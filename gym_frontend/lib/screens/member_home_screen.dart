import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/message_provider.dart';
import '../providers/member_provider.dart';
import '../providers/subscription_provider.dart'; // ← AJOUTER CETTE LIGNE
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'sessions_tab.dart';
import 'profile_tab.dart';
import 'messages_tab.dart';
import 'login_screen.dart';

// ─── Design tokens ───
const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kGreenL = Color(0xFFE0F2F1);
const Color _kBlue = Color(0xFF1976D2);
const Color _kOrange = Color(0xFFF57C00);
const Color _kPurple = Color(0xFF7B1FA2);
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

  final List<NavItem> _navItems = const [
    NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
      color: _kGreen,
    ),
    NavItem(
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center_rounded,
      label: 'Séances',
      color: _kBlue,
    ),
    NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Mon espace',
      color: _kOrange,
    ),
    NavItem(
      icon: Icons.forum_outlined,
      activeIcon: Icons.forum_rounded,
      label: 'Messages',
      color: _kPurple,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
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
                _MemberHeader(memberId: widget.memberId),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: const [
                      DashboardScreen(
                        memberId: 0,
                      ), // memberId sera récupéré via provider
                      SessionsTab(),
                      ProfileTab(),
                      MessagesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ModernBottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        unreadMessages: totalUnread,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HEADER MODERNE
// ═══════════════════════════════════════════════════════════════

class _MemberHeader extends ConsumerWidget {
  final int memberId;

  const _MemberHeader({required this.memberId});

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
    final daysRemaining = subAsync.valueOrNull?['daysRemaining'] ?? 0;

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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kGreen, Color(0xFF00695C)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
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
                if (subType != null && daysRemaining > 0)
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: daysRemaining < 7 ? _kRed : _kGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$subType • $daysRemaining jours restants',
                        style: TextStyle(
                          color: daysRemaining < 7 ? _kRed : _kTextSub,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _QuickActionButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {},
        ),
        const SizedBox(width: 8),
        _QuickActionButton(
          icon: Icons.logout_rounded,
          onTap: () async {
            await AuthService.logout();
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          },
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _kSurf2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Icon(icon, color: _kTextSub, size: 18),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BOTTOM NAVIGATION MODERNE
// ═══════════════════════════════════════════════════════════════

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}

class _ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<NavItem> items;
  final int unreadMessages;
  final ValueChanged<int> onTap;

  const _ModernBottomNav({
    required this.currentIndex,
    required this.items,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = currentIndex == index;
              final isMessages = item.label == 'Messages';

              return _NavItemWidget(
                item: item,
                isActive: isActive,
                badge: isMessages ? unreadMessages : 0,
                onTap: () => onTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemWidget extends StatelessWidget {
  final NavItem item;
  final bool isActive;
  final int badge;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isActive,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 0,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? item.color.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 22,
                  color: isActive ? item.color : _kTextSub,
                ),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
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
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                item.label,
                style: TextStyle(
                  color: item.color,
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

// ═══════════════════════════════════════════════════════════════
// BACKGROUND ANIMÉ
// ═══════════════════════════════════════════════════════════════

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
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFECF8F6), _kBg],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

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

    final grid = Paint()
      ..color = _kGreen.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    for (double y = 0; y < size.height; y += step)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
