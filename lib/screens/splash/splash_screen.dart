import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _barsController;
  bool _navigated = false;

  static const _bg = Color(0xFF033544);
  static const _teal = Color(0xFF0D9488);
  static const _tealBright = Color(0xFF2DD4BF);

  @override
  void initState() {
    super.initState();
    _barsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    Future.delayed(const Duration(milliseconds: 2500), _navigate);
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final user = ref.read(authStateProvider).valueOrNull;
    context.go(user != null ? '/' : '/login');
  }

  @override
  void dispose() {
    _barsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Logo ───────────────────────────────────────────────────────
            Image.asset(
              'assets/images/logo.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_teal, _tealBright],
                  ),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: Colors.white, size: 44),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1.0, 1.0),
                  duration: 700.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 500.ms),

            const SizedBox(height: 48),

            // ── Animated bar chart ─────────────────────────────────────────
            _AnimatedBars(controller: _barsController)
                .animate(delay: 600.ms)
                .fadeIn(duration: 500.ms),

            const SizedBox(height: 48),

            // ── Loading indicator ──────────────────────────────────────────
            _PulsingDots()
                .animate(delay: 900.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),

      // Version
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Text(
          'v1.0.0',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.18),
            fontSize: 12,
          ),
        )
            .animate(delay: 1000.ms)
            .fadeIn(duration: 600.ms),
      ),
    );
  }
}

// ── Animated rising bars ──────────────────────────────────────────────────────

class _AnimatedBars extends StatelessWidget {
  final AnimationController controller;

  static const _heights = [0.3, 0.5, 0.4, 0.72, 0.58, 0.88, 0.68];
  static const _teal = Color(0xFF0D9488);
  static const _tealBright = Color(0xFF2DD4BF);

  const _AnimatedBars({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 56,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(_heights.length, (i) {
            final delay = i / _heights.length;
            final t = ((controller.value - delay) / (1 - delay)).clamp(0.0, 1.0);
            final eased = Curves.easeOutCubic.transform(t);
            final h = _heights[i] * 56 * eased;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  height: h,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        _teal.withValues(alpha: 0.9),
                        _tealBright.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Pulsing dots ──────────────────────────────────────────────────────────────

class _PulsingDots extends StatelessWidget {
  static const _teal = Color(0xFF0D9488);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: _teal.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .fadeIn(delay: Duration(milliseconds: i * 220), duration: 400.ms)
            .then()
            .fadeOut(duration: 400.ms),
      )),
    );
  }
}
