import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_service.dart';

// ─── Design tokens light ───
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kOrange = Color(0xFFF57C00);
const Color _kRed = Color(0xFFE53935);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class SubscriptionScreen extends ConsumerStatefulWidget {
  final int memberId;

  const SubscriptionScreen({super.key, required this.memberId});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionAsync = ref.watch(
      activeSubscriptionProvider(widget.memberId),
    );

    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        title: const Text('Mon Abonnement', style: TextStyle(color: _kText)),
        backgroundColor: const Color(0xFFEEF1F8),
        iconTheme: const IconThemeData(color: _kText),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _kText),
            onPressed: () {
              ref.invalidate(activeSubscriptionProvider(widget.memberId));
            },
          ),
        ],
      ),
      body: subscriptionAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.green)),
        error: (error, stack) => _buildErrorScreen(error),
        data: (subscriptionData) {
          final hasSubscription = subscriptionData?['hasSubscription'] ?? false;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(activeSubscriptionProvider(widget.memberId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasSubscription)
                    _buildNoSubscription(context, ref)
                  else
                    _buildSubscriptionDetails(context, subscriptionData, ref),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorScreen(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'Impossible de charger l\'abonnement',
              style: TextStyle(color: _kText, fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () =>
                  ref.invalidate(activeSubscriptionProvider(widget.memberId)),
              style: ElevatedButton.styleFrom(backgroundColor: _kGreen),
              child: const Text(
                'Réessayer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetails(
    BuildContext context,
    Map<String, dynamic>? subscriptionData,
    WidgetRef ref,
  ) {
    // FIX #17 : null-safety complète sur sub
    final sub = subscriptionData?['subscription'] as Map<String, dynamic>?;
    final status = subscriptionData?['status'] ?? 'ACTIF';
    final daysRemaining = subscriptionData?['daysRemaining'] ?? 0;
    final bool isExpired =
        status == 'EXPIRED' || subscriptionData?['isExpired'] == true;
    final bool isExpiring =
        status == 'EXPIRING_SOON' || subscriptionData?['isExpiring'] == true;
    final bool isLocked = !isExpired;

    // FIX #17 : extraction sécurisée du type et du prix
    final String subType = sub?['type']?.toString() ?? 'N/A';
    final dynamic rawPrice = sub?['price'];
    final dynamic rawDuration = sub?['duration'];
    final String priceLabel = rawPrice != null ? '$rawPrice DT' : 'N/A';
    final String durationLabel = rawDuration != null
        ? '$rawDuration mois'
        : 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Carte abonnement actuel ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isExpired
                  ? [Colors.red.shade900, Colors.red.shade700]
                  : isExpiring
                  ? [Colors.orange.shade900, Colors.orange.shade700]
                  : [const Color(0xFF1B5E20), _kGreen],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.card_membership,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    subType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // FIX #17 : affichage sécurisé prix / durée
              Text(
                '$priceLabel / $durationLabel',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                      status.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '$daysRemaining jours restants',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (isLocked)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kOrange.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: _kOrange, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vous pouvez changer d\'abonnement dans $daysRemaining jours.',
                    style: const TextStyle(color: _kOrange, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),
        const Text(
          'Historique de mes abonnements',
          style: TextStyle(
            color: _kText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildHistory(),
      ],
    );
  }

  Widget _buildNoSubscription(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kRed.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber, color: _kRed),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Aucun abonnement actif.',
                  style: TextStyle(color: _kText, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Historique de mes abonnements',
          style: TextStyle(
            color: _kText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildHistory(),
      ],
    );
  }

  Widget _buildHistory() {
    return FutureBuilder<List<dynamic>>(
      future: SubscriptionService.getMemberSubscriptions(widget.memberId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _kGreen));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kSurf2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: const Center(
              child: Text(
                'Aucun historique disponible.',
                style: TextStyle(color: _kTextSub),
              ),
            ),
          );
        }

        final history = snapshot.data!;
        return Column(
          children: history.map((sub) {
            final status = sub['status'] ?? '';
            final type = sub['type'] ?? 'N/A';
            final price = (sub['price'] as num?)?.toDouble() ?? 0;
            final startDate = sub['startDate'] ?? '';
            final endDate = sub['endDate'] ?? '';

            Color statusColor = status == 'ACTIVE'
                ? _kGreen
                : status == 'CANCELLED'
                ? _kRed
                : _kOrange;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kSurf2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type,
                          style: const TextStyle(
                            color: _kText,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$startDate → $endDate',
                          style: const TextStyle(
                            color: _kTextSub,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${price.toStringAsFixed(0)} DT',
                        style: const TextStyle(
                          color: _kText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
