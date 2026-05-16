// lib/screens/coach_dashboard_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../providers/coach_provider.dart';
import '../providers/message_provider.dart';
import '../widgets/index.dart';
import 'member_details_screen.dart';
import 'login_screen.dart';
import 'messages_screen.dart';
import 'coach_profile_screen.dart';
import 'coach_admin_messages_screen.dart';
import 'coach_ai_feedback_screen.dart';

const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kGreenL = Color(0xFFE0F2F1);
const Color _kBlue = Color(0xFF1976D2);
const Color _kBlueL = Color(0xFFE3F2FD);
const Color _kOrange = Color(0xFFF57C00);
const Color _kOrangeL = Color(0xFFFFF3E0);
const Color _kRed = Color(0xFFE53935);
const Color _kRedL = Color(0xFFFFEBEE);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class CoachDashboardScreen extends ConsumerStatefulWidget {
  final int coachId;
  const CoachDashboardScreen({super.key, required this.coachId});
  @override
  ConsumerState<CoachDashboardScreen> createState() =>
      _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends ConsumerState<CoachDashboardScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  String? _username;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
    _loadUsername();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    _username = await AuthService.getUsername();
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
  }

  @override
  Widget build(BuildContext context) {
    final unreadAdmin =
        ref.watch(coachUnreadFromAdminProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          _CoachBgLight(controller: _bgController),
          SafeArea(
            child: Column(
              children: [
                _CoachTopBar(
                  coachId: widget.coachId,
                  username: _username,
                  onLogout: _logout,
                ),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      _MembersTab(coachId: widget.coachId),
                      const CoachAdminMessagesScreen(),
                      CoachProfileScreen(coachId: widget.coachId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _CoachBottomNav(
        currentIndex: _currentIndex,
        unreadAdmin: unreadAdmin,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// BACKGROUND COACH LIGHT
// ════════════════════════════════════════════════════════════
class _CoachBgLight extends AnimatedWidget {
  const _CoachBgLight({required AnimationController controller})
    : super(listenable: controller);
  @override
  Widget build(BuildContext context) {
    final t = (listenable as AnimationController).value;
    return CustomPaint(painter: _CoachBgLightPainter(t), child: Container());
  }
}

class _CoachBgLightPainter extends CustomPainter {
  final double t;
  const _CoachBgLightPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFFE3F2FD), _kBg, const Color(0xFFE0F2F1)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final orb1 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              _kBlue.withValues(alpha: 0.09 + t * 0.03),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(-20 + t * 25, -15 + t * 18),
              radius: 200,
            ),
          );
    canvas.drawCircle(Offset(-20 + t * 25, -15 + t * 18), 200, orb1);

    final orb2 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              _kGreen.withValues(alpha: 0.08 + t * 0.03),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width + 15, size.height - 40 - t * 20),
              radius: 160,
            ),
          );
    canvas.drawCircle(
      Offset(size.width + 15, size.height - 40 - t * 20),
      160,
      orb2,
    );

    final grid = Paint()
      ..color = _kBlue.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    for (double i = -size.height; i < size.width + size.height; i += 30)
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), grid);

    _drawHex(canvas, Offset(size.width - 46, 88), 46 + t * 4);
    _drawWhistle(canvas, Offset(size.width - 38, size.height - 180 + t * 6));

    final ring = Paint()
      ..color = _kBlue.withValues(alpha: 0.04 - t * 0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(0, size.height), 100 + t * 35, ring);
    final ring2 = Paint()
      ..color = _kBlue.withValues(alpha: 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(Offset(0, size.height), 155 + t * 45, ring2);
  }

  void _drawHex(Canvas canvas, Offset c, double r) {
    final p = Paint()
      ..color = _kBlue.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = math.pi / 180 * (60 * i - 30);
      final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, p);
    final p2 = Paint()
      ..color = _kBlue.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final path2 = Path();
    for (int i = 0; i < 6; i++) {
      final a = math.pi / 180 * (60 * i - 30);
      final pt = Offset(
        c.dx + r * 0.55 * math.cos(a),
        c.dy + r * 0.55 * math.sin(a),
      );
      i == 0 ? path2.moveTo(pt.dx, pt.dy) : path2.lineTo(pt.dx, pt.dy);
    }
    path2.close();
    canvas.drawPath(path2, p2);
  }

  void _drawWhistle(Canvas canvas, Offset pos) {
    final p = Paint()
      ..color = _kBlue.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(pos, 13, p);
    canvas.drawLine(
      Offset(pos.dx + 13, pos.dy),
      Offset(pos.dx + 25, pos.dy - 7),
      p,
    );
    canvas.drawLine(
      Offset(pos.dx + 18, pos.dy - 3),
      Offset(pos.dx + 18, pos.dy + 5),
      p,
    );
  }

  @override
  bool shouldRepaint(_CoachBgLightPainter old) => old.t != t;
}

