import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/message_provider.dart';
import '../providers/member_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'sessions_history_screen.dart';
import 'messages_screen.dart';
import 'login_screen.dart';
import 'subscription_screen.dart';
import 'profile_screen.dart';
import 'workout_plan_screen.dart';
import 'member_admin_chat_screen.dart';

// ─── Design tokens light ───
const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kGreenL = Color(0xFFE0F2F1);
const Color _kBlue = Color(0xFF1976D2);
const Color _kOrange = Color(0xFFF57C00);
const Color _kRed = Color(0xFFE53935);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class MemberHomeScreen extends ConsumerStatefulWidget {
  final int memberId;
  const MemberHomeScreen({super.key, required this.memberId});
  @override
  ConsumerState<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends ConsumerState<MemberHomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _bgController;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _screens = [
      _HomeTab(memberId: widget.memberId),
      SessionsHistoryScreen(memberId: widget.memberId),
      _MessagesHub(memberId: widget.memberId),
      _ProfileHub(memberId: widget.memberId),
    ];
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCoach =
        ref.watch(memberUnreadFromCoachProvider).valueOrNull ?? 0;
    final unreadAdmin =
        ref.watch(memberUnreadFromAdminProvider).valueOrNull ?? 0;
    final totalUnread = unreadCoach + unreadAdmin;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          _SportBgLight(controller: _bgController),
          SafeArea(
            child: Column(
              children: [
                _MemberTopBar(memberId: widget.memberId),
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: _screens),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _MemberBottomNav(
        currentIndex: _currentIndex,
        unreadMessages: totalUnread,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BACKGROUND SPORT LIGHT (animé)
// ─────────────────────────────────────────────
class _SportBgLight extends AnimatedWidget {
  const _SportBgLight({required AnimationController controller})
    : super(listenable: controller);
  @override
  Widget build(BuildContext context) {
    final t = (listenable as AnimationController).value;
    return CustomPaint(painter: _SportBgLightPainter(t), child: Container());
  }
}

class _SportBgLightPainter extends CustomPainter {
  final double t;
  const _SportBgLightPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Fond dégradé pastel
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFECF8F6), _kBg],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // Orbe animé vert top-right
    final orb1 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              _kGreen.withValues(alpha: 0.10 + t * 0.04),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width - 10 + t * 20, -15 + t * 10),
              radius: 180,
            ),
          );
    canvas.drawCircle(
      Offset(size.width - 10 + t * 20, -15 + t * 10),
      180,
      orb1,
    );

    // Orbe bleu bottom-left
    final orb2 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              _kBlue.withValues(alpha: 0.07 + t * 0.03),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(-30 + t * 15, size.height + 10 - t * 20),
              radius: 150,
            ),
          );
    canvas.drawCircle(
      Offset(-30 + t * 15, size.height + 10 - t * 20),
      150,
      orb2,
    );

    // Grille très fine
    final grid = Paint()
      ..color = _kGreen.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    for (double y = 0; y < size.height; y += step)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);

    // Haltère top-left animé
    _drawDumbbell(canvas, Offset(28, 60 + t * 6), 0.07 + t * 0.02);
    // Haltère bottom-right
    _drawDumbbell(
      canvas,
      Offset(size.width - 32, size.height - 180 - t * 8),
      0.06,
    );
    // Hexagone top-right
    _drawHex(canvas, Offset(size.width - 50, 100 + t * 10), 44);
    // Rond pulse
    final ring = Paint()
      ..color = _kGreen.withValues(alpha: 0.04 + t * 0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(
      Offset(size.width + 10, size.height - 80),
      90 + t * 25,
      ring,
    );
  }

  void _drawDumbbell(Canvas canvas, Offset c, double opacity) {
    final p = Paint()
      ..color = _kGreen.withValues(alpha: opacity)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    canvas.drawLine(Offset(c.dx - 18, c.dy), Offset(c.dx + 18, c.dy), p);
    final pl = Paint()
      ..color = _kGreen.withValues(alpha: opacity + 0.02)
      ..style = PaintingStyle.fill;
    for (final dx in [-18.0, 18.0])
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(c.dx + dx, c.dy),
            width: 8,
            height: 18,
          ),
          const Radius.circular(3),
        ),
        pl,
      );
  }

  void _drawHex(Canvas canvas, Offset center, double r) {
    final p = Paint()
      ..color = _kBlue.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
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
  }

  @override
  bool shouldRepaint(_SportBgLightPainter old) => old.t != t;
}

