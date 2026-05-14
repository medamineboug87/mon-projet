import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../providers/coach_provider.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';

// ─── Design tokens light ───
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

// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════

class MemberDetailsScreen extends ConsumerWidget {
  final int memberId;
  final String memberName;

  const MemberDetailsScreen({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(memberSessionsForCoachProvider(memberId));

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _kGreenL,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  memberName
                      .trim()
                      .split(' ')
                      .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
                      .take(2)
                      .join(),
                  style: const TextStyle(
                    color: _kGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                memberName,
                style: const TextStyle(
                  color: _kText,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: _kSurface,
        iconTheme: const IconThemeData(color: _kText),
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: _kBorder),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kTextSub),
            onPressed: () =>
                ref.invalidate(memberSessionsForCoachProvider(memberId)),
          ),
        ],
      ),
      body: sessionsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kGreen)),
        error: (error, stack) => _buildErrorScreen(error),
        data: (sessions) {
          if (sessions.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(memberSessionsForCoachProvider(memberId)),
            color: _kGreen,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[sessions.length - 1 - index];
                return _SessionCard(
                  session: session,
                  memberId: memberId,
                  memberName: memberName,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _kSurf2,
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
            style: TextStyle(color: _kTextSub, fontSize: 14),
          ),
        ],
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _kRedL,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: _kRed,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Impossible de charger les séances',
              style: TextStyle(
                color: _kText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: _kTextSub, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SESSION CARD — avec bouton "Évaluer la prédiction IA"
// ══════════════════════════════════════════════════════════════

class _SessionCard extends StatefulWidget {
  final Map<String, dynamic> session;
  final int memberId;
  final String memberName;

  const _SessionCard({
    required this.session,
    required this.memberId,
    required this.memberName,
  });

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _isExpanded = false;
  Map<String, dynamic>? _prediction;
  bool _loadingPrediction = false;
  bool _hasFeedback = false;

  Future<void> _loadPrediction() async {
    if (_prediction != null) return;
    setState(() => _loadingPrediction = true);
    try {
      final token = await AuthService.getToken();
      final sessionId = widget.session['id'];
      final memberId = widget.memberId;

      // Charger la prédiction
      final predResponse = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/ai/predict/$memberId/$sessionId',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      // Vérifier si feedback déjà soumis
      final fbResponse = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/ai/feedback/session/$sessionId',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          if (predResponse.statusCode == 200) {
            _prediction = jsonDecode(predResponse.body);
          }
          _hasFeedback = fbResponse.statusCode == 200;
          _loadingPrediction = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPrediction = false);
    }
  }

  void _openFeedbackForm() {
    final sessionId = widget.session['id'] as int;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AIFeedbackFormSheet(
        memberId: widget.memberId,
        sessionId: sessionId,
        memberName: widget.memberName,
        prediction: _prediction,
        onSubmitted: () {
          setState(() => _hasFeedback = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Évaluation soumise avec succès !',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              backgroundColor: _kGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final hasCardio = session['hasCardio'] == true;
    final painLevel = session['painLevel'] as int? ?? 0;
    final warmupDone = session['warmupDone'] as bool? ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        children: [
          // ── Header de la séance ──
          InkWell(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
              if (_isExpanded) _loadPrediction();
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _kGreenL,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _kGreen.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: _kGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 3),
                        Text(
                          '${session['duration']} min • ${session['weightLifted']} kg',
                          style: const TextStyle(
                            color: _kTextSub,
                            fontSize: 12,
                          ),
                        ),
                        if (session['targetMuscles'] != null &&
                            session['targetMuscles'].toString().isNotEmpty)
                          Text(
                            session['targetMuscles'],
                            style: const TextStyle(
                              color: _kTextSub,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_hasFeedback)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _kGreenL,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _kGreen.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: _kGreen,
                                size: 11,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Évalué',
                                style: TextStyle(
                                  color: _kGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Icon(
                        _isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: _kTextSub,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Détails expandables ──
          if (_isExpanded) ...[
            const Divider(height: 1, color: _kBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Infos supplémentaires
                  _buildInfoRow(
                    'Intensité',
                    '${session['intensity'] ?? 'N/A'}/10',
                  ),
                  if (hasCardio) ...[
                    _buildInfoRow(
                      'Cardio',
                      '${session['cardioDurationMinutes'] ?? 0} min • ${session['cardioType'] ?? ''}',
                    ),
                  ],
                  if (painLevel > 0)
                    _buildInfoRow(
                      'Douleur signalée',
                      '$painLevel/10',
                      color: painLevel >= 7
                          ? _kRed
                          : painLevel >= 4
                          ? _kOrange
                          : _kGreen,
                    ),
                  _buildInfoRow(
                    'Échauffement',
                    warmupDone ? 'Oui ✅' : 'Non ⚠️',
                    color: warmupDone ? _kGreen : _kOrange,
                  ),

                  const SizedBox(height: 12),

                  // Prédiction IA
                  if (_loadingPrediction)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(
                          color: _kGreen,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else if (_prediction != null)
                    _PredictionSummaryCard(prediction: _prediction!)
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _kSurf2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            color: _kTextSub,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Prédiction IA indisponible',
                            style: TextStyle(color: _kTextSub, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 14),

                  // Bouton Évaluer
                  SizedBox(
                    width: double.infinity,
                    child: _hasFeedback
                        ? OutlinedButton.icon(
                            onPressed: _openFeedbackForm,
                            icon: const Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: _kTextSub,
                            ),
                            label: const Text(
                              'Modifier l\'évaluation',
                              style: TextStyle(color: _kTextSub),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _kBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _openFeedbackForm,
                            icon: const Icon(
                              Icons.rate_review_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Évaluer la prédiction IA',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 0,
                            ),
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

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: _kTextSub, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? _kText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PREDICTION SUMMARY CARD
// ══════════════════════════════════════════════════════════════

class _PredictionSummaryCard extends StatelessWidget {
  final Map<String, dynamic> prediction;
  const _PredictionSummaryCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final fatigue = prediction['fatigue'] as Map<String, dynamic>?;
    final injury = prediction['injury'] as Map<String, dynamic>?;
    final overload = prediction['overload'] as Map<String, dynamic>?;

    final fatigueLbl = fatigue?['label']?.toString() ?? 'N/A';
    final injuryLbl = injury?['label']?.toString() ?? 'N/A';
    final riskLevel = overload?['riskLevel']?.toString() ?? 'NORMAL';
    final fatigueConf = (fatigue?['confidence'] as num?)?.toDouble() ?? 0.0;
    final injuryConf = (injury?['confidence'] as num?)?.toDouble() ?? 0.0;

    final isFatigued = fatigueLbl.toLowerCase().contains('fatigué');
    final isHighRisk = injuryLbl.toLowerCase().contains('élevé');

    Color riskColor = switch (riskLevel) {
      'CRITIQUE' => _kRed,
      'ÉLEVÉ' => _kOrange,
      'MODÉRÉ' => const Color(0xFFF9A825),
      _ => _kGreen,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurf2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: _kGreen, size: 13),
              const SizedBox(width: 5),
              const Text(
                'PRÉDICTION IA',
                style: TextStyle(
                  color: _kGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: riskColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  riskLevel,
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniPredBar(
                  label: 'Fatigue',
                  value: fatigueConf,
                  text: fatigueLbl,
                  warn: isFatigued,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniPredBar(
                  label: 'Blessure',
                  value: injuryConf,
                  text: injuryLbl,
                  warn: isHighRisk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPredBar extends StatelessWidget {
  final String label;
  final double value;
  final String text;
  final bool warn;
  const _MiniPredBar({
    required this.label,
    required this.value,
    required this.text,
    required this.warn,
  });

  @override
  Widget build(BuildContext context) {
    final color = warn ? _kRed : _kGreen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _kTextSub, fontSize: 10)),
        const SizedBox(height: 3),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: _kBorder,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${(value * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// AI FEEDBACK FORM — Bottom Sheet (CORRIGÉ)
// ══════════════════════════════════════════════════════════════

class AIFeedbackFormSheet extends StatefulWidget {
  final int memberId;
  final int sessionId;
  final String memberName;
  final Map<String, dynamic>? prediction;
  final VoidCallback onSubmitted;

  const AIFeedbackFormSheet({
    super.key,
    required this.memberId,
    required this.sessionId,
    required this.memberName,
    required this.prediction,
    required this.onSubmitted,
  });

  @override
  State<AIFeedbackFormSheet> createState() => _AIFeedbackFormSheetState();
}

class _AIFeedbackFormSheetState extends State<AIFeedbackFormSheet> {
  // ═══════════════════════════════════════════════════════════════
  // ✅ 1. Validation des prédictions (boutons Correct/Incorrect)
  // ═══════════════════════════════════════════════════════════════
  bool? _fatiguePredictionCorrect;
  bool? _injuryPredictionCorrect;
  bool? _overloadPredictionCorrect;

  // ═══════════════════════════════════════════════════════════════
  // ✅ 2. Corrections (valeurs ENUM, pas de texte libre)
  // ═══════════════════════════════════════════════════════════════
  String? _correctedFatigueLabel; // "normal" ou "fatigué" UNIQUEMENT
  String? _correctedInjuryLabel; // "risque faible" ou "risque élevé" UNIQUEMENT
  String? _correctedOverloadLevel; // "NORMAL","MODÉRÉ","ÉLEVÉ","CRITIQUE"

  // ═══════════════════════════════════════════════════════════════
  // ✅ 3. Note globale (1-5 étoiles)
  // ═══════════════════════════════════════════════════════════════
  int _coachRating = 0;

  // ═══════════════════════════════════════════════════════════════
  // ✅ 4. Observations physiques
  // ═══════════════════════════════════════════════════════════════
  int _observedFatigueLevel = 0;
  bool _injurySignsObserved = false;
  final _injuryDetailCtrl = TextEditingController();

  // ═══════════════════════════════════════════════════════════════
  // 📝 5. Commentaire libre (stocké mais PAS envoyé au modèle)
  // ═══════════════════════════════════════════════════════════════
  final _commentCtrl = TextEditingController();

  bool _isSubmitting = false;

  // Raccourcis vers les prédictions originales
  String get _originalFatigueLabel =>
      widget.prediction?['fatigue']?['label']?.toString() ?? 'N/A';
  String get _originalInjuryLabel =>
      widget.prediction?['injury']?['label']?.toString() ?? 'N/A';
  String get _originalOverloadLevel =>
      widget.prediction?['overload']?['riskLevel']?.toString() ?? 'N/A';
  double get _originalFatigueConf =>
      (widget.prediction?['fatigue']?['confidence'] as num?)?.toDouble() ?? 0.0;
  double get _originalInjuryConf =>
      (widget.prediction?['injury']?['confidence'] as num?)?.toDouble() ?? 0.0;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _injuryDetailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Vérifier que la note est donnée
    if (_coachRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez donner une note (1-5 étoiles)'),
          backgroundColor: _kOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await AuthService.getToken();

      // ═══════════════════════════════════════════════════════════════
      // ⚠️ IMPORTANT: coachComment et injuryObservationDetail sont des
      //    textes libres qui sont STOCKÉS mais PAS utilisés par le modèle
      // ═══════════════════════════════════════════════════════════════
      final body = <String, dynamic>{
        // Prédictions originales (pour référence)
        'originalFatigueLabel': _originalFatigueLabel,
        'originalFatigueConfidence': _originalFatigueConf,
        'originalInjuryLabel': _originalInjuryLabel,
        'originalInjuryConfidence': _originalInjuryConf,
        'originalOverloadLevel': _originalOverloadLevel,

        // ✅ Corrections structurées (utilisées par le modèle)
        'fatiguePredictionCorrect': _fatiguePredictionCorrect,
        'injuryPredictionCorrect': _injuryPredictionCorrect,
        'overloadPredictionCorrect': _overloadPredictionCorrect,

        // ✅ Labels corrigés (valeurs ENUM limitées)
        'correctedFatigueLabel': _correctedFatigueLabel,
        'correctedInjuryLabel': _correctedInjuryLabel,
        'correctedOverloadLevel': _correctedOverloadLevel,

        // ✅ Note et observations structurées
        'coachRating': _coachRating,
        'observedFatigueLevel': _observedFatigueLevel,
        'injurySignsObserved': _injurySignsObserved,

        // 📝 Textes libres (stockés mais PAS pour le ML)
        'coachComment': _commentCtrl.text.trim(),
        'injuryObservationDetail': _injuryDetailCtrl.text.trim(),
      };

      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/ai/feedback/member/${widget.memberId}/session/${widget.sessionId}',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context);
        widget.onSubmitted();
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de la soumission'),
            backgroundColor: _kRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur réseau'),
            backgroundColor: _kRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _kBorder,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kGreenL,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.rate_review_rounded,
                    color: _kGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Évaluer la prédiction IA',
                        style: TextStyle(
                          color: _kText,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        widget.memberName,
                        style: const TextStyle(color: _kTextSub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: _kTextSub),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 20, color: _kBorder),
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Évaluation Fatigue ──
                  _buildSectionHeader(
                    'Prédiction Fatigue',
                    Icons.battery_alert_rounded,
                    _kOrange,
                  ),
                  const SizedBox(height: 8),
                  _buildOriginalPredictionChip(
                    _originalFatigueLabel,
                    _originalFatigueConf,
                    _originalFatigueLabel.toLowerCase().contains('fatigué'),
                  ),
                  const SizedBox(height: 10),
                  _buildValidationRow(
                    label: 'La prédiction est-elle correcte ?',
                    value: _fatiguePredictionCorrect,
                    onChanged: (v) => setState(() {
                      _fatiguePredictionCorrect = v;
                      if (v == true) _correctedFatigueLabel = null;
                    }),
                  ),
                  if (_fatiguePredictionCorrect == false) ...[
                    const SizedBox(height: 10),
                    // ✅ SEULEMENT 2 OPTIONS : "normal" ou "fatigué"
                    _buildCorrectionLabel(
                      'Correction fatigue :',
                      options: const ['normal', 'fatigué'],
                      selected: _correctedFatigueLabel,
                      onSelect: (v) =>
                          setState(() => _correctedFatigueLabel = v),
                      colors: {'normal': _kGreen, 'fatigué': _kOrange},
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── 2. Évaluation Blessure ──
                  _buildSectionHeader(
                    'Prédiction Blessure',
                    Icons.healing_rounded,
                    _kRed,
                  ),
                  const SizedBox(height: 8),
                  _buildOriginalPredictionChip(
                    _originalInjuryLabel,
                    _originalInjuryConf,
                    _originalInjuryLabel.toLowerCase().contains('élevé'),
                  ),
                  const SizedBox(height: 10),
                  _buildValidationRow(
                    label: 'La prédiction est-elle correcte ?',
                    value: _injuryPredictionCorrect,
                    onChanged: (v) => setState(() {
                      _injuryPredictionCorrect = v;
                      if (v == true) _correctedInjuryLabel = null;
                    }),
                  ),
                  if (_injuryPredictionCorrect == false) ...[
                    const SizedBox(height: 10),
                    // ✅ SEULEMENT 2 OPTIONS : "risque faible" ou "risque élevé"
                    _buildCorrectionLabel(
                      'Correction blessure :',
                      options: const ['risque faible', 'risque élevé'],
                      selected: _correctedInjuryLabel,
                      onSelect: (v) =>
                          setState(() => _correctedInjuryLabel = v),
                      colors: {'risque faible': _kGreen, 'risque élevé': _kRed},
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── 3. Évaluation Surcharge ──
                  _buildSectionHeader(
                    'Niveau de Surcharge',
                    Icons.analytics_rounded,
                    _kBlue,
                  ),
                  const SizedBox(height: 8),
                  _buildOverloadChip(_originalOverloadLevel),
                  const SizedBox(height: 10),
                  _buildValidationRow(
                    label: 'Le niveau est-il correct ?',
                    value: _overloadPredictionCorrect,
                    onChanged: (v) => setState(() {
                      _overloadPredictionCorrect = v;
                      if (v == true) _correctedOverloadLevel = null;
                    }),
                  ),
                  if (_overloadPredictionCorrect == false) ...[
                    const SizedBox(height: 10),
                    // ✅ SEULEMENT 4 OPTIONS : "NORMAL","MODÉRÉ","ÉLEVÉ","CRITIQUE"
                    _buildCorrectionLabel(
                      'Correction surcharge :',
                      options: const ['NORMAL', 'MODÉRÉ', 'ÉLEVÉ', 'CRITIQUE'],
                      selected: _correctedOverloadLevel,
                      onSelect: (v) =>
                          setState(() => _correctedOverloadLevel = v),
                      colors: {
                        'NORMAL': _kGreen,
                        'MODÉRÉ': const Color(0xFFF9A825),
                        'ÉLEVÉ': _kOrange,
                        'CRITIQUE': _kRed,
                      },
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── 4. Observations physiques ──
                  _buildSectionHeader(
                    'Observations Physiques',
                    Icons.visibility_rounded,
                    _kBlue,
                  ),
                  const SizedBox(height: 12),

                  // Fatigue observée (0-10)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Fatigue observée',
                        style: TextStyle(
                          color: _kTextSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _observedFatigueLevel == 0
                              ? _kSurf2
                              : (_observedFatigueLevel >= 7
                                    ? _kRedL
                                    : _observedFatigueLevel >= 4
                                    ? _kOrangeL
                                    : _kGreenL),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _observedFatigueLevel == 0
                                ? _kBorder
                                : (_observedFatigueLevel >= 7
                                      ? _kRed
                                      : _observedFatigueLevel >= 4
                                      ? _kOrange
                                      : _kGreen),
                          ),
                        ),
                        child: Text(
                          _observedFatigueLevel == 0
                              ? 'Non évalué'
                              : '$_observedFatigueLevel/10',
                          style: TextStyle(
                            color: _observedFatigueLevel == 0
                                ? _kTextSub
                                : (_observedFatigueLevel >= 7
                                      ? _kRed
                                      : _observedFatigueLevel >= 4
                                      ? _kOrange
                                      : _kGreen),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _observedFatigueLevel.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    activeColor: _observedFatigueLevel >= 7
                        ? _kRed
                        : _observedFatigueLevel >= 4
                        ? _kOrange
                        : _kGreen,
                    inactiveColor: _kBorder,
                    onChanged: (v) =>
                        setState(() => _observedFatigueLevel = v.round()),
                  ),
                  const SizedBox(height: 8),

                  // Signes de blessure
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kSurf2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _injurySignsObserved
                            ? _kRed.withValues(alpha: 0.3)
                            : _kBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Signes de blessure observés',
                                    style: TextStyle(
                                      color: _kText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _injurySignsObserved
                                        ? '⚠️ Oui — à documenter'
                                        : 'Aucun signe visible',
                                    style: TextStyle(
                                      color: _injurySignsObserved
                                          ? _kRed
                                          : _kTextSub,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _injurySignsObserved,
                              onChanged: (v) =>
                                  setState(() => _injurySignsObserved = v),
                              activeColor: _kRed,
                            ),
                          ],
                        ),
                        if (_injurySignsObserved) ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: _injuryDetailCtrl,
                            maxLines: 2,
                            style: const TextStyle(color: _kText, fontSize: 13),
                            decoration: InputDecoration(
                              hintText:
                                  'Décrire les signes observés (douleur, boiterie, etc.)',
                              hintStyle: const TextStyle(
                                color: _kTextSub,
                                fontSize: 12,
                              ),
                              filled: true,
                              fillColor: _kSurface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: _kRed,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 5. Note Globale (1-5 étoiles) ──
                  _buildSectionHeader(
                    'Note Globale',
                    Icons.star_rounded,
                    const Color(0xFFF9A825),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Qualité globale de la prédiction IA',
                    style: TextStyle(color: _kTextSub, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final starValue = i + 1;
                      return GestureDetector(
                        onTap: () => setState(() => _coachRating = starValue),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              starValue <= _coachRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: starValue <= _coachRating
                                  ? const Color(0xFFF9A825)
                                  : _kBorder,
                              size: 38,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_coachRating > 0) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        _ratingLabel(_coachRating),
                        style: const TextStyle(
                          color: Color(0xFFF9A825),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── 6. Commentaire (TEXTE LIBRE - stocké seulement) ──
                  _buildSectionHeader(
                    'Commentaire (optionnel)',
                    Icons.comment_rounded,
                    _kTextSub,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: _kText, fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'Observations supplémentaires, contexte particulier...',
                      hintStyle: const TextStyle(
                        color: _kTextSub,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: _kSurf2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: _kGreen,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Bouton Soumettre ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGreen,
                        disabledBackgroundColor: _kGreen.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Soumettre l\'évaluation',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WIDGETS HELPERS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
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
            color: _kText,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildOriginalPredictionChip(
    String label,
    double confidence,
    bool warn,
  ) {
    final color = warn ? _kOrange : _kGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Text(
            'IA prédit :',
            style: TextStyle(color: _kTextSub, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            '${(confidence * 100).toStringAsFixed(0)}% confiance',
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildOverloadChip(String level) {
    Color color = switch (level) {
      'CRITIQUE' => _kRed,
      'ÉLEVÉ' => _kOrange,
      'MODÉRÉ' => const Color(0xFFF9A825),
      _ => _kGreen,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Text(
            'IA détecte :',
            style: TextStyle(color: _kTextSub, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Text(
            'Surcharge $level',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Validation row avec boutons Correct/Incorrect
  Widget _buildValidationRow({
    required String label,
    required bool? value,
    required void Function(bool?) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _kTextSub, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        _ValidationChip(
          label: '✅ Correct',
          selected: value == true,
          color: _kGreen,
          onTap: () => onChanged(value == true ? null : true),
        ),
        const SizedBox(width: 6),
        _ValidationChip(
          label: '❌ Incorrect',
          selected: value == false,
          color: _kRed,
          onTap: () => onChanged(value == false ? null : false),
        ),
      ],
    );
  }

  // ✅ Correction label avec options LIMITÉES (pas de texte libre)
  Widget _buildCorrectionLabel(
    String title, {
    required List<String> options,
    required String? selected,
    required void Function(String) onSelect,
    required Map<String, Color> colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _kTextSub,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((opt) {
            final isSelected = selected == opt;
            final color = colors[opt] ?? _kGreen;
            return GestureDetector(
              onTap: () => onSelect(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : _kSurf2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color.withValues(alpha: 0.5) : _kBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    color: isSelected ? color : _kTextSub,
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.w800
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _ratingLabel(int rating) => switch (rating) {
    1 => 'Très mauvaise prédiction',
    2 => 'Mauvaise prédiction',
    3 => 'Prédiction acceptable',
    4 => 'Bonne prédiction',
    5 => 'Excellente prédiction !',
    _ => '',
  };
}

// ── Chip de validation ✅ / ❌ ──
class _ValidationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ValidationChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : _kSurf2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.4) : _kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : _kTextSub,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
