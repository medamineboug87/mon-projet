// lib/screens/messages_tab.dart
// ✅ REDESIGN : version mobile-first épurée
// - Tabs Coach / Support fins et compacts (hauteur 44px)
// - Badges non-lus bien visibles
// - Pas de double Scaffold

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/message_provider.dart';
import 'messages_screen.dart';
import 'member_admin_chat_screen.dart';

const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kPurple = Color(0xFF7B1FA2);
const Color _kRed = Color(0xFFE53935);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class MessagesTab extends ConsumerStatefulWidget {
  final int memberId;

  const MessagesTab({super.key, required this.memberId});

  @override
  ConsumerState<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends ConsumerState<MessagesTab> {
  int _selectedIndex = 0; // 0 = Coach, 1 = Support

  @override
  Widget build(BuildContext context) {
    final unreadCoach =
        ref.watch(memberUnreadFromCoachProvider).valueOrNull ?? 0;
    final unreadAdmin =
        ref.watch(memberUnreadFromAdminProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            color: _kText,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Tabs fins pleine largeur ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _TabChip(
                    icon: Icons.sports_rounded,
                    label: 'Coach',
                    badge: unreadCoach,
                    color: _kGreen,
                    isSelected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TabChip(
                    icon: Icons.support_agent_rounded,
                    label: 'Support',
                    badge: unreadAdmin,
                    color: _kPurple,
                    isSelected: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                ),
              ],
            ),
          ),

          // ── Contenu ──
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                MessagesScreen(memberId: widget.memberId, isCoach: false),
                const MemberAdminChatScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget tab chip réutilisable ──
class _TabChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabChip({
    required this.icon,
    required this.label,
    required this.badge,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : _kSurf2,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.4) : _kBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : _kTextSub, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : _kTextSub,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _kRed,
                  borderRadius: BorderRadius.circular(16),
                ),
                constraints: const BoxConstraints(minWidth: 20),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
