// lib/screens/muscle_selector_screen.dart
// ✅ CORRIGÉ : version mobile-first

import 'package:flutter/material.dart';
import 'exercise_screen_updated.dart';

const Color _kSurface = Color(0xFFFFFFFF);
const Color _kGreen = Color(0xFF00897B);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class MuscleSelectorScreen extends StatefulWidget {
  const MuscleSelectorScreen({super.key});

  @override
  State<MuscleSelectorScreen> createState() => _MuscleSelectorScreenState();
}

class _MuscleSelectorScreenState extends State<MuscleSelectorScreen> {
  bool _showFront = true;
  final Set<String> _selectedMuscles = {};

  final Map<String, int> _lastWorkedHours = {
    'Pectoraux': 36,
    'Biceps': 52,
    'Biceps droit': 52,
    'Épaules': 18,
    'Abdominaux': 16,
    'Quadriceps': 72,
    'Quadriceps droit': 72,
    'Mollets': 30,
    'Mollets droits': 30,
    'Dorsaux': 50,
    'Triceps': 42,
    'Triceps droit': 42,
    'Trapèzes': 28,
    'Lombaires': 48,
    'Ischio-jambiers': 60,
    'Ischio-jambiers droits': 60,
    'Fessiers': 45,
  };

  final Map<String, MuscleInfo> _muscles = {
    'Pectoraux': MuscleInfo(
      color: _kGreen,
      frontPosition: const Rect.fromLTWH(120, 120, 110, 60),
      isFront: true,
      icon: Icons.fitness_center,
    ),
    'Biceps': MuscleInfo(
      color: _kGreen,
      frontPosition: const Rect.fromLTWH(70, 140, 45, 70),
      isFront: true,
      icon: Icons.fitness_center,
    ),
    'Biceps droit': MuscleInfo(
      color: _kGreen,
      frontPosition: const Rect.fromLTWH(235, 140, 45, 70),
      isFront: true,
      icon: Icons.fitness_center,
    ),
    'Épaules': MuscleInfo(
      color: _kGreen,
      frontPosition: const Rect.fromLTWH(85, 105, 180, 40),
      isFront: true,
      icon: Icons.fitness_center,
    ),
    'Abdominaux': MuscleInfo(
      color: _kGreen,
      frontPosition: const Rect.fromLTWH(135, 185, 80, 90),
      isFront: true,
      icon: Icons.fitness_center,
    ),
    'Quadriceps': MuscleInfo(
      color: _kGreen,
      frontPosition: const Rect.fromLTWH(120, 285, 50, 100),
      isFront: true,
      icon: Icons.fitness_center,
    ),
    'Quadriceps droit': MuscleInfo(
      color: _kGreen,
      frontPosition: const Rect.fromLTWH(180, 285, 50, 100),
      isFront: true,
      icon: Icons.fitness_center,
    ),
    'Mollets': MuscleInfo(
      color: _kGreen,
      frontPosition: const Rect.fromLTWH(120, 395, 50, 80),
      isFront: true,
      icon: Icons.fitness_center,
    ),
    'Mollets droits': MuscleInfo(
      color: _kGreen,
      frontPosition: const Rect.fromLTWH(180, 395, 50, 80),
      isFront: true,
      icon: Icons.fitness_center,
    ),
    'Dorsaux': MuscleInfo(
      color: _kGreen,
      frontPosition: const Rect.fromLTWH(110, 130, 130, 80),
      isFront: false,
      icon: Icons.fitness_center,
    ),
    'Triceps': MuscleInfo(
      color: _kGreen,
      frontPosition: const Rect.fromLTWH(65, 140, 40, 70),
      isFront: false,
      icon: Icons.fitness_center,
    ),
    'Triceps droit': MuscleInfo(
      color: _kGreen,
      frontPosition: const Rect.fromLTWH(245, 140, 40, 70),
      isFront: false,
      icon: Icons.fitness_center,
    ),
    'Trapèzes': MuscleInfo(
      color: _kGreen,
      frontPosition: const Rect.fromLTWH(120, 95, 110, 50),
      isFront: false,
      icon: Icons.fitness_center,
    ),
    'Lombaires': MuscleInfo(
      color: _kGreen,
      frontPosition: const Rect.fromLTWH(135, 215, 80, 60),
      isFront: false,
      icon: Icons.fitness_center,
    ),
    'Ischio-jambiers': MuscleInfo(
      color: _kGreen,
      frontPosition: const Rect.fromLTWH(120, 285, 50, 100),
      isFront: false,
      icon: Icons.fitness_center,
    ),
    'Ischio-jambiers droits': MuscleInfo(
      color: _kGreen,
      frontPosition: const Rect.fromLTWH(180, 285, 50, 100),
      isFront: false,
      icon: Icons.fitness_center,
    ),
    'Fessiers': MuscleInfo(
      color: _kGreen,
      frontPosition: const Rect.fromLTWH(120, 265, 110, 50),
      isFront: false,
      icon: Icons.fitness_center,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        title: const Text(
          'Choisir les muscles',
          style: TextStyle(color: _kText),
        ),
        backgroundColor: const Color(0xFFEEF1F8),
        iconTheme: const IconThemeData(color: _kText),
        actions: [
          if (_selectedMuscles.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context, _selectedMuscles.toList());
              },
              child: const Text(
                'Confirmer',
                style: TextStyle(
                  color: _kGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF1F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showFront = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _showFront ? _kGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Vue avant',
                          style: TextStyle(
                            color: _kText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showFront = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_showFront ? _kGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Vue arrière',
                          style: TextStyle(
                            color: _kText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_selectedMuscles.isNotEmpty)
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _selectedMuscles.map((muscle) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _kGreen,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Text(
                          muscle,
                          style: const TextStyle(
                            color: _kText,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selectedMuscles.remove(muscle)),
                          child: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.close,
                              color: _kText,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 8),

          Expanded(
            child: Stack(
              children: [
                Center(
                  child: _showFront ? _buildFrontBody() : _buildBackBody(),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _muscles.entries
                  .where((e) => e.value.isFront == _showFront)
                  .map((e) {
                    final isSelected = _selectedMuscles.contains(e.key);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedMuscles.remove(e.key);
                          } else {
                            _selectedMuscles.add(e.key);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? _kGreen : const Color(0xFFEEF1F8),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? _kGreen : _kBorder,
                          ),
                        ),
                        child: Text(
                          e.key,
                          style: TextStyle(
                            color: isSelected ? Colors.white : _kTextSub,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          ),

          if (_selectedMuscles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _selectedMuscles.toList());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Confirmer (${_selectedMuscles.length} muscle${_selectedMuscles.length > 1 ? 's' : ''})',
                    style: const TextStyle(
                      fontSize: 16,
                      color: _kText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFrontBody() {
    return CustomPaint(
      size: const Size(350, 500),
      painter: BodyPainter(showFront: true, selectedMuscles: _selectedMuscles),
      child: SizedBox(
        width: 350,
        height: 500,
        child: Stack(
          children: _muscles.entries.where((e) => e.value.isFront).map((e) {
            final isSelected = _selectedMuscles.contains(e.key);
            return Positioned(
              left: e.value.frontPosition.left,
              top: e.value.frontPosition.top,
              width: e.value.frontPosition.width,
              height: e.value.frontPosition.height,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedMuscles.remove(e.key);
                    } else {
                      _selectedMuscles.add(e.key);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kGreen.withValues(alpha: 0.5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: _kGreen, width: 2)
                        : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBackBody() {
    return CustomPaint(
      size: const Size(350, 500),
      painter: BodyPainter(showFront: false, selectedMuscles: _selectedMuscles),
      child: SizedBox(
        width: 350,
        height: 500,
        child: Stack(
          children: _muscles.entries.where((e) => !e.value.isFront).map((e) {
            final isSelected = _selectedMuscles.contains(e.key);
            return Positioned(
              left: e.value.frontPosition.left,
              top: e.value.frontPosition.top,
              width: e.value.frontPosition.width,
              height: e.value.frontPosition.height,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedMuscles.remove(e.key);
                    } else {
                      _selectedMuscles.add(e.key);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kGreen.withValues(alpha: 0.5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: _kGreen, width: 2)
                        : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class MuscleInfo {
  final Color color;
  final Rect frontPosition;
  final bool isFront;
  final IconData icon;

  MuscleInfo({
    required this.color,
    required this.frontPosition,
    required this.isFront,
    required this.icon,
  });
}

class BodyPainter extends CustomPainter {
  final bool showFront;
  final Set<String> selectedMuscles;

  BodyPainter({required this.showFront, required this.selectedMuscles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2C3E6B)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = const Color(0xFF4A6FA5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final selectedPaint = Paint()
      ..color = _kGreen.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Tête
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, 45),
        width: 60,
        height: 70,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, 45),
        width: 60,
        height: 70,
      ),
      outlinePaint,
    );

    // Cou
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 15, 75, 30, 25), paint);

    // Torse
    final torsePath = Path()
      ..moveTo(size.width / 2 - 70, 100)
      ..lineTo(size.width / 2 + 70, 100)
      ..lineTo(size.width / 2 + 55, 280)
      ..lineTo(size.width / 2 - 55, 280)
      ..close();
    canvas.drawPath(torsePath, paint);
    canvas.drawPath(torsePath, outlinePaint);

    // Épaules
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2 - 80, 115),
        width: 40,
        height: 30,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2 + 80, 115),
        width: 40,
        height: 30,
      ),
      paint,
    );

    // Bras gauche
    final leftArmPath = Path()
      ..moveTo(size.width / 2 - 70, 105)
      ..lineTo(size.width / 2 - 95, 110)
      ..lineTo(size.width / 2 - 100, 220)
      ..lineTo(size.width / 2 - 75, 220)
      ..close();
    canvas.drawPath(leftArmPath, paint);
    canvas.drawPath(leftArmPath, outlinePaint);

    // Avant-bras gauche
    final leftForearmPath = Path()
      ..moveTo(size.width / 2 - 100, 220)
      ..lineTo(size.width / 2 - 75, 220)
      ..lineTo(size.width / 2 - 78, 310)
      ..lineTo(size.width / 2 - 103, 310)
      ..close();
    canvas.drawPath(leftForearmPath, paint);
    canvas.drawPath(leftForearmPath, outlinePaint);

    // Bras droit
    final rightArmPath = Path()
      ..moveTo(size.width / 2 + 70, 105)
      ..lineTo(size.width / 2 + 95, 110)
      ..lineTo(size.width / 2 + 100, 220)
      ..lineTo(size.width / 2 + 75, 220)
      ..close();
    canvas.drawPath(rightArmPath, paint);
    canvas.drawPath(rightArmPath, outlinePaint);

    // Avant-bras droit
    final rightForearmPath = Path()
      ..moveTo(size.width / 2 + 100, 220)
      ..lineTo(size.width / 2 + 75, 220)
      ..lineTo(size.width / 2 + 78, 310)
      ..lineTo(size.width / 2 + 103, 310)
      ..close();
    canvas.drawPath(rightForearmPath, paint);
    canvas.drawPath(rightForearmPath, outlinePaint);

    // Bassin
    final pelvisPath = Path()
      ..moveTo(size.width / 2 - 55, 278)
      ..lineTo(size.width / 2 + 55, 278)
      ..lineTo(size.width / 2 + 60, 305)
      ..lineTo(size.width / 2 - 60, 305)
      ..close();
    canvas.drawPath(pelvisPath, paint);
    canvas.drawPath(pelvisPath, outlinePaint);

    // Cuisse gauche
    final leftThighPath = Path()
      ..moveTo(size.width / 2 - 55, 303)
      ..lineTo(size.width / 2 - 10, 303)
      ..lineTo(size.width / 2 - 15, 420)
      ..lineTo(size.width / 2 - 58, 420)
      ..close();
    canvas.drawPath(leftThighPath, paint);
    canvas.drawPath(leftThighPath, outlinePaint);

    // Cuisse droite
    final rightThighPath = Path()
      ..moveTo(size.width / 2 + 10, 303)
      ..lineTo(size.width / 2 + 55, 303)
      ..lineTo(size.width / 2 + 58, 420)
      ..lineTo(size.width / 2 + 15, 420)
      ..close();
    canvas.drawPath(rightThighPath, paint);
    canvas.drawPath(rightThighPath, outlinePaint);

    // Jambe gauche
    final leftLegPath = Path()
      ..moveTo(size.width / 2 - 58, 418)
      ..lineTo(size.width / 2 - 15, 418)
      ..lineTo(size.width / 2 - 18, 500)
      ..lineTo(size.width / 2 - 60, 500)
      ..close();
    canvas.drawPath(leftLegPath, paint);
    canvas.drawPath(leftLegPath, outlinePaint);

    // Jambe droite
    final rightLegPath = Path()
      ..moveTo(size.width / 2 + 15, 418)
      ..lineTo(size.width / 2 + 58, 418)
      ..lineTo(size.width / 2 + 60, 500)
      ..lineTo(size.width / 2 + 18, 500)
      ..close();
    canvas.drawPath(rightLegPath, paint);
    canvas.drawPath(rightLegPath, outlinePaint);

    if (showFront) {
      _paintFrontMuscles(canvas, size, selectedPaint, outlinePaint);
    } else {
      _paintBackMuscles(canvas, size, selectedPaint, outlinePaint);
    }

    if (showFront) {
      _paintFrontDetails(canvas, size, outlinePaint);
    } else {
      _paintBackDetails(canvas, size, outlinePaint);
    }
  }

  void _paintFrontMuscles(
    Canvas canvas,
    Size size,
    Paint selectedPaint,
    Paint outlinePaint,
  ) {
    if (selectedMuscles.contains('Pectoraux')) {
      final pectPath = Path()
        ..moveTo(size.width / 2 - 55, 105)
        ..lineTo(size.width / 2, 115)
        ..lineTo(size.width / 2, 175)
        ..lineTo(size.width / 2 - 55, 165)
        ..close();
      canvas.drawPath(pectPath, selectedPaint);
      final pectPath2 = Path()
        ..moveTo(size.width / 2 + 55, 105)
        ..lineTo(size.width / 2, 115)
        ..lineTo(size.width / 2, 175)
        ..lineTo(size.width / 2 + 55, 165)
        ..close();
      canvas.drawPath(pectPath2, selectedPaint);
    }

    if (selectedMuscles.contains('Abdominaux')) {
      for (int i = 0; i < 3; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width / 2 - 30, 178 + i * 30.0, 25, 22),
            const Radius.circular(4),
          ),
          selectedPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width / 2 + 5, 178 + i * 30.0, 25, 22),
            const Radius.circular(4),
          ),
          selectedPaint,
        );
      }
    }

    if (selectedMuscles.contains('Biceps')) {
      final bicepsPath = Path()
        ..moveTo(size.width / 2 - 95, 115)
        ..lineTo(size.width / 2 - 73, 115)
        ..lineTo(size.width / 2 - 76, 185)
        ..lineTo(size.width / 2 - 98, 185)
        ..close();
      canvas.drawPath(bicepsPath, selectedPaint);
    }

    if (selectedMuscles.contains('Biceps droit')) {
      final bicepsPath = Path()
        ..moveTo(size.width / 2 + 73, 115)
        ..lineTo(size.width / 2 + 95, 115)
        ..lineTo(size.width / 2 + 98, 185)
        ..lineTo(size.width / 2 + 76, 185)
        ..close();
      canvas.drawPath(bicepsPath, selectedPaint);
    }

    if (selectedMuscles.contains('Épaules')) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2 - 80, 115),
          width: 38,
          height: 28,
        ),
        selectedPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2 + 80, 115),
          width: 38,
          height: 28,
        ),
        selectedPaint,
      );
    }

    if (selectedMuscles.contains('Quadriceps')) {
      final quadPath = Path()
        ..moveTo(size.width / 2 - 55, 305)
        ..lineTo(size.width / 2 - 12, 305)
        ..lineTo(size.width / 2 - 15, 415)
        ..lineTo(size.width / 2 - 57, 415)
        ..close();
      canvas.drawPath(quadPath, selectedPaint);
    }

    if (selectedMuscles.contains('Quadriceps droit')) {
      final quadPath = Path()
        ..moveTo(size.width / 2 + 12, 305)
        ..lineTo(size.width / 2 + 55, 305)
        ..lineTo(size.width / 2 + 57, 415)
        ..lineTo(size.width / 2 + 15, 415)
        ..close();
      canvas.drawPath(quadPath, selectedPaint);
    }

    if (selectedMuscles.contains('Mollets')) {
      final calfPath = Path()
        ..moveTo(size.width / 2 - 57, 420)
        ..lineTo(size.width / 2 - 17, 420)
        ..lineTo(size.width / 2 - 19, 500)
        ..lineTo(size.width / 2 - 59, 500)
        ..close();
      canvas.drawPath(calfPath, selectedPaint);
    }

    if (selectedMuscles.contains('Mollets droits')) {
      final calfPath = Path()
        ..moveTo(size.width / 2 + 17, 420)
        ..lineTo(size.width / 2 + 57, 420)
        ..lineTo(size.width / 2 + 59, 500)
        ..lineTo(size.width / 2 + 19, 500)
        ..close();
      canvas.drawPath(calfPath, selectedPaint);
    }
  }

  void _paintBackMuscles(
    Canvas canvas,
    Size size,
    Paint selectedPaint,
    Paint outlinePaint,
  ) {
    if (selectedMuscles.contains('Dorsaux')) {
      final latPath = Path()
        ..moveTo(size.width / 2 - 55, 110)
        ..lineTo(size.width / 2 - 10, 145)
        ..lineTo(size.width / 2 - 10, 230)
        ..lineTo(size.width / 2 - 55, 210)
        ..close();
      canvas.drawPath(latPath, selectedPaint);
      final latPath2 = Path()
        ..moveTo(size.width / 2 + 55, 110)
        ..lineTo(size.width / 2 + 10, 145)
        ..lineTo(size.width / 2 + 10, 230)
        ..lineTo(size.width / 2 + 55, 210)
        ..close();
      canvas.drawPath(latPath2, selectedPaint);
    }

    if (selectedMuscles.contains('Trapèzes')) {
      final trapPath = Path()
        ..moveTo(size.width / 2 - 55, 100)
        ..lineTo(size.width / 2 + 55, 100)
        ..lineTo(size.width / 2 + 20, 150)
        ..lineTo(size.width / 2, 130)
        ..lineTo(size.width / 2 - 20, 150)
        ..close();
      canvas.drawPath(trapPath, selectedPaint);
    }

    if (selectedMuscles.contains('Triceps')) {
      final tricepsPath = Path()
        ..moveTo(size.width / 2 - 73, 115)
        ..lineTo(size.width / 2 - 95, 115)
        ..lineTo(size.width / 2 - 98, 185)
        ..lineTo(size.width / 2 - 76, 185)
        ..close();
      canvas.drawPath(tricepsPath, selectedPaint);
    }

    if (selectedMuscles.contains('Triceps droit')) {
      final tricepsPath = Path()
        ..moveTo(size.width / 2 + 95, 115)
        ..lineTo(size.width / 2 + 73, 115)
        ..lineTo(size.width / 2 + 76, 185)
        ..lineTo(size.width / 2 + 98, 185)
        ..close();
      canvas.drawPath(tricepsPath, selectedPaint);
    }

    if (selectedMuscles.contains('Lombaires')) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width / 2 - 25, 220, 20, 55),
          const Radius.circular(4),
        ),
        selectedPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width / 2 + 5, 220, 20, 55),
          const Radius.circular(4),
        ),
        selectedPaint,
      );
    }

    if (selectedMuscles.contains('Fessiers')) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2 - 28, 295),
          width: 55,
          height: 45,
        ),
        selectedPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2 + 28, 295),
          width: 55,
          height: 45,
        ),
        selectedPaint,
      );
    }

    if (selectedMuscles.contains('Ischio-jambiers')) {
      final hamPath = Path()
        ..moveTo(size.width / 2 - 55, 318)
        ..lineTo(size.width / 2 - 12, 318)
        ..lineTo(size.width / 2 - 15, 415)
        ..lineTo(size.width / 2 - 57, 415)
        ..close();
      canvas.drawPath(hamPath, selectedPaint);
    }

    if (selectedMuscles.contains('Ischio-jambiers droits')) {
      final hamPath = Path()
        ..moveTo(size.width / 2 + 12, 318)
        ..lineTo(size.width / 2 + 55, 318)
        ..lineTo(size.width / 2 + 57, 415)
        ..lineTo(size.width / 2 + 15, 415)
        ..close();
      canvas.drawPath(hamPath, selectedPaint);
    }
  }

  void _paintFrontDetails(Canvas canvas, Size size, Paint outlinePaint) {
    final detailPaint = Paint()
      ..color = const Color(0xFF4A6FA5).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(size.width / 2, 100),
      Offset(size.width / 2, 278),
      detailPaint,
    );
    canvas.drawLine(
      Offset(size.width / 2 - 55, 165),
      Offset(size.width / 2 + 55, 165),
      detailPaint,
    );

    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width / 2 - 30, 178 + i * 30.0),
        Offset(size.width / 2 + 30, 178 + i * 30.0),
        detailPaint,
      );
    }
  }

  void _paintBackDetails(Canvas canvas, Size size, Paint outlinePaint) {
    final detailPaint = Paint()
      ..color = const Color(0xFF4A6FA5).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 8; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, 110 + i * 20.0),
          width: 12,
          height: 10,
        ),
        detailPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BodyPainter oldDelegate) =>
      oldDelegate.selectedMuscles != selectedMuscles ||
      oldDelegate.showFront != showFront;
}
