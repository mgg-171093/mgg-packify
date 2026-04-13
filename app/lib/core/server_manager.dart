import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/server_status_provider.dart';
import 'app_logger.dart';

class ServerManager {
  Process? _process;
  static const _execName = 'mgg-packify-api.exe';

  Future<void> start() async {
    if (kReleaseMode) {
      await _startRelease();
    } else {
      await _startDev();
    }
  }

  Future<void> _startRelease() async {
    final execDir = File(Platform.resolvedExecutable).parent.path;
    final exePath = '$execDir\\$_execName';

    if (!File(exePath).existsSync()) {
      debugPrint(
        '[ServerManager] WARNING: $exePath not found — skipping server start',
      );
      return;
    }

    try {
      _process = await Process.start(
        exePath,
        [],
        mode: ProcessStartMode.normal,
      );
      debugPrint(
        '[ServerManager] Started release server from $exePath (pid: ${_process?.pid})',
      );

      _process!.stdout
          .transform(const SystemEncoding().decoder)
          .transform(const LineSplitter())
          .listen((line) => AppLogger.raw(line));

      _process!.stderr
          .transform(const SystemEncoding().decoder)
          .transform(const LineSplitter())
          .listen((line) => AppLogger.raw('[stderr] $line'));
    } catch (e) {
      debugPrint('[ServerManager] ERROR starting release server: $e');
    }
  }

  Future<void> _startDev() async {
    // In dev mode, if the API is already running skip launch entirely.
    // This lets you run the API separately from VS Code / terminal.
    if (await _isPortListening(8787)) {
      debugPrint(
        '[ServerManager] DEV mode — API already running on :8787, skipping launch',
      );
      return;
    }

    final apiPath = _resolveDevApiPath();
    if (apiPath == null) {
      debugPrint(
        '[ServerManager] DEV mode — api path not found, start the API manually',
      );
      return;
    }

    // apiPath resolves to api/src — the package root is one level up (api/)
    final workDir = Directory(apiPath).parent.path;

    try {
      _process = await Process.start(
        'python',
        ['-m', 'mgg_packify_api.main'],
        workingDirectory: workDir,
        mode: ProcessStartMode.normal,
      );
      debugPrint(
        '[ServerManager] Started dev server from $workDir (pid: ${_process?.pid})',
      );

      _process!.stdout.listen((data) {
        debugPrint('[API] ${String.fromCharCodes(data).trim()}');
      });
      _process!.stderr.listen((data) {
        debugPrint('[API ERR] ${String.fromCharCodes(data).trim()}');
      });
    } catch (e) {
      debugPrint('[ServerManager] WARNING: Could not start dev server: $e');
    }
  }

  /// Returns true if something is already listening on [port].
  Future<bool> _isPortListening(int port) async {
    try {
      final socket = await Socket.connect(
        '127.0.0.1',
        port,
        timeout: const Duration(milliseconds: 300),
      );
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  String? _resolveDevApiPath() {
    // Check environment variable first
    final envPath = Platform.environment['MGG_API_PATH'];
    if (envPath != null && Directory(envPath).existsSync()) {
      return envPath;
    }

    // Try relative to executable: go up to find api/src
    try {
      final execDir = File(Platform.resolvedExecutable).parent.path;
      // In dev: executable is in app/build/windows/x64/runner/Debug/
      // Repo root is ~6 levels up
      final candidates = [
        '$execDir\\..\\..\\..\\..\\..\\..\\api\\src',
        '$execDir\\..\\..\\..\\..\\..\\api\\src',
        '..\\api\\src',
        '..\\..\\api\\src',
      ];
      for (final c in candidates) {
        final dir = Directory(c);
        if (dir.existsSync()) return dir.path;
      }
    } catch (_) {}

    return null;
  }

  Future<void> restart(WidgetRef ref) async {
    AppLogger.i('ServerManager: restarting API...');
    ref.read(serverStatusProvider.notifier).state = ServerStatus.restarting;
    await stop();
    await Future.delayed(const Duration(milliseconds: 500));
    await start();
  }

  Future<void> stop() async {
    if (_process == null) return;
    final pid = _process!.pid;
    AppLogger.i('[ServerManager] Stopping server (pid: $pid)');
    if (Platform.isWindows) {
      await Process.run('taskkill', ['/F', '/PID', '$pid']);
    } else {
      _process!.kill(ProcessSignal.sigkill);
    }
    try {
      await _process!.exitCode.timeout(const Duration(seconds: 3));
    } catch (_) {
      AppLogger.w('[ServerManager] Process did not exit within timeout');
    }
    _process = null;
  }
}

final serverManagerProvider = Provider<ServerManager>((ref) => ServerManager());
