import 'package:flutter/material.dart';

const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kBlue = Color(0xFF1976D2);
const Color _kRed = Color(0xFFE53935);
const Color _kOrange = Color(0xFFF57C00);
const Color _kPurple = Color(0xFF7B1FA2);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class SessionCardioSection extends StatefulWidget {
  final bool hasCardio;
  final String cardioType;
  final int cardioIntensity;
  final TextEditingController durationCtrl;
  final Function(bool, String, int) onCardioChanged;

  const SessionCardioSection({
    super.key,
    required this.hasCardio,
    required this.cardioType,
    required this.cardioIntensity,
    required this.durationCtrl,
    required this.onCardioChanged,
  });

  @override
  State<SessionCardioSection> createState() => _SessionCardioSectionState();
}

class _SessionCardioSectionState extends State<SessionCardioSection> {
  static const List<String> _cardioTypes = [
    'Course', 'Vélo', 'HIIT', 'Natation', 'Elliptique', 'Rameur', 'Marche', 'Corde',
  ];

  static const Map<String, IconData> _cardioIcons = {
    'Course': Icons.directions_run_rounded,
    'Vélo': Icons.pedal_bike_rounded,
    'HIIT': Icons.flash_on_rounded,
    'Natation': Icons.pool_rounded,
    'Elliptique': Icons.loop_rounded,
    'Rameur': Icons.rowing_rounded,
    'Marche': Icons.directions_walk_rounded,
    'Corde': Icons.cable_rounded,
  };

  static const Map<String, Color> _cardioColors = {
    'Course': _kGreen,
    'Vélo': _kBlue,
    'HIIT': _kRed,
    'Natation': _kBlue,
    'Elliptique': Color(0xFFCE93D8),
    'Rameur': _kOrange,
    'Marche': Color(0xFF69F0AE),
    'Corde': _kRed,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurf2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.hasCardio ? (_cardioColors[widget.cardioType] ?? _kGreen).withValues(alpha: 0.4) : _kBorder,
          width: widget.hasCardio ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: _kPurple.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.favorite_rounded, color: _kPurple, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cardio', style: TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.w800)),
                      Text(
                        widget.hasCardio
                            ? '${widget.cardioType} • ${widget.durationCtrl.text.isEmpty ? "?" : widget.durationCtrl.text} min'
                            : 'Aucun cardio cette séance',
                        style: TextStyle(
                          color: widget.hasCardio ? (_cardioColors[widget.cardioType] ?? _kGreen) : _kTextSub,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.hasCardio,
                  onChanged: (v) => widget.onCardioChanged(v, widget.cardioType, widget.cardioIntensity),
                  activeColor: _kPurple,
                ),
              ],
            ),
          ),
          if (widget.hasCardio) ...[
            const Divider(color: _kBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Type de cardio', style: TextStyle(color: _kTextSub, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.85,
                    children: _cardioTypes.map((type) {
                      final isSelected = widget.cardioType == type;
                      final color = _cardioColors[type] ?? _kGreen;
                      return GestureDetector(
                        onTap: () => widget.onCardioChanged(widget.hasCardio, type, widget.cardioIntensity),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withValues(alpha: 0.15) : _kText.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? color.withValues(alpha: 0.5) : _kBorder, width: isSelected ? 1.5 : 1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_cardioIcons[type] ?? Icons.directions_run_rounded, color: isSelected ? color : _kBorder, size: 22),
                              const SizedBox(height: 4),
                              Text(type, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? color : _kTextSub, fontSize: 9, fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildDurationField(),
                  const SizedBox(height: 16),
                  _buildIntensityRow(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDurationField() {
    return TextFormField(
      controller: widget.durationCtrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: _kText),
      decoration: InputDecoration(
        labelText: 'Durée (minutes)',
        labelStyle: const TextStyle(color: _kTextSub),
        prefixIcon: const Icon(Icons.timer_outlined, color: _kGreen, size: 20),
        filled: true,
        fillColor: _kSurf2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kGreen, width: 1.5)),
      ),
    );
  }

  Widget _buildIntensityRow() {
    final color = _cardioColors[widget.cardioType] ?? _kGreen;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Intensité cardio', style: TextStyle(color: _kTextSub, fontSize: 11, fontWeight: FontWeight.w700)),
            _IntensityBadge(intensity: widget.cardioIntensity, cardioType: widget.cardioType),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: _kBorder,
            thumbColor: color,
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: widget.cardioIntensity.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (v) => widget.onCardioChanged(widget.hasCardio, widget.cardioType, v.round()),
          ),
        ),
      ],
    );
  }
}

class _IntensityBadge extends StatelessWidget {
  final int intensity;
  final String cardioType;
  const _IntensityBadge({required this.intensity, required this.cardioType});

  Color _color() {
    if (intensity >= 8) return const Color(0xFFE53935);
    if (intensity >= 6) return const Color(0xFFF57C00);
    if (intensity >= 4) return const Color(0xFFFFD740);
    return const Color(0xFF00897B);
  }

  String _label() {
    if (intensity >= 8) return 'Intense';
    if (intensity >= 6) return 'Modérée';
    if (intensity >= 4) return 'Légère';
    return 'Très légère';
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$intensity/10', style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(width: 5),
          Text('• ${_label()}', style: TextStyle(color: c.withValues(alpha: 0.7), fontSize: 11)),
        ],
      ),
    );
  }
}