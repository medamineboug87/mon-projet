import 'package:flutter/material.dart';
import '../shared/progression_card.dart';
import '../shared/rest_recommendation_card.dart';

const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kGreenDark = Color(0xFF00695C);
const Color _kGreenL = Color(0xFFE0F2F1);
const Color _kBlue = Color(0xFF1976D2);
const Color _kOrange = Color(0xFFF57C00);
const Color _kRed = Color(0xFFE53935);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class SessionPredictionCard extends StatelessWidget {
  final Map<String, dynamic> prediction;

  const SessionPredictionCard({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final fatigue = prediction['fatigue'] as Map<String, dynamic>?;
    final injury = prediction['injury'] as Map<String, dynamic>?;
    final overload = prediction['overload'] as Map<String, dynamic>?;

    final fatigueLbl = fatigue?['label'] ?? 'N/A';

    // FIX 4.4 / 1.1 — "risque modéré" est maintenant un label valide
    final injuryLbl = injury?['label'] ?? 'N/A';

    // FIX 1.1 — lire riskLevel (camelCase Java) avec fallback snake_case Python
    final riskLevel =
        overload?['riskLevel'] ?? overload?['risk_level'] ?? 'NORMAL';

    // FIX 3.4 — riskLevel "NON_DISPONIBLE" → afficher NORMAL par défaut
    final displayRiskLevel = riskLevel == 'NON_DISPONIBLE'
        ? 'NORMAL'
        : riskLevel;

    final warnings = (overload?['warnings'] as List?)?.cast<String>() ?? [];
    final recs = (overload?['recommendations'] as List?)?.cast<String>() ?? [];

    // FIX 1.4 — exerciseCount et effectiveWeightUsed maintenant garantis par Java
    final exerciseCount = fatigue?['exerciseCount'] ?? 0;
    final muscleRiskSource = fatigue?['muscleRiskSource'] ?? '';
    final effectiveWeight =
        (fatigue?['effectiveWeightUsed'] as num?)?.toDouble() ?? 0.0;

    // FIX 1.3 — remainingRestDays maintenant retourné par /api/ai/predict
    final remainingRestDays =
        (prediction['remainingRestDays'] as num?)?.toInt() ?? 0;
    final restMessage = prediction['restMessage'] as String? ?? '';

    final riskColor = _getRiskColor(displayRiskLevel);

    // FIX 3.4 — avertissement si modèle blessure indisponible
    final injuryUnavailable =
        (injury?['riskLevel'] ?? injury?['risk_level']) == 'NON_DISPONIBLE';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurf2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(exerciseCount),
          if (effectiveWeight > 0)
            _buildEffectiveWeightInfo(effectiveWeight, muscleRiskSource),
          const SizedBox(height: 14),
          _buildFatigueInjuryRow(fatigueLbl, injuryLbl, fatigue, injury),

          // FIX 3.4 — bannière si modèle blessure indisponible (scaler manquant)
          if (injuryUnavailable) ...[
            const SizedBox(height: 8),
            _buildUnavailableBanner(),
          ],

          const SizedBox(height: 10),
          ProgressionCard(overload: overload ?? {}),

          // FIX 1.3 — remainingRestDays calculé côté Java maintenant
          if (remainingRestDays > 0)
            RestRecommendationCard(days: remainingRestDays),

          if (remainingRestDays == 0 && restMessage.isNotEmpty)
            _buildRecoveryCompleteCard(restMessage),

          const SizedBox(height: 10),
          _buildOverloadCard(displayRiskLevel, riskColor, overload),
          if (warnings.isNotEmpty) _buildWarningsList(warnings),
          if (recs.isNotEmpty) _buildRecommendationsList(recs),

          // ✅ FIX #5 : Bouton navigation interne au lieu d'URL API
          if (prediction['recoveryAvailable'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigation interne vers l'écran de récupération musculaire
                  Navigator.pushNamed(
                    context,
                    '/muscle-recovery',
                    arguments: {'memberId': prediction['memberId']},
                  );
                },
                icon: const Icon(Icons.fitness_center_rounded, size: 18),
                label: const Text('Voir la récupération musculaire détaillée'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(int exerciseCount) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _kGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: _kGreen, size: 11),
              SizedBox(width: 4),
              Text(
                'ANALYSE IA',
                style: TextStyle(
                  color: _kGreen,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        if (exerciseCount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.list_alt_rounded, color: _kBlue, size: 11),
                const SizedBox(width: 4),
                Text(
                  '$exerciseCount EXERCICES RÉELS',
                  style: const TextStyle(
                    color: _kBlue,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEffectiveWeightInfo(double weight, String source) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _kGreenL,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Charge effective analysée : ${weight}kg'
            '${source == 'EXERCICES_RÉELS' ? ' (données réelles)' : ''}',
            style: const TextStyle(
              color: _kGreenDark,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFatigueInjuryRow(
    String fatigueLbl,
    String injuryLbl,
    dynamic fatigue,
    dynamic injury,
  ) {
    // FIX 1.2 — lire confidence depuis injury (présente dans les deux sources)
    final injuryConf = (injury?['confidence'] as num?)?.toDouble() ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _PredCard(
            icon: Icons.battery_alert_rounded,
            label: 'Fatigue',
            value: fatigueLbl,
            confidence: (fatigue?['confidence'] as num?)?.toDouble() ?? 0,
            isWarning: fatigueLbl.toLowerCase().contains('fatigué'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PredCard(
            icon: Icons.healing_rounded,
            label: 'Blessure',
            value: injuryLbl,
            confidence: injuryConf,
            isWarning: injuryLbl.toLowerCase().contains('élevé'),
            isModerate: injuryLbl.toLowerCase().contains('modéré'),
            // FIX 3.4 — désactiver la barre si modèle indisponible
            isUnavailable: injuryLbl == 'non disponible',
          ),
        ),
      ],
    );
  }

  // FIX 3.4 — Bannière quand le scaler blessure est absent
  Widget _buildUnavailableBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _kOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kOrange.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _kOrange, size: 14),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Modèle blessure non calibré — analyse heuristique utilisée.',
              style: TextStyle(color: _kOrange, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverloadCard(
    String riskLevel,
    Color riskColor,
    dynamic overload,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics_rounded, color: riskColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Charge hebdomadaire',
                  style: TextStyle(color: _kTextSub, fontSize: 11),
                ),
                Text(
                  '${overload?['sessionCount'] ?? 0} séances • ${overload?['totalMinutes'] ?? 0} min',
                  style: const TextStyle(color: _kText, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              riskLevel,
              style: TextStyle(
                color: riskColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsList(List<String> warnings) {
    return Column(
      children: [
        const SizedBox(height: 10),
        ...warnings
            .take(3)
            .map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, color: _kRed, size: 6),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        w,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildRecommendationsList(List<String> recs) {
    return Column(
      children: [
        const SizedBox(height: 8),
        ...recs
            .take(2)
            .map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_rounded,
                      color: _kGreen,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        r,
                        style: const TextStyle(color: _kTextSub, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildRecoveryCompleteCard(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: _kGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _kGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'CRITIQUE':
        return _kRed;
      case 'ÉLEVÉ':
        return _kOrange;
      case 'MODÉRÉ':
        return const Color(0xFFFFD740);
      default:
        return _kGreen;
    }
  }
}

// ════════════════════════════════════════════════════════════
// _PredCard — FIX 3.4 : isUnavailable pour état scaler absent
// ════════════════════════════════════════════════════════════
class _PredCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final double confidence;
  final bool isWarning;
  final bool isModerate;
  final bool isUnavailable;

  const _PredCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.confidence,
    required this.isWarning,
    this.isModerate = false,
    this.isUnavailable = false,
  });

  @override
  Widget build(BuildContext context) {
    // FIX 3.4 : couleur grise si modèle indisponible
    Color color;
    if (isUnavailable) {
      color = _kTextSub;
    } else if (isWarning) {
      color = _kRed;
    } else if (isModerate) {
      color = _kOrange;
    } else {
      color = _kGreen;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(color: _kTextSub, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isUnavailable ? 'N/A' : value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          if (!isUnavailable) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: confidence,
                backgroundColor: _kBorder,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${(confidence * 100).toStringAsFixed(0)}% confiance',
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 9,
              ),
            ),
          ] else
            Text(
              'Modèle en cours de calibrage',
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 9,
              ),
            ),
        ],
      ),
    );
  }
}