// ─────────────────────────────────────────────
// TOP BAR LIGHT
// ─────────────────────────────────────────────
class _MemberTopBar extends ConsumerWidget {
  final int memberId;
  const _MemberTopBar({required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberProvider(memberId));
    final subAsync = ref.watch(activeSubscriptionProvider(memberId));
    final fullName =
        memberAsync.valueOrNull?['fullName']?.toString() ?? 'Membre';
    final firstName = fullName.split(' ').first;
    final initials = fullName.trim().isEmpty
        ? 'M'
        : fullName
              .trim()
              .split(' ')
              .map((w) => w[0].toUpperCase())
              .take(2)
              .join();
    final subType = subAsync.valueOrNull?['subscription']?['type'];

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
                colors: [Color(0xFF00897B), Color(0xFF00695C)],
              ),
              borderRadius: BorderRadius.circular(12),
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
                  firstName,
                  style: const TextStyle(
                    color: _kText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          if (subType != null) _SubBadge(type: subType),
        ],
      ),
    );
  }
}

class _SubBadge extends StatelessWidget {
  final String type;
  const _SubBadge({required this.type});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _kGreenL,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: _kGreen, size: 12),
        const SizedBox(width: 4),
        Text(
          type,
          style: const TextStyle(
            color: _kGreen,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
// HOME / MESSAGES / PROFILE TABS
// ─────────────────────────────────────────────
class _HomeTab extends ConsumerWidget {
  final int memberId;
  const _HomeTab({required this.memberId});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      DashboardScreen(memberId: memberId);
}

class _MessagesHub extends ConsumerStatefulWidget {
  final int memberId;
  const _MessagesHub({required this.memberId});
  @override
  ConsumerState<_MessagesHub> createState() => _MessagesHubState();
}

class _MessagesHubState extends ConsumerState<_MessagesHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCoach =
        ref.watch(memberUnreadFromCoachProvider).valueOrNull ?? 0;
    final unreadAdmin =
        ref.watch(memberUnreadFromAdminProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: _kText,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            color: _kSurface,
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: _kGreen,
              indicatorWeight: 2,
              labelColor: _kGreen,
              unselectedLabelColor: _kTextSub,
              tabs: [
                _buildTab(Icons.sports_rounded, 'Coach', unreadCoach),
                _buildTab(
                  Icons.admin_panel_settings_rounded,
                  'Support',
                  unreadAdmin,
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          MessagesScreen(memberId: widget.memberId, isCoach: false),
          const MemberAdminChatScreen(),
        ],
      ),
    );
  }

  Tab _buildTab(IconData icon, String label, int badge) => Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        if (badge > 0) ...[const SizedBox(width: 5), _Badge(count: badge)],
      ],
    ),
  );
}

class _ProfileHub extends ConsumerStatefulWidget {
  final int memberId;
  const _ProfileHub({required this.memberId});
  @override
  ConsumerState<_ProfileHub> createState() => _ProfileHubState();
}

class _ProfileHubState extends ConsumerState<_ProfileHub> {
  int _section = 0;

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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Mon espace',
          style: TextStyle(
            color: _kText,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: _kTextSub, size: 20),
            onPressed: _logout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: _kSurface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _Chip(
                  label: 'Profil',
                  icon: Icons.person_rounded,
                  active: _section == 0,
                  onTap: () => setState(() => _section = 0),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: 'Abonnement',
                  icon: Icons.card_membership_rounded,
                  active: _section == 1,
                  onTap: () => setState(() => _section = 1),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: 'Plans',
                  icon: Icons.calendar_month_rounded,
                  active: _section == 2,
                  onTap: () => setState(() => _section = 2),
                ),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _section,
        children: [
          ProfileScreen(memberId: widget.memberId),
          SubscriptionScreen(memberId: widget.memberId),
          const WorkoutPlanScreen(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM NAV LIGHT
// ─────────────────────────────────────────────
class _MemberBottomNav extends StatelessWidget {
  final int currentIndex;
  final int unreadMessages;
  final ValueChanged<int> onTap;

  const _MemberBottomNav({
    required this.currentIndex,
    required this.unreadMessages,
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
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Accueil',
                active: currentIndex == 0,
                color: _kGreen,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.fitness_center_outlined,
                activeIcon: Icons.fitness_center_rounded,
                label: 'Séances',
                active: currentIndex == 1,
                color: _kBlue,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.forum_outlined,
                activeIcon: Icons.forum_rounded,
                label: 'Messages',
                active: currentIndex == 2,
                color: _kOrange,
                onTap: () => onTap(2),
                badge: unreadMessages,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Moi',
                active: currentIndex == 3,
                color: _kGreen,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool active;
  final Color color;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
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
        curve: Curves.easeOutCubic,
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
                  active ? activeIcon : icon,
                  size: 20,
                  color: active ? color : _kTextSub,
                ),
                if (badge > 0)
                  Positioned(top: -5, right: -7, child: _Badge(count: badge)),
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

// ─────────────────────────────────────────────
// WIDGETS PARTAGÉS
// ─────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: _kRed,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _kSurface, width: 1.5),
    ),
    child: Text(
      count > 99 ? '99+' : '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _kGreenL : _kSurf2,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? _kGreen.withValues(alpha: 0.35) : _kBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? _kGreen : _kTextSub),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? _kGreen : _kTextSub,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
