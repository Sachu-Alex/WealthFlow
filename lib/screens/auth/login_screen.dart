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
  static const _bg = Color(0xFF0A0F1E);
  static const _surface = Color(0xFF111827);
  static const _teal = Color(0xFF0D9488);
  static const _tealBright = Color(0xFF2DD4BF);

  bool _googleLoading = false;
  bool _appleLoading = false;

  Future<void> _handleGoogle() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    try {
      final cred = await ref.read(authServiceProvider).signInWithGoogle();
      if (cred != null && mounted) context.go('/');
    } catch (e) {
      if (mounted) _showError('Google sign-in failed. Please try again.');
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
    } catch (e) {
      if (mounted) _showError('Apple sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final showApple = ref.read(authServiceProvider).isAppleSignInAvailable;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Background grid lines — subtle
          Positioned.fill(child: _GridLines()),

          // Top teal glow
          Positioned(
            top: -80,
            left: size.width * 0.5 - 160,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _teal.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Logo + Name ───────────────────────────────────────────
                  _buildLogo()
                      .animate()
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 24),

                  Text(
                    'WealthFlow',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),

                  const SizedBox(height: 10),

                  Text(
                    'Track. Grow. Prosper.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  )
                      .animate(delay: 350.ms)
                      .fadeIn(duration: 500.ms),

                  const Spacer(flex: 2),

                  // ── Feature pills ─────────────────────────────────────────
                  _buildFeaturePills()
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),

                  const Spacer(flex: 3),

                  // ── Divider label ─────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.1),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Continue with',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.1),
                          thickness: 1,
                        ),
                      ),
                    ],
                  )
                      .animate(delay: 650.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 20),

                  // ── Google button ─────────────────────────────────────────
                  _GoogleButton(loading: _googleLoading, onTap: _handleGoogle)
                      .animate(delay: 750.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOut),

                  if (showApple) ...[
                    const SizedBox(height: 14),
                    _AppleButton(loading: _appleLoading, onTap: _handleApple)
                        .animate(delay: 850.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOut),
                  ],

                  const SizedBox(height: 32),

                  // ── Privacy note ──────────────────────────────────────────
                  Text(
                    'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 12,
                      height: 1.6,
                    ),
                  )
                      .animate(delay: 950.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_teal, _tealBright],
        ),
        boxShadow: [
          BoxShadow(
            color: _teal.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 40),
    );
  }

  Widget _buildFeaturePills() {
    final features = [
      ('Investments', Icons.show_chart_rounded),
      ('Withdrawals', Icons.account_balance_wallet_rounded),
      ('Expenses', Icons.receipt_long_rounded),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: features.map((f) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(f.$2, size: 14, color: _tealBright),
              const SizedBox(width: 6),
              Text(
                f.$1,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Google Sign-In button ─────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _GoogleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _AuthButton(
      onTap: onTap,
      loading: loading,
      backgroundColor: Colors.white,
      borderColor: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1F2937)),
            )
          else ...[
            _GoogleLogo(),
            const SizedBox(width: 12),
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
        ],
      ),
    );
  }
}

// ── Apple Sign-In button ──────────────────────────────────────────────────────

class _AppleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _AppleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _AuthButton(
      onTap: onTap,
      loading: loading,
      backgroundColor: const Color(0xFF1A1A1A),
      borderColor: const Color(0xFF2A2A2A),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          else ...[
            const Icon(Icons.apple, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            const Text(
              'Continue with Apple',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared button shell ───────────────────────────────────────────────────────

class _AuthButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool loading;
  final Color backgroundColor;
  final Color borderColor;
  final Widget child;

  const _AuthButton({
    required this.onTap,
    required this.loading,
    required this.backgroundColor,
    required this.borderColor,
    required this.child,
  });

  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton> {
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
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.borderColor, width: 1),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Google logo (SVG-free) ────────────────────────────────────────────────────

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Blue arc (top/right)
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -1.57, 2.35, false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18,
    );
    // Green arc (bottom)
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      0.785, 1.57, false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18,
    );
    // Yellow arc (bottom-left)
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      2.355, 0.785, false,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18,
    );
    // Red arc (left/top)
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      3.14, 0.43, false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18,
    );

    // Horizontal bar (right side of G)
    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - size.height * 0.09, r * 0.95, size.height * 0.18),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Subtle background grid ────────────────────────────────────────────────────

class _GridLines extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    const spacing = 48.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
