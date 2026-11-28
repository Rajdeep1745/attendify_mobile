import 'package:flutter/material.dart';

/// Keeps a short request from flashing its loading view.
class MinimumLoadingTimer {
  final Stopwatch _stopwatch = Stopwatch()..start();

  Future<void> wait() async {
    final remaining = const Duration(seconds: 1) - _stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }
}

Future<T> withMinimumLoading<T>(Future<T> work) async {
  final timer = MinimumLoadingTimer();
  try {
    return await work;
  } finally {
    await timer.wait();
  }
}

/// Shared branded loading state for screens and blocking saves.
class AppLoadingView extends StatelessWidget {
  final String message;
  final bool overlay;

  const AppLoadingView({
    super.key,
    this.message = 'Loading your attendance…',
    this.overlay = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: ColoredBox(
        color: overlay
            ? Colors.black.withValues(alpha: 0.55)
            : const Color(0xffF6F7FB),
        child: Center(
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/attendify_loading_logo.png',
                  width: 64,
                  height: 64,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    width: 64,
                    height: 64,
                    child: Icon(
                      Icons.fact_check_rounded,
                      color: Color(0xff6F52E8),
                      size: 40,
                    ),
                  ),
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded || frame != null) {
                          return child;
                        }
                        return const SizedBox(
                          width: 64,
                          height: 64,
                          child: Icon(
                            Icons.fact_check_rounded,
                            color: Color(0xff6F52E8),
                          ),
                        );
                      },
                ),
                const SizedBox(height: 18),
                const Text(
                  'Attendify',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff29234B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    color: Color(0xff6F52E8),
                    backgroundColor: Color(0xffEDE9FA),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
