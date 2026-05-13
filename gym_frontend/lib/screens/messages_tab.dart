// lib/screens/messages_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/message_provider.dart';
import 'messages_screen.dart';
import 'member_admin_chat_screen.dart';

const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kBlue = Color(0xFF1976D2);
const Color _kOrange = Color(0xFFF57C00);
const Color _kRed = Color(0xFFE53935);
const Color _kPurple = Color(0xFF7B1FA2);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class MessagesTab extends ConsumerStatefulWidget {
  final int memberId; // ✅ FIX #3 : paramètre ajouté

  const MessagesTab({super.key, required this.memberId});

  @override
  ConsumerState<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends ConsumerState<MessagesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildChatChip(
                  icon: Icons.sports_rounded,
                  label: 'Coach',
                  badge: unreadCoach,
                  color: _kGreen,
                  onTap: () => _tabController.animateTo(0),
                ),
                const SizedBox(width: 12),
                _buildChatChip(
                  icon: Icons.support_agent_rounded,
                  label: 'Support',
                  badge: unreadAdmin,
                  color: _kPurple,
                  onTap: () => _tabController.animateTo(1),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MessagesScreen(
            memberId: widget.memberId,
            isCoach: false,
          ), // ✅ utilise widget.memberId
          const MemberAdminChatScreen(),
        ],
      ),
    );
  }

  Widget _buildChatChip({
    required IconData icon,
    required String label,
    required int badge,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isActive =
        (label == 'Coach' && _tabController.index == 0) ||
        (label == 'Support' && _tabController.index == 1);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive ? color.withValues(alpha: 0.4) : _kBorder,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? color : _kTextSub, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? color : _kTextSub,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _kRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
