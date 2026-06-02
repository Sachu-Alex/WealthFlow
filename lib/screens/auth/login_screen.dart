import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _bg = Color(0xFF033544);
  static const _teal = Color(0xFF2DD4BF);

  bool _googleLoading = false;
  bool _appleLoading = false;

  Future<void> _handleGoogle() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    try {
      final cred = await ref.read(authServiceProvider).signInWithGoogle();
      if (cred != null && mounted) context.go('/');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Google sign-in failed. Try again.'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _handleApple() async {
    if (_appleLoading) return;
    setState(() => _appleLoading = true);
    try {
      final cred = await ref.read(authServiceProvider).signInWithApple();
      if (cred != null && mounted) context.go('/');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Apple sign-in failed. Try again.'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final showApple = ref.read(authServiceProvider).isAppleSignInAvailable;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.06),

              // ── Hero: logo image ──────────────────────────────────────────
              // THE main event — everything else is a supporting act
              _LogoHero()
                  .animate()
                  .scale(
                    begin: const Offset(0.65, 0.65),
                    end: const Offset(1.0, 1.0),
                    duration: 750.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 500.ms),

              const SizedBox(height: 28),

              // ── Tagline ───────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['PLAN', '•', 'INVEST', '•', 'GROW']
                    .asMap()
                    .entries
                    .map((e) {
                  final isDot = e.value == '•';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: isDot
                            ? _teal.withValues(alpha: 0.4)
                            : _teal,
                        fontSize: isDot ? 10 : 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: isDot ? 0 : 2.5,
                      ),
                    )
                        .animate(delay: Duration(milliseconds: 450 + e.key * 80))
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.3, end: 0, duration: 350.ms, curve: Curves.easeOut),
                  );
                }).toList(),
              ),

              const Spacer(),

              // ── Auth section ──────────────────────────────────────────────
              Column(
                children: [
                  // Divider
                  _DividerRow()
                      .animate(delay: 800.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 28),

                  // Google
                  _GoogleButton(loading: _googleLoading, onTap: _handleGoogle)
                      .animate(delay: 900.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.25, end: 0, duration: 450.ms, curve: Curves.easeOut),

                  if (showApple) ...[
                    const SizedBox(height: 14),
                    _AppleButton(loading: _appleLoading, onTap: _handleApple)
                        .animate(delay: 1000.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.25, end: 0, duration: 450.ms, curve: Curves.easeOut),
                  ],

                  const SizedBox(height: 28),

                  Text(
                    'By continuing, you agree to our Terms & Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.22),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  )
                      .animate(delay: 1100.ms)
                      .fadeIn(duration: 500.ms),
                ],
              )
                  .animate(delay: 700.ms)
                  .slideY(begin: 0.12, end: 0, duration: 600.ms, curve: Curves.easeOut),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Logo hero — image with elegant fallback ───────────────────────────────────

class _LogoHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: 220,
      height: 220,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const _FallbackLogo(),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D9488), Color(0xFF2DD4BF)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.trending_up_rounded, color: Colors.white, size: 56),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Wealth',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'Flow',
                  style: TextStyle(
                    color: Color(0xFFB2F5EA),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Divider row ───────────────────────────────────────────────────────────────

class _DividerRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Sign in to continue',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
        ),
      ],
    );
  }
}

// ── Google button ─────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _GoogleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PressableButton(
      onTap: onTap,
      color: Colors.white,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1F2937),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GoogleG(),
                const SizedBox(width: 14),
                const Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Apple button ──────────────────────────────────────────────────────────────

class _AppleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _AppleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PressableButton(
      onTap: onTap,
      color: const Color(0xFF1A1A1A),
      border: Border.all(color: const Color(0xFF2C2C2E), width: 1),
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apple, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Continue with Apple',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Pressable button shell ────────────────────────────────────────────────────

class _PressableButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color color;
  final BoxBorder? border;
  final Widget child;

  const _PressableButton({
    required this.onTap,
    required this.color,
    required this.child,
    this.border,
  });

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: AnimatedOpacity(
          opacity: _pressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 90),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(16),
              border: widget.border,
            ),
            alignment: Alignment.center,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ── Google "G" logo ───────────────────────────────────────────────────────────

class _GoogleG extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = w * 0.46;
    final sw = w * 0.17;

    void arc(double startAngle, double sweep, Color color) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.butt,
      );
    }

    // Google colors: Blue, Red, Yellow, Green
    arc(-1.5708, 1.5708, const Color(0xFF4285F4)); // top-right blue
    arc(0.0, 1.5708, const Color(0xFF34A853));     // bottom-right green
    arc(1.5708, 0.7854, const Color(0xFFFBBC05));  // bottom-left yellow
    arc(2.3562, 0.7854, const Color(0xFFEA4335));  // left red

    // Horizontal bar for the "G" crossbar
    final barY = cy;
    final barLeft = cx;
    final barRight = cx + r + sw * 0.5;
    canvas.drawRect(
      Rect.fromLTWH(barLeft, barY - sw * 0.5, barRight - barLeft, sw),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
