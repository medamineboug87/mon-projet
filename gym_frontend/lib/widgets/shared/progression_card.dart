import 'package:flutter/material.dart';

const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kBlue = Color(0xFF1976D2);
const Color _kOrange = Color(0xFFF57C00);
const Color _kRed = Color(0xFFE53935);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class ProgressionCard extends StatelessWidget {
  final Map<String, dynamic> overload;

  const ProgressionCard({super.key, required this.overload});

  @override
  Widget build(BuildContext context) {
    final exerciseProgressions = overload['exerciseProgressions'] as Map<String, dynamic>?;
    final progressions = (exerciseProgressions?['progressions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final alerts = (exerciseProgressions?['alerts'] as List?)?.cast<String>() ?? [];
    final hasRapidProgression = exerciseProgressions?['hasRapidProgression'] ?? false;
    final totalExercisesTracked = exerciseProgressions?['totalExercisesTracked'] ?? 0;
    final weightProgressionPercent = (overload['weightProgressionPercent'] as num?)?.toDouble();

    if (progressions.isEmpty && weightProgressionPercent == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: _kSurf2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasRapidProgression ? _kRed.withValues(alpha: 0.3) : _kGreen.withValues(alpha: 0.2), width: hasRapidProgression ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(hasRapidProgression, weightProgressionPercent, totalExercisesTracked),
          if (alerts.isNotEmpty) _buildAlertsSection(alerts),
          if (progressions.isNotEmpty) _buildProgressionsList(progressions),
          if (exerciseProgressions?['note'] != null) _buildNoteSection(exerciseProgressions!['note']),
        ],
      ),
    );
  }

  Widget _buildHeader(bool hasRapidProgression, double? weightProgressionPercent, int totalExercisesTracked) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: hasRapidProgression ? _kRed.withValues(alpha: 0.08) : _kGreen.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up_rounded, color: hasRapidProgression ? _kRed : _kGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PROGRESSION DES CHARGES', style: TextStyle(color: _kTextSub, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                Text(
                  weightProgressionPercent != null
                      ? 'Progression moyenne : ${weightProgressionPercent > 0 ? "+" : ""}${weightProgressionPercent.toStringAsFixed(1)}%'
                      : 'Analyse par exercice',
                  style: TextStyle(color: hasRapidProgression ? _kRed : _kGreen, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (totalExercisesTracked > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Text('$totalExercisesTracked exos', style: const TextStyle(color: _kGreen, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(List<String> alerts) {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Divider(color: _kBorder, height: 1)),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Icon(Icons.warning_amber_rounded, color: _kRed, size: 14), const SizedBox(width: 6), Text('${alerts.length} alerte${alerts.length > 1 ? 's' : ''}', style: const TextStyle(color: _kRed, fontSize: 11, fontWeight: FontWeight.w700))]),
              const SizedBox(height: 8),
              ...alerts.take(3).map((alert) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.trip_origin_rounded, color: _kRed, size: 8),
                    const SizedBox(width: 8),
                    Expanded(child: Text(alert, style: const TextStyle(color: Colors.black54, fontSize: 11))),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressionsList(List<Map<String, dynamic>> progressions) {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Divider(color: _kBorder, height: 1)),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Détail par exercice', style: TextStyle(color: _kTextSub, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ...progressions.map((progression) => _ProgressionItem(progression: progression)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteSection(String note) {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Divider(color: _kBorder, height: 1)),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _kBlue, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(note, style: const TextStyle(color: _kTextSub, fontSize: 11))),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressionItem extends StatelessWidget {
  final Map<String, dynamic> progression;

  const _ProgressionItem({required this.progression});

  @override
  Widget build(BuildContext context) {
    final exerciseName = progression['exerciseName'] ?? 'Exercice';
    final muscleName = progression['muscleName'] ?? '';
    final currentWeight = (progression['currentWeight'] as num?)?.toDouble() ?? 0.0;
    final previousAvg = (progression['previousAvg'] as num?)?.toDouble();
    final progressionPct = (progression['progressionPct'] as num?)?.toDouble();
    final status = progression['status'] ?? 'NEW';
    final safeThreshold = (progression['safeThreshold'] as num?)?.toDouble() ?? 10.0;
    final isNewPR = progression['isNewPersonalRecord'] ?? false;
    final allTimeMax = (progression['allTimeMax'] as num?)?.toDouble();
    final rpe = progression['rpe'];
    final failureReached = progression['failureReached'] ?? false;

    final (statusColor, statusIcon, statusLabel) = _getStatusStyle(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: status == 'CRITICAL' ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 28, height: 28, decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(statusIcon, color: statusColor, size: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exerciseName, style: const TextStyle(color: _kText, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (muscleName.isNotEmpty) Text(muscleName, style: const TextStyle(color: _kTextSub, fontSize: 10)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (progressionPct != null && status != 'NEW') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progression : ${progressionPct > 0 ? "+" : ""}${progressionPct.toStringAsFixed(1)}%', style: TextStyle(color: progressionPct > safeThreshold ? _kRed : progressionPct > 0 ? _kGreen : _kTextSub, fontWeight: FontWeight.w700, fontSize: 12)),
                Text('Seuil sûr : +${safeThreshold.toStringAsFixed(0)}%', style: const TextStyle(color: _kTextSub, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressionPct > 0 ? (progressionPct / (safeThreshold * 2)).clamp(0.0, 1.0) : 0.0,
              backgroundColor: _kBorder,
              color: progressionPct > safeThreshold ? _kRed : _kGreen,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 8),
          ],
          if (previousAvg != null && status != 'NEW') ...[
            Row(
              children: [
                Expanded(child: _ProgressionStat(label: 'Charge actuelle', value: '${currentWeight.toStringAsFixed(1)} kg', color: _kGreen)),
                Expanded(child: _ProgressionStat(label: 'Moyenne précédente', value: '${previousAvg.toStringAsFixed(1)} kg', color: _kBlue)),
              ],
            ),
          ] else if (status == 'NEW') ...[
            _ProgressionStat(label: 'Charge actuelle', value: '${currentWeight.toStringAsFixed(1)} kg', color: _kGreen),
          ],
          if (isNewPR || failureReached || (rpe != null && rpe >= 9)) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (isNewPR) _buildBadge(Icons.emoji_events_rounded, 'Record : ${allTimeMax?.toStringAsFixed(1) ?? currentWeight.toStringAsFixed(1)} kg', _kBlue),
                if (failureReached) _buildBadge(Icons.warning_amber_rounded, 'Échec musculaire', _kRed),
                if (rpe != null && rpe >= 9) _buildBadge(Icons.speed_rounded, 'RPE $rpe/10', _kOrange),
              ],
            ),
          ],
        ],
      ),
    );
  }

  (Color, IconData, String) _getStatusStyle(String status) {
    switch (status) {
      case 'CRITICAL': return (_kRed, Icons.error_rounded, 'Progression critique');
      case 'WARNING': return (_kOrange, Icons.warning_rounded, 'Progression rapide');
      case 'OK': return (_kGreen, Icons.check_circle_rounded, 'Progression OK');
      case 'DOWN': return (_kBlue, Icons.trending_down_rounded, 'Charge réduite');
      default: return (_kTextSub, Icons.add_circle_outline_rounded, 'Nouvel exercice');
    }
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color == _kBlue ? const Color(0xFFE3F2FD) : color == _kRed ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProgressionStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProgressionStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _kTextSub, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    );
  }
}