import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/api_client.dart';
import '../core/server_manager.dart';
import '../providers/server_status_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.minDisplayDuration = const Duration(milliseconds: 5000),
  });

  /// Minimum time the splash is shown before navigating to /dashboard.
  /// Inject [Duration.zero] in tests for instant navigation.
  final Duration minDisplayDuration;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;
  int _attempts = 0;
  // 36 × 500ms = 18 seconds maximum wait
  static const _maxAttempts = 36;

  @override
  void initState() {
    super.initState();
    _launchAndPoll();
  }

  Future<void> _launchAndPoll() async {
    // Start the server process
    try {
      await ref.read(serverManagerProvider).start();
    } catch (e) {
      debugPrint('[SplashScreen] Error starting server: $e');
    }
    // Begin health polling
    _startPolling();
  }

  void _startPolling() {
    _attempts = 0;
    ref.read(serverStatusProvider.notifier).state = ServerStatus.starting;

    // Minimum display delay future — runs in parallel with polling
    final minDelayFuture = Future<void>.delayed(widget.minDisplayDuration);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (_attempts >= _maxAttempts) {
        _timer?.cancel();
        if (mounted) {
          ref.read(serverStatusProvider.notifier).state = ServerStatus.error;
        }
        return;
      }
      _attempts++;
      try {
        await ref.read(apiClientProvider).getHealth();
        _timer?.cancel();
        // Wait for minimum display delay before navigating
        await minDelayFuture;
        if (mounted) {
          ref.read(serverStatusProvider.notifier).state = ServerStatus.ready;
          context.go('/dashboard');
        }
      } catch (_) {
        // Not ready yet — keep polling
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(serverStatusProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / icon
              Builder(
                builder: (context) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  Widget img = Image.asset(
                    'assets/branding/logo-full.png',
                    width: 400,
                    height: 450,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.inventory_2,
                      size: 96,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                  if (isDark) {
                    img = ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                      child: img,
                    );
                  }
                  return img;
                },
              ),
              const SizedBox(height: 10),
              if (status == ServerStatus.starting) ...[
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Iniciando servidor...',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
              ],
              if (status == ServerStatus.error) ...[
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  'No se pudo iniciar el servidor',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _startPolling,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