// ════════════════════════════════════════════════════════════
// TOP BAR COACH LIGHT
// ════════════════════════════════════════════════════════════
class _CoachTopBar extends ConsumerWidget {
  final int coachId;
  final String? username;
  final VoidCallback onLogout;

  const _CoachTopBar({
    required this.coachId,
    required this.username,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(allMembersProvider);
    final memberCount = membersAsync.valueOrNull?.length ?? 0;
    final alertCount =
        ref
            .watch(allMembersPredictionsProvider)
            .valueOrNull
            ?.values
            .where(
              (p) =>
                  (p['fatigue']?['label']?.toString().toLowerCase().contains(
                        'fatigué',
                      ) ??
                      false) ||
                  (p['injury']?['label']?.toString().toLowerCase().contains(
                        'élevé',
                      ) ??
                      false),
            )
            .length ??
        0;

    final uname = username ?? 'Coach';
    final initials = uname.trim().isEmpty
        ? 'C'
        : uname
              .trim()
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
              .take(2)
              .join();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: _kSurface,
        border: const Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kBlue, Color(0xFF0D47A1)],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bonjour,',
                  style: TextStyle(color: _kTextSub, fontSize: 11),
                ),
                Text(
                  uname,
                  style: const TextStyle(
                    color: _kText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_rounded, color: _kTextSub),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CoachAIFeedbackScreen(coachId: coachId),
                ),
              );
            },
            tooltip: 'Évaluations IA',
          ),
          if (alertCount > 0) ...[
            _TopChip(
              icon: Icons.warning_amber_rounded,
              label: '$alertCount alerte${alertCount > 1 ? 's' : ''}',
              color: _kRed,
              bg: _kRedL,
            ),
            const SizedBox(width: 6),
          ],
          _TopChip(
            icon: Icons.people_rounded,
            label: '$memberCount',
            color: _kGreen,
            bg: _kGreenL,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onLogout,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _kSurf2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _kBorder),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: _kTextSub,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, bg;
  const _TopChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════
// MEMBERS TAB
// ════════════════════════════════════════════════════════════
class _MembersTab extends ConsumerWidget {
  final int coachId;
  const _MembersTab({required this.coachId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(allMembersProvider);
    final predictionsAsync = ref.watch(allMembersPredictionsProvider);

    return membersAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _kGreen)),
      error: (e, _) => Center(
        child: Text('Erreur: $e', style: const TextStyle(color: _kRed)),
      ),
      data: (members) {
        final predictions = predictionsAsync.valueOrNull ?? {};
        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _kSurf2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kBorder),
                  ),
                  child: const Icon(
                    Icons.people_outline_rounded,
                    color: _kTextSub,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucun membre assigné',
                  style: TextStyle(
                    color: _kTextSub,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        final sorted = [...members]
          ..sort((a, b) {
            final aA = _hasAlert(predictions[a['id']]);
            final bA = _hasAlert(predictions[b['id']]);
            return aA == bA
                ? 0
                : aA
                ? -1
                : 1;
          });
        final alertCount = sorted
            .where((m) => _hasAlert(predictions[m['id']]))
            .length;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allMembersProvider);
            ref.invalidate(allMembersPredictionsProvider);
          },
          color: _kGreen,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _SummaryBar(total: sorted.length, alerts: alertCount),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final member = sorted[i];
                    final pred = predictions[member['id']];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MemberCard(
                        member: member,
                        prediction: pred,
                        onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => MemberDetailsScreen(
                              memberId: member['id'],
                              memberName: member['fullName'],
                            ),
                          ),
                        ),
                        onMessage: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => MessagesScreen(
                              memberId: member['id'],
                              isCoach: true,
                              memberName: member['fullName'],
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: sorted.length),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _hasAlert(Map<String, dynamic>? p) {
    if (p == null) return false;
    return (p['fatigue']?['label']?.toString().toLowerCase().contains(
              'fatigué',
            ) ??
            false) ||
        (p['injury']?['label']?.toString().toLowerCase().contains('élevé') ??
            false);
  }
}

