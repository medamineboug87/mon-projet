import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../providers/member_provider.dart';
import '../providers/session_provider.dart';
import '../providers/prediction_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/index.dart';
import 'new_session_screen.dart';
import 'sessions_history_screen.dart';
import 'login_screen.dart';
import 'messages_screen.dart';

// ─── Design tokens light ───
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
    if (isLoading)
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: LoadingIndicator(),
      );
    if (memberAsync.hasError)
      return _buildErrorScreen(context, ref, memberAsync.error);

    final member = memberAsync.valueOrNull;
    final recentSessions = recentSessionsAsync.valueOrNull ?? [];
    final lastPrediction = lastPredictionAsync.valueOrNull;
    final subscriptionData = subscriptionAsync.valueOrNull;
    final subscriptionType = subscriptionData?['subscription']?['type'];
    final fatigueData = lastPrediction?['fatigue'];
    final injuryData = lastPrediction?['injury'];
    final overloadData = lastPrediction?['overload'];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: _kText, fontWeight: FontWeight.w800),
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: _kBorder),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kTextSub),
            onPressed: () => _refreshData(ref),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: _kTextSub),
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshData(ref),
        color: _kGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bienvenue
              Text(
                'Bonjour ${member?['fullName'] ?? 'Membre'} 👋',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _kText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${recentSessions.length} séances récentes',
                style: const TextStyle(color: _kTextSub, fontSize: 14),
              ),
              const SizedBox(height: 14),

              // Badge abonnement
              if (subscriptionType != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _kGreenL,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: _kGreen, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Abonnement $subscriptionType',
                        style: const TextStyle(
                          color: _kGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Alertes IA
              if (lastPrediction != null) ...[
                _SectionTitle(
                  'Alertes IA',
                  Icons.auto_awesome_rounded,
                  _kGreen,
                ),
                const SizedBox(height: 12),
                _AlertCard(
                  title: 'Fatigue',
                  label: fatigueData?['label'] ?? 'N/A',
                  confidence: (fatigueData?['confidence'] ?? 0.0).toDouble(),
                  isWarning: (fatigueData?['label'] ?? '')
                      .toLowerCase()
                      .contains('fatigué'),
                  icon: Icons.battery_alert_rounded,
                ),
                const SizedBox(height: 10),
                _AlertCard(
                  title: 'Risque de blessure',
                  label: injuryData?['label'] ?? 'N/A',
                  confidence: (injuryData?['confidence'] ?? 0.0).toDouble(),
                  isWarning: (injuryData?['label'] ?? '')
                      .toLowerCase()
                      .contains('élevé'),
                  icon: Icons.healing_rounded,
                ),
                if (overloadData != null) ...[
                  const SizedBox(height: 10),
                  _OverloadCard(overload: overloadData),
                ],
                const SizedBox(height: 24),
              ],

              // Actions rapides
              _SectionTitle('Actions rapides', Icons.flash_on_rounded, _kBlue),
              const SizedBox(height: 12),
              Row(
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
                            builder: (_) =>
                                NewSessionScreen(memberId: memberId),
                          ),
                        );
                        if (result == true && context.mounted)
                          _refreshData(ref);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionCard(
                      title: 'Historique',
                      icon: Icons.history_rounded,
                      color: _kBlue,
                      bg: _kBlueL,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SessionsHistoryScreen(memberId: memberId),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionCard(
                      title: 'Messages',
                      icon: Icons.chat_bubble_outline_rounded,
                      color: _kOrange,
                      bg: _kOrangeL,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MessagesScreen(
                            memberId: memberId,
                            isCoach: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Dernières séances
              _SectionTitle(
                'Dernières séances',
                Icons.fitness_center_rounded,
                _kOrange,
              ),
              const SizedBox(height: 12),
              if (recentSessions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kBorder),
                  ),
                  child: const Center(
                    child: Text(
                      'Aucune séance enregistrée',
                      style: TextStyle(color: _kTextSub),
                    ),
                  ),
                )
              else
                ...recentSessions.map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SessionCard(session: session),
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

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await AuthService.logout();
    ref.invalidate(memberProvider(memberId));
    ref.invalidate(sessionsProvider(memberId));
    ref.invalidate(recentSessionsProvider(memberId));
    ref.invalidate(lastPredictionProvider(memberId));
    ref.invalidate(activeSubscriptionProvider(memberId));
    if (context.mounted)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
  }

  Widget _buildErrorScreen(BuildContext context, WidgetRef ref, Object? error) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: _kText)),
        backgroundColor: _kSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: _kTextSub),
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
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
                label: const Text(
                  'Réessayer',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGETS LOCAUX
// ─────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionTitle(this.title, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: _kText,
        ),
      ),
    ],
  );
}

class _AlertCard extends StatelessWidget {
  final String title, label;
  final double confidence;
  final bool isWarning;
  final IconData icon;
  const _AlertCard({
    required this.title,
    required this.label,
    required this.confidence,
    required this.isWarning,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    final color = isWarning ? _kRed : _kGreen;
    final bg = isWarning ? _kRedL : _kGreenL;
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: confidence,
                    backgroundColor: _kSurf2,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(confidence * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverloadCard extends StatelessWidget {
  final Map<String, dynamic> overload;
  const _OverloadCard({required this.overload});
  @override
  Widget build(BuildContext context) {
    final riskLevel = overload['riskLevel'] ?? 'NORMAL';
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.analytics_rounded, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Charge hebdomadaire',
                  style: TextStyle(color: _kText, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${overload['sessionCount']} séances • ${overload['totalMinutes']} min',
                  style: const TextStyle(color: _kTextSub, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              riskLevel,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 22),
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

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  const _SessionCard({required this.session});
  @override
  Widget build(BuildContext context) => Container(
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _kGreenL,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.fitness_center_rounded, color: _kGreen),
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
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${session['duration']} min • ${session['weightLifted']} kg',
                style: const TextStyle(color: _kTextSub, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _kGreenL,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.chevron_right_rounded,
            color: _kGreen,
            size: 18,
          ),
        ),
      ],
    ),
  );
}
