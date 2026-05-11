import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import 'admin_dashboard_screen.dart';
import 'member_home_screen.dart';
import 'coach_dashboard_screen.dart';
import 'register_screen.dart';

// ─── Design tokens light ───
const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kGreen = Color(0xFF00897B);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isPending = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_identifierController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez remplir tous les champs';
        _isPending = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isPending = false;
    });
    final result = await AuthService.login(
      _identifierController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (result["success"] == true) {
      final role = result["role"] ?? "MEMBER";
      final memberId = result["memberId"] ?? 0;
      final coachId = result["coachId"] ?? 0;
      if (role == "ADMIN") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else if (role == "COACH") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CoachDashboardScreen(coachId: coachId),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MemberHomeScreen(memberId: memberId),
          ),
        );
      }
    } else {
      final error = result["error"] ?? "";
      setState(() {
        _isPending = (error == "PENDING");
        _errorMessage = result["message"] ?? "Identifiants incorrects";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Background sportif ──
          const _SportBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        // ── Logo ──
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: _kSurface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _kGreen.withValues(alpha: 0.18),
                                blurRadius: 32,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: _kGreen.withValues(alpha: 0.25),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/dumbbell.svg',
                              width: 48,
                              height: 48,
                              colorFilter: const ColorFilter.mode(
                                _kGreen,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // ── Titre ──
                        const Text(
                          'SMART GYM',
                          style: TextStyle(
                            color: _kText,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Votre coach intelligent',
                          style: TextStyle(
                            color: _kTextSub,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 36),
                        // ── Carte formulaire ──
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _kSurface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _kBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _LightTextField(
                                controller: _identifierController,
                                label: 'Email, téléphone ou username',
                                icon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 14),
                              _LightTextField(
                                controller: _passwordController,
                                label: 'Mot de passe',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscurePassword,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: _kTextSub,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              if (_errorMessage != null && !_isPending) ...[
                                const SizedBox(height: 14),
                                _AlertBanner(
                                  icon: Icons.error_outline,
                                  color: const Color(0xFFE53935),
                                  bgColor: const Color(0xFFFFEBEE),
                                  message: _errorMessage!,
                                ),
                              ],
                              if (_isPending) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFF57C00,
                                      ).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.hourglass_top,
                                            color: Color(0xFFF57C00),
                                            size: 16,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Compte en attente',
                                            style: TextStyle(
                                              color: Color(0xFFF57C00),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Votre abonnement n'est pas encore activé.",
                                        style: TextStyle(
                                          color: _kText.withValues(alpha: 0.7),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '➤ Présentez-vous à la réception\n➤ Payez en espèces\n➤ L\'admin activera votre compte',
                                        style: TextStyle(
                                          color: _kTextSub,
                                          fontSize: 12,
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kGreen,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.login_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Se connecter',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: Divider(color: _kBorder)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                'ou',
                                style: TextStyle(
                                  color: _kTextSub,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: _kBorder)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                            icon: const Icon(
                              Icons.person_add_outlined,
                              color: _kGreen,
                            ),
                            label: const Text(
                              'Créer un compte',
                              style: TextStyle(
                                color: _kGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: _kGreen,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BACKGROUND SPORTIF
// ─────────────────────────────────────────────
class _SportBackground extends StatelessWidget {
  const _SportBackground();
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: CustomPaint(painter: _SportBgPainter()));
  }
}

class _SportBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fond dégradé très léger
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFFE8F5E9),
          const Color(0xFFF4F6FA),
          const Color(0xFFE3F2FD),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Orbe vert top-right
    final orb1 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Color(0xFF00897B).withValues(alpha: 0.12),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(size.width + 30, -20), radius: 220),
          );
    canvas.drawCircle(Offset(size.width + 30, -20), 220, orb1);

    // Orbe bleu bottom-left
    final orb2 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Color(0xFF1976D2).withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(-40, size.height + 10), radius: 180),
          );
    canvas.drawCircle(Offset(-40, size.height + 10), 180, orb2);

    // Grille fine
    final grid = Paint()
      ..color = Color(0xFF00897B).withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    for (double y = 0; y < size.height; y += step)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);

    // Haltère décoratif top-left
    _drawDumbbell(canvas, const Offset(32, 80), 0.06);
    // Haltère décoratif bottom-right
    _drawDumbbell(canvas, Offset(size.width - 40, size.height - 120), 0.05);
    // Hexagone
    _drawHex(canvas, Offset(size.width - 55, 55), 48);
    // Coeur de sport (bottom-left)
    _drawHeartbeat(
      canvas,
      Offset(28, size.height - 140),
      size.width * 0.25,
      0.06,
    );
  }

  void _drawDumbbell(Canvas canvas, Offset center, double opacity) {
    final p = Paint()
      ..color = Color(0xFF00897B).withValues(alpha: opacity)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;
    canvas.drawLine(
      Offset(center.dx - 22, center.dy),
      Offset(center.dx + 22, center.dy),
      p,
    );
    final plate = Paint()
      ..color = Color(0xFF00897B).withValues(alpha: opacity + 0.02)
      ..style = PaintingStyle.fill;
    for (final dx in [-22.0, 22.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx + dx, center.dy),
            width: 10,
            height: 22,
          ),
          const Radius.circular(3),
        ),
        plate,
      );
    }
  }

  void _drawHex(Canvas canvas, Offset center, double r) {
    final p = Paint()
      ..color = Color(0xFF1976D2).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = math.pi / 180 * (60 * i - 30);
      final pt = Offset(
        center.dx + r * math.cos(a),
        center.dy + r * math.sin(a),
      );
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, p);
    // cercle intérieur
    final p2 = Paint()
      ..color = Color(0xFF1976D2).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(center, r * 0.6, p2);
  }

  void _drawHeartbeat(
    Canvas canvas,
    Offset origin,
    double width,
    double opacity,
  ) {
    final p = Paint()
      ..color = Color(0xFFE53935).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final seg = width / 7;
    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(origin.dx + seg, origin.dy)
      ..lineTo(origin.dx + 1.8 * seg, origin.dy - 28)
      ..lineTo(origin.dx + 2.6 * seg, origin.dy + 18)
      ..lineTo(origin.dx + 3.4 * seg, origin.dy - 14)
      ..lineTo(origin.dx + 4.0 * seg, origin.dy)
      ..lineTo(origin.dx + width, origin.dy);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────
// WIDGETS UTILITAIRES LIGHT
// ─────────────────────────────────────────────
class _LightTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;

  const _LightTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: _kText, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _kTextSub, fontSize: 14),
        prefixIcon: Icon(icon, color: _kGreen, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFEEF1F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String message;

  const _AlertBanner({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
