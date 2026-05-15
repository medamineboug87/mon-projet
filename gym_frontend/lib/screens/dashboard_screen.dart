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

// ─── Design tokens ───
const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kGreenL = Color(0xFFE0F2F1);
const Color _kGreenDark = Color(0xFF00695C);
const Color _kBlue = Color(0xFF1976D2);
const Color _kBlueL = Color(0xFFE3F2FD);
const Color _kOrange = Color(0xFFF57C00);
const Color _kOrangeL = Color(0xFFFFF3E0);
const Color _kRed = Color(0xFFE53935);
const Color _kRedL = Color(0xFFFFEBEE);
const Color _kPurple = Color(0xFF7B1FA2);
const Color _kPurpleL = Color(0xFFF3E5F5);
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
    final daysRemaining = subscriptionData?['daysRemaining'] ?? 0;

    return RefreshIndicator(
      onRefresh: () => _refreshData(ref),
      color: _kGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. CARTE DE BIENVENUE ──
            _buildWelcomeCard(
              member,
              subscriptionType,
              isExpiring,
              daysRemaining,
            ),
            const SizedBox(height: 20),

            // ── 2. ANALYSE IA (section mise en avant) ──
            if (lastPrediction != null) ...[
              _buildAIAnalysisSection(lastPrediction),
              const SizedBox(height: 20),
            ],

            // ── 3. ACTIONS RAPIDES ──
            _buildQuickActionsSection(context, ref),
            const SizedBox(height: 20),

            // ── 4. DERNIÈRES SÉANCES ──
            _buildRecentSessionsSection(context, recentSessions),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 1. CARTE DE BIENVENUE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildWelcomeCard(
    Map<String, dynamic>? member,
    String? subscriptionType,
    bool isExpiring,
    int daysRemaining,
  ) {
    final name = member?['fullName']?.split(' ').first ?? 'Membre';
    final today = DateTime.now();
    final dayName = _getDayName(today.weekday);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpiring ? [_kOrange, _kRed] : [_kGreen, _kGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpiring
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        subscriptionType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Bonjour $name 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bon $dayName ! Prêt pour une nouvelle séance ?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          if (isExpiring && daysRemaining > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.hourglass_empty_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Votre abonnement expire dans $daysRemaining jour${daysRemaining > 1 ? 's' : ''}. Rendez-vous dans "Mon espace" pour le renouveler.',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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

  // ═══════════════════════════════════════════════════════════════
  // 2. ANALYSE IA (section mise en avant)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAIAnalysisSection(Map<String, dynamic> prediction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de section
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kPurple, _kBlue]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Analyse IA',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kText,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kPurpleL,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'DERNIÈRE SÉANCE',
                style: TextStyle(
                  color: _kPurple,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SessionPredictionCard(prediction: prediction),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. ACTIONS RAPIDES
  // ═══════════════════════════════════════════════════════════════

  Widget _buildQuickActionsSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ Actions rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _kText,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                title: 'Nouvelle séance',
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
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. DERNIÈRES SÉANCES
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRecentSessionsSection(
    BuildContext context,
    List<dynamic> sessions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            if (sessions.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SessionsHistoryScreen(memberId: memberId),
                  ),
                ),
                style: TextButton.styleFrom(foregroundColor: _kGreen),
                child: const Text('Voir tout'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          _buildEmptySessions(context)
        else
          ...sessions.map(
            (session) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildSessionCard(session),
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _kGreenL,
              borderRadius: BorderRadius.circular(14),
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
                  _formatDate(session['date']),
                  style: const TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildSessionStat(
                      '${session['duration']} min',
                      Icons.timer_outlined,
                    ),
                    const SizedBox(width: 10),
                    _buildSessionStat(
                      '${session['weightLifted']} kg',
                      Icons.fitness_center,
                    ),
                    if (session['hasCardio'] == true) ...[
                      const SizedBox(width: 10),
                      _buildSessionStat('Cardio', Icons.favorite),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
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

  Widget _buildSessionStat(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _kTextSub),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: _kTextSub, fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptySessions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _kSurf2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.fitness_center_outlined,
                size: 32,
                color: _kTextSub,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune séance enregistrée',
              style: TextStyle(
                color: _kText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Commencez votre première séance !',
              style: TextStyle(color: _kTextSub, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewSessionScreen(memberId: memberId),
                  ),
                );
              },
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text('Commencer une séance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
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
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 42,
                  color: _kRed,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Impossible de charger les données',
                style: TextStyle(
                  color: _kText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vérifiez votre connexion et réessayez',
                style: TextStyle(color: _kTextSub, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _refreshData(ref),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// ACTION CARD
// ═══════════════════════════════════════════════════════════════

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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
