import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/app_logger.dart';
import '../core/server_manager.dart';

class UpdateCheckState {
  final bool hasUpdate;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;

  const UpdateCheckState({
    required this.hasUpdate,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
  });

  factory UpdateCheckState.none() => const UpdateCheckState(
    hasUpdate: false,
    latestVersion: '',
    releaseNotes: '',
    downloadUrl: '',
  );
}

class UpdateCheckNotifier extends AsyncNotifier<UpdateCheckState> {
  Timer? _pollingTimer;

  @override
  Future<UpdateCheckState> build() async {
    // Start 4h background polling timer
    _pollingTimer = Timer.periodic(
      const Duration(hours: 4),
      (_) => checkForUpdates(),
    );
    ref.onDispose(() {
      _pollingTimer?.cancel();
      _pollingTimer = null;
    });

    // Defer initial check so build() can complete first, then update state
    Future.microtask(checkForUpdates);

    return UpdateCheckState.none();
  }

  Future<void> checkForUpdates({http.Client? client}) async {
    state = const AsyncValue.loading();
    try {
      final httpClient = client ?? http.Client();
      final response = await httpClient
          .get(Uri.parse(kUpdateCheckUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        AppLogger.w('UpdateCheck: HTTP ${response.statusCode}');
        state = AsyncValue.data(UpdateCheckState.none());
        return;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final latestVersion = json['version'] as String? ?? '';
      final releaseNotes = json['release_notes'] as String? ?? '';
      final downloadUrl = json['url'] as String? ?? '';

      final hasUpdate = _isNewer(latestVersion, kAppVersion);
      if (hasUpdate) {
        AppLogger.i('UpdateCheck: new version available — $latestVersion');
        // Cancel timer — no need to keep polling once we found an update
        _pollingTimer?.cancel();
        _pollingTimer = null;
      }

      state = AsyncValue.data(
        UpdateCheckState(
          hasUpdate: hasUpdate,
          latestVersion: latestVersion,
          releaseNotes: releaseNotes,
          downloadUrl: downloadUrl,
        ),
      );
    } catch (e) {
      // Silent failure — update check must never crash the app
      AppLogger.w('UpdateCheck: failed silently — $e');
      state = AsyncValue.data(UpdateCheckState.none());
    }
  }

  /// Downloads the installer to a temp file, emitting progress via [onProgress].
  ///
  /// Progress values: 0.0..1.0 = downloading; -1.0 = error sentinel.
  /// On success: launches the installer with /SILENT and exits the app.
  Future<void> downloadAndInstall({
    required void Function(double progress) onProgress,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final tempPath = '${Platform.environment['TEMP']}/mgg-packify-update.exe';
    final tempFile = File(tempPath);

    try {
      final url = Uri.parse(state.value!.downloadUrl);
      final request = http.Request('GET', url);
      final response = await httpClient.send(request);
      final total = response.contentLength ?? 0;
      int downloaded = 0;

      final sink = tempFile.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (total > 0) {
          onProgress(downloaded / total);
        }
      }
      await sink.close();

      // Stop the Python API process before launching the installer.
      // exit(0) bypasses the Flutter lifecycle — the process would otherwise
      // remain alive, causing Inno Setup "Access Denied" on mgg-packify-api.exe.
      AppLogger.i('UpdateCheck: stopping API process before installer launch');
      await ref.read(serverManagerProvider).stop();

      // Launch installer silently and exit the app
      await Process.start(tempPath, ['/SILENT']);
      exit(0);
    } catch (e) {
      AppLogger.w('UpdateCheck: downloadAndInstall failed — $e');
      // Cleanup partial file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      onProgress(-1.0); // error sentinel
    }
  }

  /// Returns true if [candidate] is semantically newer than [current].
  /// Compares major.minor.patch as List<int>. No external semver package.
  bool _isNewer(String candidate, String current) {
    try {
      final a = candidate.split('.').map(int.parse).toList();
      final b = current.split('.').map(int.parse).toList();
      for (var i = 0; i < 3; i++) {
        final ai = i < a.length ? a[i] : 0;
        final bi = i < b.length ? b[i] : 0;
        if (ai > bi) return true;
        if (ai < bi) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

final updateCheckProvider =
    AsyncNotifierProvider<UpdateCheckNotifier, UpdateCheckState>(
      UpdateCheckNotifier.new,
    );
