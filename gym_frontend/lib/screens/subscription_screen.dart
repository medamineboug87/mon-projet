import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';
import '../services/plan_service.dart';
import 'payment_screen.dart';

// ─── Design tokens light ───
const Color _kBg      = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2   = Color(0xFFEEF1F8);
const Color _kGreen   = Color(0xFF00897B);
const Color _kGreenL  = Color(0xFFE0F2F1);
const Color _kGreenDark = Color(0xFF00695C);
const Color _kBlue    = Color(0xFF1976D2);
const Color _kBlueL   = Color(0xFFE3F2FD);
const Color _kOrange  = Color(0xFFF57C00);
const Color _kOrangeL = Color(0xFFFFF3E0);
const Color _kRed     = Color(0xFFE53935);
const Color _kRedL    = Color(0xFFFFEBEE);
const Color _kPurple  = Color(0xFF7B1FA2);
const Color _kPurpleL = Color(0xFFF3E5F5);
const Color _kText    = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder  = Color(0xFFDDE2EE);


class SubscriptionScreen extends ConsumerStatefulWidget {
  final int memberId;

  const SubscriptionScreen({super.key, required this.memberId});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  List<SubscriptionPlanModel> _plans = [];
  bool _plansLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final plans = await PlanService.getActivePlans();
    if (mounted) {
      setState(() {
        _plans = plans;
        _plansLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionAsync = ref.watch(
      activeSubscriptionProvider(widget.memberId),
    );

    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        title: const Text(
          'Mon Abonnement',
          style: TextStyle(color: _kText),
        ),
        backgroundColor: const Color(0xFFEEF1F8),
        iconTheme: const IconThemeData(color: _kText),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _kText),
            onPressed: () {
              ref.invalidate(activeSubscriptionProvider(widget.memberId));
              _loadPlans();
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
              await _loadPlans();
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
            ElevatedButton(onPressed: () {}, child: const Text('Réessayer')),
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
    final sub = subscriptionData?['subscription'];
    final status = subscriptionData?['status'] ?? 'ACTIF';
    final daysRemaining = subscriptionData?['daysRemaining'] ?? 0;
    final isExpiring = subscriptionData?['isExpiring'] ?? false;
    final isExpired = subscriptionData?['isExpired'] ?? false;
    final bool isLocked = !isExpired;

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
                    color: _kText,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getPlanDisplayName(sub?['type'] ?? 'N/A'),
                    style: const TextStyle(
                      color: _kText,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${sub?['price']} DT / ${sub?['duration']} mois',
                style: const TextStyle(color: _kText),
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
                      color: _kText.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: _kText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '$daysRemaining jours restants',
                    style: const TextStyle(color: _kText),
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
              border: Border.all(
                color: _kOrange.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: _kOrange,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vous pouvez changer d\'abonnement dans $daysRemaining jours.',
                    style: const TextStyle(
                      color: _kOrange,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),
        const Text(
          'Nos abonnements',
          style: TextStyle(
            color: _kText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildPlansList(
          context,
          ref,
          isLocked: isLocked,
          currentType: sub?['type'],
        ),
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
                  'Aucun abonnement actif. Choisissez un plan pour accéder à toutes les fonctionnalités.',
                  style: TextStyle(color: _kText, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Choisissez votre abonnement',
          style: TextStyle(
            color: _kText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildPlansList(context, ref, isLocked: false, currentType: null),
      ],
    );
  }

  Widget _buildPlansList(
    BuildContext context,
    WidgetRef ref, {
    required bool isLocked,
    required String? currentType,
  }) {
    if (_plansLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: _kGreen),
        ),
      );
    }

    return Column(
      children: _plans
          .map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPlanCard(
                context,
                plan,
                ref,
                isLocked: isLocked,
                currentType: currentType,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    SubscriptionPlanModel plan,
    WidgetRef ref, {
    required bool isLocked,
    required String? currentType,
  }) {
    final isCurrentPlan = currentType == plan.name;
    final Color planColor = _hexToColor(plan.color);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentPlan ? planColor : planColor.withValues(alpha: 0.3),
          width: isCurrentPlan ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Emoji
              Text(plan.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.displayName,
                      style: TextStyle(
                        color: planColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (plan.description != null &&
                        plan.description!.isNotEmpty)
                      Text(
                        plan.description!,
                        style: const TextStyle(
                          color: _kTextSub,
                          fontSize: 11,
                        ),
                      ),
                    Text(
                      plan.durationLabel,
                      style: const TextStyle(
                        color: _kTextSub,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${plan.price.toStringAsFixed(0)} DT',
                    style: const TextStyle(
                      color: _kText,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (isCurrentPlan)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: planColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Actuel',
                        style: TextStyle(color: planColor, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (!isCurrentPlan) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: isLocked
                  ? ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock, size: 16),
                      label: const Text('Non disponible'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBorder,
                        foregroundColor: Colors.black38,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              memberId: widget.memberId,
                              subscriptionType: plan.name,
                              amount: plan.price,
                            ),
                          ),
                        ).then(
                          (_) => ref.invalidate(
                            activeSubscriptionProvider(widget.memberId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: planColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Souscrire',
                        style: TextStyle(color: _kText),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  String _getPlanDisplayName(String type) {
    // Chercher dans les plans chargés
    final match = _plans.where((p) => p.name == type);
    if (match.isNotEmpty) return match.first.displayName;
    // Fallback
    return type;
  }

  Color _hexToColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return _kGreen;
    }
  }
}