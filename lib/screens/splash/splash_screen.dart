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
  late AnimationController _chartController;
  bool _navigated = false;

  static const _bgColor = Color(0xFF0A0F1E);
  static const _teal = Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    // Navigate after animations settle
    Future.delayed(const Duration(milliseconds: 2600), _navigate);
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      context.go('/');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Subtle radial glow behind logo
          Positioned(
            top: MediaQuery.of(context).size.height * 0.18,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _teal.withValues(alpha: 0.18),
                      _bgColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 0),
                // ── Logo mark ──────────────────────────────────────────────
                _LogoMark()
                    .animate()
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1.0, 1.0),
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 500.ms),

                const SizedBox(height: 28),

                // ── App name ───────────────────────────────────────────────
                Text(
                  'WealthFlow',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.3, end: 0.0, duration: 500.ms, curve: Curves.easeOut),

                const SizedBox(height: 10),

                // ── Tagline ────────────────────────────────────────────────
                Text(
                  'Your wealth, flowing forward',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                )
                    .animate(delay: 550.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.3, end: 0.0, duration: 500.ms, curve: Curves.easeOut),

                const SizedBox(height: 56),

                // ── Animated chart bars ────────────────────────────────────
                _AnimatedChart(controller: _chartController)
                    .animate(delay: 700.ms)
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: 64),

                // ── Loading dots ───────────────────────────────────────────
                _LoadingDots()
                    .animate(delay: 1000.ms)
                    .fadeIn(duration: 400.ms),
              ],
            ),
          ),

          // Bottom version label
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'v1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            )
                .animate(delay: 1200.ms)
                .fadeIn(duration: 600.ms),
          ),
        ],
      ),
    );
  }
}

// ── Logo mark widget ──────────────────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  static const _teal = Color(0xFF0D9488);
  static const _tealBright = Color(0xFF2DD4BF);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_teal, _tealBright],
        ),
        boxShadow: [
          BoxShadow(
            color: _teal.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.trending_up_rounded,
        color: Colors.white,
        size: 44,
      ),
    );
  }
}

// ── Animated chart bars ───────────────────────────────────────────────────────

class _AnimatedChart extends StatelessWidget {
  final AnimationController controller;

  static const _teal = Color(0xFF0D9488);
  static const _tealBright = Color(0xFF2DD4BF);

  static const _barHeights = [0.35, 0.55, 0.45, 0.75, 0.60, 0.85, 0.70];

  const _AnimatedChart({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 64,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_barHeights.length, (i) {
              final delay = i / _barHeights.length;
              final progress = ((controller.value - delay) / (1 - delay)).clamp(0.0, 1.0);
              final eased = Curves.easeOutCubic.transform(progress);
              final maxH = 64.0;
              final h = _barHeights[i] * maxH * eased;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    height: h,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
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
          );
        },
      ),
    );
  }
}

// ── Loading dots ──────────────────────────────────────────────────────────────

class _LoadingDots extends StatelessWidget {
  static const _teal = Color(0xFF0D9488);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
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
              .fadeIn(
                delay: Duration(milliseconds: i * 200),
                duration: 400.ms,
              )
              .then()
              .fadeOut(duration: 400.ms),
        );
      }),
    );
  }
}
