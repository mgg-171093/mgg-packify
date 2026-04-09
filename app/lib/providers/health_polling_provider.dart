import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/app_logger.dart';
import 'server_status_provider.dart';

class HealthPollingNotifier extends Notifier<void> {
  Timer? _timer;

  @override
  void build() {
    // No initial state — caller activates via startPolling()
    ref.onDispose(() => _timer?.cancel());
  }

  void startPolling() {
    _timer?.cancel();
    AppLogger.i('HealthPolling: starting 30s poll');
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkHealth());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    AppLogger.i('HealthPolling: stopped');
  }

  Future<void> _checkHealth() async {
    // CRITICAL: use ref.read, NEVER ref.watch inside timer callback
    try {
      final response = await http
          .get(Uri.parse('$kBaseUrl/health'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        ref.read(serverStatusProvider.notifier).state = ServerStatus.ready;
      } else {
        AppLogger.w('HealthPolling: /health returned ${response.statusCode}');
        _markFailed();
      }
    } catch (e) {
      AppLogger.w('HealthPolling: /health unreachable — $e');
      _markFailed();
    }
  }

  void _markFailed() {
    // CRITICAL: use ref.read, NEVER ref.watch
    final current = ref.read(serverStatusProvider);
    if (current == ServerStatus.crashed || current == ServerStatus.restarting)
      return;
    if (current == ServerStatus.error) {
      // Second consecutive failure → crashed
      ref.read(serverStatusProvider.notifier).state = ServerStatus.crashed;
    } else {
      ref.read(serverStatusProvider.notifier).state = ServerStatus.error;
    }
  }
}

final healthPollingProvider = NotifierProvider<HealthPollingNotifier, void>(
  HealthPollingNotifier.new,
);
