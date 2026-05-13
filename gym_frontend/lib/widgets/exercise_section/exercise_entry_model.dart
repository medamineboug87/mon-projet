import 'package:flutter/material.dart';

// ─── Design tokens ───
const Color _kGreen = Color(0xFF00897B);
const Color _kBlue = Color(0xFF1976D2);
const Color _kOrange = Color(0xFFF57C00);
const Color _kRed = Color(0xFFE53935);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);

class ExerciseEntry {
  String exerciseName;
  String muscleName;
  double weightKg;
  int setsCompleted;
  String repsCompleted;
  int? rpe;
  bool failureReached;
  int restSeconds;
  String notes;

  ExerciseEntry({
    this.exerciseName = '',
    this.muscleName = '',
    this.weightKg = 0.0,
    this.setsCompleted = 3,
    this.repsCompleted = '10',
    this.rpe,
    this.failureReached = false,
    this.restSeconds = 90,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'exerciseName': exerciseName,
    'muscleName': muscleName,
    'weightKg': weightKg,
    'setsCompleted': setsCompleted,
    'repsCompleted': repsCompleted,
    'rpe': rpe,
    'failureReached': failureReached,
    'restSeconds': restSeconds,
    'notes': notes.isNotEmpty ? notes : null,
  };

  double get totalVolume =>
      weightKg *
      setsCompleted *
      (double.tryParse(repsCompleted.split(RegExp(r'[-,]'))[0]) ?? 10);

  String get chargeLevel {
    if (weightKg == 0) return 'N/A';
    if (weightKg < 20) return 'Légère';
    if (weightKg < 50) return 'Modérée';
    if (weightKg < 80) return 'Élevée';
    return 'Très élevée';
  }

  Color get chargeLevelColor {
    switch (chargeLevel) {
      case 'Légère': return _kGreen;
      case 'Modérée': return _kBlue;
      case 'Élevée': return _kOrange;
      case 'Très élevée': return _kRed;
      default: return _kTextSub;
    }
  }

  bool get isValid => exerciseName.trim().isNotEmpty;
}