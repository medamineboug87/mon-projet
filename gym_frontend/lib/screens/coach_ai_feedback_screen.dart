// lib/screens/coach_ai_feedback_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/coach_ai_feedback_service.dart';
import '../providers/auth_provider.dart';

// ─── Design tokens ───
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

class CoachAIFeedbackScreen extends ConsumerStatefulWidget {
  final int coachId;

  const CoachAIFeedbackScreen({super.key, required this.coachId});

  @override
  ConsumerState<CoachAIFeedbackScreen> createState() =>
      _CoachAIFeedbackScreenState();
}

class _CoachAIFeedbackScreenState extends ConsumerState<CoachAIFeedbackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _globalStats;
  List<Map<String, dynamic>> _memberStats = [];
  Map<int, List<Map<String, dynamic>>> _memberFeedbacks = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger les statistiques globales
      final stats = await CoachAIFeedbackService.getGlobalAccuracyStats();
      // Charger les statistiques par membre
      final memberStats =
          await CoachAIFeedbackService.getMembersAccuracyStats();
      // Charger les feedbacks récents par membre
      final feedbacks =
          await CoachAIFeedbackService.getRecentFeedbacksByMember();

      if (mounted) {
        setState(() {
          _globalStats = stats;
          _memberStats = memberStats;
          _memberFeedbacks = feedbacks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Évaluations IA',
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
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: _kGreen,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kGreen))
            : _errorMessage != null
            ? _buildErrorWidget()
            : Column(
                children: [
                  _buildGlobalStatsCard(),
                  const SizedBox(height: 12),
                  Container(
                    color: _kSurface,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: _kGreen,
                      labelColor: _kGreen,
                      unselectedLabelColor: _kTextSub,
                      tabs: const [
                        Tab(text: 'Par membre'),
                        Tab(text: 'Corrections récentes'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMembersList(),
                        _buildRecentCorrectionsList(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 60, color: _kRed),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Erreur de chargement',
            style: const TextStyle(color: _kTextSub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalStatsCard() {
    if (_globalStats == null) return const SizedBox.shrink();

    final fatigueAccuracy = _globalStats!['fatigueAccuracyValue'] ?? 0.0;
    final injuryAccuracy = _globalStats!['injuryAccuracyValue'] ?? 0.0;
    final avgRating = _globalStats!['averageRating'] ?? 0.0;
    final pendingFeedbacks = _globalStats!['pendingRetrainingFeedbacks'] ?? 0;
    final qualityLabel = _globalStats!['qualityLabel'] ?? '';

    Color qualityColor = _kGreen;
    if (qualityLabel.contains('Améliorer')) qualityColor = _kOrange;
    if (qualityLabel.contains('Insuffisant')) qualityColor = _kRed;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: _kGreen, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Précision des prédictions IA',
                style: TextStyle(
                  color: _kText,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: qualityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: qualityColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  qualityLabel,
                  style: TextStyle(
                    color: qualityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  label: 'Fatigue',
                  value: '${fatigueAccuracy.toStringAsFixed(0)}%',
                  color: fatigueAccuracy >= 70 ? _kGreen : _kOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatChip(
                  label: 'Blessure',
                  value: '${injuryAccuracy.toStringAsFixed(0)}%',
                  color: injuryAccuracy >= 70 ? _kGreen : _kOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatChip(
                  label: 'Note coach',
                  value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '—',
                  color: _kBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pendingFeedbacks > 0)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kGreenL,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology_rounded,
                    color: _kGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$pendingFeedbacks feedbacks prêts pour le réentraînement',
                      style: const TextStyle(
                        color: _kGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (pendingFeedbacks >= 10)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _kGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Prêt',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _kTextSub, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    if (_memberStats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline_rounded, size: 48, color: _kBorder),
            const SizedBox(height: 12),
            const Text(
              'Aucun feedback IA enregistré',
              style: TextStyle(color: _kTextSub),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _memberStats.length,
      itemBuilder: (context, index) {
        final member = _memberStats[index];
        final memberId = member['memberId'];
        final memberName = member['memberName'] ?? 'Membre #$memberId';
        final fatigueAcc = member['fatigue']['accuracyValue'] ?? 0.0;
        final injuryAcc = member['injury']['accuracyValue'] ?? 0.0;
        final avgRating = member['averageRating'] ?? 0.0;
        final correctionsCount = member['correctionsCount'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: ExpansionTile(
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kGreenL,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: _kGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memberName,
                        style: const TextStyle(
                          color: _kText,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (correctionsCount > 0)
                        Text(
                          '$correctionsCount correction${correctionsCount > 1 ? 's' : ''}',
                          style: const TextStyle(color: _kOrange, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                _buildMiniStat(
                  'F',
                  fatigueAcc,
                  fatigueAcc >= 70 ? _kGreen : _kOrange,
                ),
                const SizedBox(width: 8),
                _buildMiniStat(
                  'B',
                  injuryAcc,
                  injuryAcc >= 70 ? _kGreen : _kOrange,
                ),
                if (avgRating > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _kBlueL,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: _kBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            childrenPadding: const EdgeInsets.all(12),
            children: [
              const Divider(color: _kBorder, height: 1),
              const SizedBox(height: 8),
              if (_memberFeedbacks.containsKey(memberId))
                ..._memberFeedbacks[memberId]!
                    .take(5)
                    .map((fb) => _buildFeedbackItem(fb, memberName)),
              if (_memberFeedbacks.containsKey(memberId) &&
                  _memberFeedbacks[memberId]!.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+ ${_memberFeedbacks[memberId]!.length - 5} autres corrections',
                    style: const TextStyle(color: _kTextSub, fontSize: 11),
                  ),
                ),
              if (!_memberFeedbacks.containsKey(memberId))
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Aucun feedback détaillé',
                    style: TextStyle(color: _kTextSub, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, double value, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(label, style: const TextStyle(color: _kTextSub, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(Map<String, dynamic> feedback, String memberName) {
    final createdAt = feedback['createdAt'] != null
        ? DateTime.tryParse(feedback['createdAt']?.toString() ?? '')
        : null;
    final fatigueCorrect = feedback['fatiguePredictionCorrect'];
    final injuryCorrect = feedback['injuryPredictionCorrect'];
    final rating = feedback['coachRating'];
    final comment = feedback['coachComment'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kSurf2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: fatigueCorrect == true && injuryCorrect == true
                      ? _kGreen
                      : _kOrange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  createdAt != null
                      ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}'
                      : 'Date inconnue',
                  style: const TextStyle(color: _kTextSub, fontSize: 11),
                ),
              ),
              if (rating != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _kOrangeL,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '⭐ $rating/5',
                    style: const TextStyle(
                      color: _kOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildCorrectChip('Fatigue', fatigueCorrect),
              const SizedBox(width: 8),
              _buildCorrectChip('Blessure', injuryCorrect),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style: const TextStyle(
                color: _kTextSub,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCorrectChip(String label, bool? isCorrect) {
    if (isCorrect == null) return const SizedBox.shrink();

    final isOk = isCorrect == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isOk ? _kGreen : _kRed).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isOk ? _kGreen : _kRed).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOk ? Icons.check_circle_rounded : Icons.error_rounded,
            size: 12,
            color: isOk ? _kGreen : _kRed,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isOk ? _kGreen : _kRed,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCorrectionsList() {
    // Collecter tous les feedbacks de tous les membres
    final allFeedbacks = <Map<String, dynamic>>[];
    for (final entry in _memberFeedbacks.entries) {
      allFeedbacks.addAll(entry.value);
    }
    allFeedbacks.sort((a, b) {
      final dateA = a['createdAt'] != null
          ? DateTime.tryParse(a['createdAt'].toString())
          : null;
      final dateB = b['createdAt'] != null
          ? DateTime.tryParse(b['createdAt'].toString())
          : null;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    if (allFeedbacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_rounded, size: 48, color: _kBorder),
            const SizedBox(height: 12),
            const Text(
              'Aucune correction enregistrée',
              style: TextStyle(color: _kTextSub),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: allFeedbacks.length,
      itemBuilder: (context, index) {
        final fb = allFeedbacks[index];
        final memberName = fb['memberName'] ?? 'Membre #${fb['memberId']}';
        final createdAt = fb['createdAt'] != null
            ? DateTime.tryParse(fb['createdAt'].toString())
            : null;
        final fatigueCorrect = fb['fatiguePredictionCorrect'];
        final injuryCorrect = fb['injuryPredictionCorrect'];
        final rating = fb['coachRating'];
        final comment = fb['coachComment'];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _kGreenL,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: _kGreen,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memberName,
                          style: const TextStyle(
                            color: _kText,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (createdAt != null)
                          Text(
                            '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                            style: const TextStyle(
                              color: _kTextSub,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _kOrangeL,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '⭐ $rating/5',
                        style: const TextStyle(
                          color: _kOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildCorrectChip('Fatigue', fatigueCorrect),
                  const SizedBox(width: 8),
                  _buildCorrectChip('Blessure', injuryCorrect),
                ],
              ),
              if (comment != null && comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kSurf2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    comment,
                    style: const TextStyle(color: _kTextSub, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
