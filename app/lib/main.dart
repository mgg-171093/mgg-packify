import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import 'app.dart';
import 'core/app_logger.dart';
import 'core/server_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.initialize();
  FlutterError.onError = (details) {
    AppLogger.e(
      'Flutter error: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  await localNotifier.setup(appName: 'MGG-Packify');

  final serverManager = ServerManager();

  runApp(
    ProviderScope(
      overrides: [serverManagerProvider.overrideWithValue(serverManager)],
      child: _AppWithLifecycle(serverManager: serverManager),
    ),
  );
}

class _AppWithLifecycle extends StatefulWidget {
  const _AppWithLifecycle({required this.serverManager});

  final ServerManager serverManager;

  @override
  State<_AppWithLifecycle> createState() => _AppWithLifecycleState();
}

class _AppWithLifecycleState extends State<_AppWithLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // Kill the child process when the app is closing
      widget.serverManager.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}
