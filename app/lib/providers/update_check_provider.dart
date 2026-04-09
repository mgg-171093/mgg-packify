import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/app_logger.dart';

class UpdateCheckState {
  final bool hasUpdate;
  final String latestVersion;
  final String releaseNotes;

  const UpdateCheckState({
    required this.hasUpdate,
    required this.latestVersion,
    required this.releaseNotes,
  });

  factory UpdateCheckState.none() => const UpdateCheckState(
    hasUpdate: false,
    latestVersion: '',
    releaseNotes: '',
  );
}

class UpdateCheckNotifier extends AsyncNotifier<UpdateCheckState> {
  @override
  Future<UpdateCheckState> build() async {
    return UpdateCheckState.none();
  }

  Future<void> checkForUpdates() async {
    state = const AsyncValue.loading();
    try {
      final response = await http
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

      final hasUpdate = _isNewer(latestVersion, kAppVersion);
      if (hasUpdate) {
        AppLogger.i('UpdateCheck: new version available — $latestVersion');
      }

      state = AsyncValue.data(
        UpdateCheckState(
          hasUpdate: hasUpdate,
          latestVersion: latestVersion,
          releaseNotes: releaseNotes,
        ),
      );
    } catch (e) {
      // Silent failure — update check must never crash the app
      AppLogger.w('UpdateCheck: failed silently — $e');
      state = AsyncValue.data(UpdateCheckState.none());
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
