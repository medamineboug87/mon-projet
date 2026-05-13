import 'package:flutter/material.dart';
import 'exercise_entry_model.dart';

// ─── Design tokens ───
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kBlue = Color(0xFF1976D2);
const Color _kOrange = Color(0xFFF57C00);
const Color _kRed = Color(0xFFE53935);
const Color _kRedL = Color(0xFFFFEBEE);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class ExerciseCard extends StatelessWidget {
  final int index;
  final ExerciseEntry exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExerciseCard({
    super.key,
    required this.index,
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasHighLoad = exercise.weightKg >= 80;
    final hasFailure = exercise.failureReached;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: _kSurf2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasHighLoad || hasFailure
              ? _kOrange.withValues(alpha: 0.4)
              : _kBorder,
          width: hasHighLoad || hasFailure ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: _kGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName.isEmpty
                            ? 'Exercice ${index + 1}'
                            : exercise.exerciseName,
                        style: const TextStyle(
                          color: _kText,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (exercise.muscleName.isNotEmpty)
                        Text(
                          exercise.muscleName,
                          style: const TextStyle(
                            color: _kTextSub,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                if (exercise.weightKg > 0) ...[
                  _buildChargeBadge(),
                  const SizedBox(width: 6),
                ],
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: _kBlue, size: 18),
                  onPressed: onEdit,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: _kRed, size: 18),
                  onPressed: onDelete,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                _StatChip('${exercise.weightKg.toStringAsFixed(1)} kg', Icons.fitness_center_rounded, _kBlue),
                const SizedBox(width: 6),
                _StatChip('${exercise.setsCompleted} séries', Icons.repeat_rounded, _kGreen),
                const SizedBox(width: 6),
                _StatChip('${exercise.repsCompleted} reps', Icons.numbers_rounded, _kOrange),
                if (exercise.rpe != null) ...[
                  const SizedBox(width: 6),
                  _StatChip(
                    'RPE ${exercise.rpe}',
                    Icons.speed_rounded,
                    exercise.rpe! >= 9 ? _kRed : exercise.rpe! >= 7 ? _kOrange : _kGreen,
                  ),
                ],
                if (exercise.failureReached) ...[
                  const SizedBox(width: 6),
                  _failureBadge(),
                ],
              ],
            ),
          ),
          if (exercise.totalVolume > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart_rounded, size: 12, color: _kTextSub),
                  const SizedBox(width: 5),
                  Text(
                    'Volume total : ${exercise.totalVolume.toStringAsFixed(0)} kg',
                    style: const TextStyle(color: _kTextSub, fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChargeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: exercise.chargeLevelColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        exercise.chargeLevel,
        style: TextStyle(color: exercise.chargeLevelColor, fontSize: 9, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _failureBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _kRedL,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kRed.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: _kRed, size: 10),
          SizedBox(width: 3),
          Text('Échec', style: TextStyle(color: _kRed, fontSize: 9, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _StatChip(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}