class _SummaryBar extends StatelessWidget {
  final int total, alerts;
  const _SummaryBar({required this.total, required this.alerts});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: _kSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _kBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _kGreenL,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _kGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'IA LIVE',
                style: TextStyle(
                  color: _kGreen,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$total membre${total > 1 ? 's' : ''} suivis',
            style: const TextStyle(
              color: _kTextSub,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (alerts > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kRedL,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kRed.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: _kRed, size: 12),
                const SizedBox(width: 4),
                Text(
                  '$alerts alerte${alerts > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: _kRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kGreenL,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: _kGreen, size: 12),
                SizedBox(width: 4),
                Text(
                  'Tout OK',
                  style: TextStyle(
                    color: _kGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════
// MEMBER CARD LIGHT
// ════════════════════════════════════════════════════════════
class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final Map<String, dynamic>? prediction;
  final VoidCallback onTap, onMessage;

  const _MemberCard({
    required this.member,
    required this.onTap,
    required this.onMessage,
    this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    final fatigue = prediction?['fatigue'];
    final injury = prediction?['injury'];
    final overload = prediction?['overload'];
    final isFatigued =
        fatigue?['label']?.toString().toLowerCase().contains('fatigué') ??
        false;
    final isHighRisk =
        injury?['label']?.toString().toLowerCase().contains('élevé') ?? false;
    final hasAlert = isFatigued || isHighRisk;

    final initials = (member['fullName'] as String? ?? '?')
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasAlert ? _kRed.withValues(alpha: 0.3) : _kBorder,
            width: hasAlert ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (hasAlert ? _kRed : _kBlue).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: hasAlert ? _kRedL : _kBlueL,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: (hasAlert ? _kRed : _kBlue).withValues(
                          alpha: 0.25,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: hasAlert ? _kRed : _kBlue,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member['fullName'] ?? '—',
                          style: const TextStyle(
                            color: _kText,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${member['age']} ans • ${member['weight']}kg • ${member['gender'] ?? ''}',
                          style: const TextStyle(
                            color: _kTextSub,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasAlert) ...[
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _kRedL,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: _kRed.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: _kRed,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  GestureDetector(
                    onTap: onMessage,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _kGreenL,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: _kGreen.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: _kGreen,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (prediction != null)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: _kSurf2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: _kGreen,
                          size: 11,
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'ANALYSE IA',
                          style: TextStyle(
                            color: _kGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        if (overload != null)
                          _OverloadChip(
                            riskLevel: overload['riskLevel'] ?? 'NORMAL',
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _AiBar(
                      label: 'Fatigue',
                      value: (fatigue?['confidence'] as num?)?.toDouble() ?? 0,
                      warn: isFatigued,
                    ),
                    const SizedBox(height: 5),
                    _AiBar(
                      label: 'Blessure',
                      value: (injury?['confidence'] as num?)?.toDouble() ?? 0,
                      warn: isHighRisk,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AiBar extends StatelessWidget {
  final String label;
  final double value;
  final bool warn;
  const _AiBar({required this.label, required this.value, required this.warn});
  @override
  Widget build(BuildContext context) {
    final color = warn ? _kRed : _kGreen;
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(color: _kTextSub, fontSize: 10),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: _kBorder,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 34,
          child: Text(
            '${(value * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _OverloadChip extends StatelessWidget {
  final String riskLevel;
  const _OverloadChip({required this.riskLevel});
  @override
  Widget build(BuildContext context) {
    final color = switch (riskLevel) {
      'CRITIQUE' => _kRed,
      'ÉLEVÉ' => _kOrange,
      'MODÉRÉ' => const Color(0xFFF9A825),
      _ => _kGreen,
    };
    final bg = switch (riskLevel) {
      'CRITIQUE' => _kRedL,
      'ÉLEVÉ' => _kOrangeL,
      'MODÉRÉ' => const Color(0xFFFFFDE7),
      _ => _kGreenL,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        riskLevel,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// BOTTOM NAV COACH LIGHT
// ════════════════════════════════════════════════════════════
class _CoachBottomNav extends StatelessWidget {
  final int currentIndex, unreadAdmin;
  final ValueChanged<int> onTap;

  const _CoachBottomNav({
    required this.currentIndex,
    required this.unreadAdmin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        border: const Border(top: BorderSide(color: _kBorder, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                outlinedIcon: Icons.people_outline_rounded,
                filledIcon: Icons.people_rounded,
                label: 'Membres',
                active: currentIndex == 0,
                color: _kBlue,
                onTap: () => onTap(0),
              ),
              _NavItem(
                outlinedIcon: Icons.forum_outlined,
                filledIcon: Icons.forum_rounded,
                label: 'Messages',
                active: currentIndex == 1,
                color: _kOrange,
                onTap: () => onTap(1),
                badge: unreadAdmin,
              ),
              _NavItem(
                outlinedIcon: Icons.person_outline_rounded,
                filledIcon: Icons.person_rounded,
                label: 'Profil',
                active: currentIndex == 2,
                color: _kGreen,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData outlinedIcon, filledIcon;
  final String label;
  final bool active;
  final Color color;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.outlinedIcon,
    required this.filledIcon,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(
          horizontal: active ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.25) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  active ? filledIcon : outlinedIcon,
                  size: 20,
                  color: active ? color : _kTextSub,
                ),
                if (badge > 0)
                  Positioned(
                    top: -5,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _kRed,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kSurface, width: 1.5),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (active) ...[
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
