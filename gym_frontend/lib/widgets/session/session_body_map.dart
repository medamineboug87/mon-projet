import 'package:flutter/material.dart';
import '../../models/muscle_zone.dart';

// ─── Design tokens ───
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kBlue = Color(0xFF1976D2);
const Color _kOrange = Color(0xFFF57C00);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

const double _svgW = 350.0;
const double _svgH = 520.0;

class SessionBodyMap extends StatefulWidget {
  final Set<String> selectedMuscles;
  final Function(Set<String>) onMusclesChanged;
  final bool showFront;
  final List<MuscleZone> frontMuscles;
  final List<MuscleZone> backMuscles;
  final Function(bool) onViewChanged;

  const SessionBodyMap({
    super.key,
    required this.selectedMuscles,
    required this.onMusclesChanged,
    required this.showFront,
    required this.frontMuscles,
    required this.backMuscles,
    required this.onViewChanged,
  });

  @override
  State<SessionBodyMap> createState() => _SessionBodyMapState();
}

class _SessionBodyMapState extends State<SessionBodyMap> {
  List<MuscleZone> get _currentMuscles =>
      widget.showFront ? widget.frontMuscles : widget.backMuscles;

  void _toggleMuscle(String muscle) {
    final newSet = Set<String>.from(widget.selectedMuscles);
    if (newSet.contains(muscle)) {
      newSet.remove(muscle);
    } else {
      newSet.add(muscle);
    }
    widget.onMusclesChanged(newSet);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💪 Muscles ciblés',
          style: TextStyle(
            color: _kOrange,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Appuyez sur un muscle pour le sélectionner',
          style: TextStyle(color: _kTextSub, fontSize: 11),
        ),
        const SizedBox(height: 12),
        _buildViewToggle(),
        const SizedBox(height: 10),
        if (widget.selectedMuscles.isNotEmpty) _buildSelectedChips(),
        Center(child: _buildBodyCanvas()),
        const SizedBox(height: 10),
        _buildMuscleChipsList(),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurf2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleBtn(
              'Face avant',
              widget.showFront,
              () => widget.onViewChanged(true),
            ),
          ),
          Expanded(
            child: _toggleBtn(
              'Vue arrière',
              !widget.showFront,
              () => widget.onViewChanged(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? _kGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? _kText : _kTextSub,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedChips() {
    return Wrap(
      spacing: 7,
      runSpacing: 6,
      children: widget.selectedMuscles
          .map(
            (m) => Chip(
              label: Text(
                m,
                style: const TextStyle(color: _kText, fontSize: 12),
              ),
              backgroundColor: _kGreen.withValues(alpha: 0.18),
              side: const BorderSide(color: _kGreen, width: 0.8),
              deleteIcon: const Icon(Icons.close, size: 14, color: _kTextSub),
              onDeleted: () => _toggleMuscle(m),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBodyCanvas() {
    return SizedBox(
      width: _svgW,
      height: _svgH,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(_svgW, _svgH),
            painter: BodyPainter(
              showFront: widget.showFront,
              selectedMuscles: widget.selectedMuscles,
              muscles: _currentMuscles,
            ),
          ),
          ..._currentMuscles.map((zone) {
            final isSelected = widget.selectedMuscles.contains(zone.name);
            return Positioned(
              left: zone.rect.left,
              top: zone.rect.top,
              width: zone.rect.width,
              height: zone.rect.height,
              child: GestureDetector(
                onTap: () => _toggleMuscle(zone.name),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kGreen.withValues(alpha: 0.35)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected
                        ? Border.all(color: _kGreen, width: 1.5)
                        : null,
                  ),
                  child: isSelected
                      ? Center(
                          child: Text(
                            zone.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _kText,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMuscleChipsList() {
    return Wrap(
      spacing: 7,
      runSpacing: 6,
      children: _currentMuscles.map((zone) {
        final isSelected = widget.selectedMuscles.contains(zone.name);
        return GestureDetector(
          onTap: () => _toggleMuscle(zone.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? _kGreen.withValues(alpha: 0.15) : _kSurf2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? _kGreen.withValues(alpha: 0.5) : _kBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              zone.name,
              style: TextStyle(
                color: isSelected ? _kGreen : _kTextSub,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class BodyPainter extends CustomPainter {
  final bool showFront;
  final Set<String> selectedMuscles;
  final List<MuscleZone> muscles;

  const BodyPainter({
    required this.showFront,
    required this.selectedMuscles,
    required this.muscles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()
      ..color = const Color(0xFF2C3E6B)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = const Color(0xFF4A6FA5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final cx = size.width / 2;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 44), width: 62, height: 72),
      body,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 44), width: 62, height: 72),
      outline,
    );
    canvas.drawRect(Rect.fromLTWH(cx - 16, 78, 32, 22), body);

    final torso = Path()
      ..moveTo(cx - 72, 100)
      ..lineTo(cx + 72, 100)
      ..lineTo(cx + 56, 282)
      ..lineTo(cx - 56, 282)
      ..close();
    canvas.drawPath(torso, body);
    canvas.drawPath(torso, outline);

    for (final dx in [-82.0, 82.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + dx, 114), width: 42, height: 32),
        body,
      );
    }

    _drawLimb(
      canvas,
      body,
      outline,
      Offset(cx - 70, 106),
      Offset(cx - 98, 222),
      22,
    );
    _drawLimb(
      canvas,
      body,
      outline,
      Offset(cx - 98, 222),
      Offset(cx - 100, 316),
      16,
    );
    _drawLimb(
      canvas,
      body,
      outline,
      Offset(cx + 70, 106),
      Offset(cx + 98, 222),
      22,
    );
    _drawLimb(
      canvas,
      body,
      outline,
      Offset(cx + 98, 222),
      Offset(cx + 100, 316),
      16,
    );

    final pelvis = Path()
      ..moveTo(cx - 56, 280)
      ..lineTo(cx + 56, 280)
      ..lineTo(cx + 62, 306)
      ..lineTo(cx - 62, 306)
      ..close();
    canvas.drawPath(pelvis, body);
    canvas.drawPath(pelvis, outline);

    _drawLimb(
      canvas,
      body,
      outline,
      Offset(cx - 34, 304),
      Offset(cx - 36, 420),
      28,
    );
    _drawLimb(
      canvas,
      body,
      outline,
      Offset(cx + 34, 304),
      Offset(cx + 36, 420),
      28,
    );
    _drawLimb(
      canvas,
      body,
      outline,
      Offset(cx - 36, 418),
      Offset(cx - 38, 508),
      22,
    );
    _drawLimb(
      canvas,
      body,
      outline,
      Offset(cx + 36, 418),
      Offset(cx + 38, 508),
      22,
    );

    final detail = Paint()
      ..color = const Color(0xFF4A6FA5).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    if (showFront) {
      canvas.drawLine(Offset(cx, 100), Offset(cx, 280), detail);
      for (int i = 0; i < 3; i++) {
        canvas.drawLine(
          Offset(cx - 28, 178 + i * 30.0),
          Offset(cx + 28, 178 + i * 30.0),
          detail,
        );
      }
    } else {
      for (int i = 0; i < 9; i++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, 108 + i * 18.0),
            width: 12,
            height: 10,
          ),
          detail,
        );
      }
    }
  }

  void _drawLimb(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    Offset top,
    Offset bottom,
    double halfW,
  ) {
    final path = Path()
      ..moveTo(top.dx - halfW, top.dy)
      ..lineTo(top.dx + halfW, top.dy)
      ..lineTo(bottom.dx + halfW * 0.85, bottom.dy)
      ..lineTo(bottom.dx - halfW * 0.85, bottom.dy)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant BodyPainter old) =>
      old.selectedMuscles != selectedMuscles || old.showFront != showFront;
}
