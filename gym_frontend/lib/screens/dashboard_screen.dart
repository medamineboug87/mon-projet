// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/member_provider.dart';
import '../providers/session_provider.dart';
import '../providers/prediction_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/auth_service.dart';
import '../widgets/session/session_prediction_card.dart';
import 'new_session_screen.dart';
import 'sessions_history_screen.dart';
import 'login_screen.dart';
import 'messages_screen.dart';
import 'unified_profile_screen.dart';

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

class DashboardScreen extends ConsumerWidget {
  final int memberId;
  const DashboardScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberProvider(memberId));
    final recentSessionsAsync = ref.watch(recentSessionsProvider(memberId));
    final lastPredictionAsync = ref.watch(lastPredictionProvider(memberId));
    final subscriptionAsync = ref.watch(activeSubscriptionProvider(memberId));

    final isLoading = memberAsync.isLoading || recentSessionsAsync.isLoading;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kGreen));
    }

    if (memberAsync.hasError) {
      return _buildErrorScreen(context, ref);
    }

    final member = memberAsync.valueOrNull;
    final recentSessions = recentSessionsAsync.valueOrNull ?? [];
    final lastPrediction = lastPredictionAsync.valueOrNull;
    final subscriptionData = subscriptionAsync.valueOrNull;
    final subscriptionType = subscriptionData?['subscription']?['type'];
    final isExpiring = subscriptionData?['isExpiring'] ?? false;

    return RefreshIndicator(
      onRefresh: () => _refreshData(ref),
      color: _kGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Carte de bienvenue ──
            _buildWelcomeCard(member, subscriptionType, isExpiring),
            const SizedBox(height: 20),

            // ── Prédiction IA ──
            if (lastPrediction != null) ...[
              const Text(
                '📊 Analyse IA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kText,
                ),
              ),
              const SizedBox(height: 12),
              SessionPredictionCard(prediction: lastPrediction),
              const SizedBox(height: 20),
            ],

            // ── Actions rapides ──
            const Text(
              '⚡ Actions rapides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kText,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(context, ref),

            const SizedBox(height: 20),

            // ── Dernières séances ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📅 Dernières séances',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _kText,
                  ),
                ),
                if (recentSessions.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SessionsHistoryScreen(memberId: memberId),
                      ),
                    ),
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(color: _kGreen),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentSessions.isEmpty)
              _buildEmptySessions()
            else
              ...recentSessions.map(
                (session) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildSessionCard(session),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(
    Map<String, dynamic>? member,
    String? subscriptionType,
    bool isExpiring,
  ) {
    final name = member?['fullName']?.split(' ').first ?? 'Membre';
    final today = DateTime.now();
    final dayName = _getDayName(today.weekday);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpiring
              ? [_kOrange, _kRed]
              : [_kGreen, const Color(0xFF00695C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isExpiring ? _kOrange : _kGreen).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 28),
              const Spacer(),
              if (subscriptionType != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subscriptionType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Bonjour $name 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bon $dayName ! Prêt pour une nouvelle séance ?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          if (isExpiring) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Votre abonnement expire bientôt ! Pensez à le renouveler.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            title: 'Nouvelle\nséance',
            icon: Icons.add_rounded,
            color: _kGreen,
            bg: _kGreenL,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewSessionScreen(memberId: memberId),
                ),
              );
              if (result == true) _refreshData(ref);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            title: 'Historique',
            icon: Icons.history_rounded,
            color: _kBlue,
            bg: _kBlueL,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SessionsHistoryScreen(memberId: memberId),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            title: 'Messages',
            icon: Icons.chat_bubble_outline_rounded,
            color: _kOrange,
            bg: _kOrangeL,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MessagesScreen(memberId: memberId, isCoach: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kGreenL,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: _kGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session['date'] ?? 'N/A',
                  style: const TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session['duration']} min • ${session['weightLifted']} kg',
                  style: const TextStyle(color: _kTextSub, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kSurf2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: _kTextSub,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySessions() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _kSurf2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.fitness_center_outlined, size: 48, color: _kTextSub),
            SizedBox(height: 12),
            Text(
              'Aucune séance enregistrée',
              style: TextStyle(color: _kTextSub),
            ),
            SizedBox(height: 4),
            Text(
              'Commencez votre première séance !',
              style: TextStyle(color: _kTextSub, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _kRedL,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: _kRed,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Impossible de charger les données',
              style: TextStyle(
                color: _kText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _refreshData(ref),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(backgroundColor: _kGreen),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData(WidgetRef ref) async {
    ref.invalidate(memberProvider(memberId));
    ref.invalidate(sessionsProvider(memberId));
    ref.invalidate(recentSessionsProvider(memberId));
    ref.invalidate(lastPredictionProvider(memberId));
    ref.invalidate(activeSubscriptionProvider(memberId));
  }

  String _getDayName(int weekday) {
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    return days[weekday - 1];
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
