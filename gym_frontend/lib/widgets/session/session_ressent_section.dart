import 'package:flutter/material.dart';

const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kOrange = Color(0xFFF57C00);
const Color _kRed = Color(0xFFE53935);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class SessionRessentSection extends StatelessWidget {
  final int painLevel;
  final bool warmupDone;
  final ValueChanged<int> onPainChanged;
  final ValueChanged<bool> onWarmupChanged;

  const SessionRessentSection({
    super.key,
    required this.painLevel,
    required this.warmupDone,
    required this.onPainChanged,
    required this.onWarmupChanged,
  });

  @override
  Widget build(BuildContext context) {
    final painColor = _getPainColor();
    final painLabel = _getPainLabel();

    return Container(
      decoration: BoxDecoration(
        color: _kSurf2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (painLevel >= 7 || !warmupDone) ? (painLevel >= 7 ? _kRed.withValues(alpha: 0.4) : _kOrange.withValues(alpha: 0.4)) : _kBorder,
          width: (painLevel >= 7 || !warmupDone) ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(color: _kBorder, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWarmupRow(),
                const SizedBox(height: 16),
                _buildPainRow(painColor, painLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: const Color(0xFF26C6DA).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.sentiment_satisfied_alt_rounded, color: Color(0xFF26C6DA), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ressenti post-séance', style: TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.w800)),
                Text('Ces informations améliorent les prédictions IA', style: TextStyle(color: _kTextSub, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarmupRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Échauffement effectué', style: TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w700)),
              Text(
                warmupDone ? '✅ Risque de blessure réduit' : '⚠️ Sans échauffement = risque accru',
                style: TextStyle(color: warmupDone ? _kGreen : _kOrange, fontSize: 11),
              ),
            ],
          ),
        ),
        Switch(value: warmupDone, onChanged: onWarmupChanged, activeColor: _kGreen, inactiveThumbColor: _kOrange),
      ],
    );
  }

  Widget _buildPainRow(Color painColor, String painLabel) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Douleur ressentie', style: TextStyle(color: _kTextSub, fontSize: 11, fontWeight: FontWeight.w700)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: painColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: painColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$painLevel/10', style: TextStyle(color: painColor, fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 5),
                  Text('• $painLabel', style: TextStyle(color: painColor.withValues(alpha: 0.7), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: painColor,
            inactiveTrackColor: _kBorder,
            thumbColor: painColor,
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: painLevel.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => onPainChanged(v.round()),
          ),
        ),
      ],
    );
  }

  Color _getPainColor() {
    if (painLevel == 0) return _kGreen;
    if (painLevel <= 3) return const Color(0xFF69F0AE);
    if (painLevel <= 6) return _kOrange;
    return _kRed;
  }

  String _getPainLabel() {
    if (painLevel == 0) return 'Aucune douleur';
    if (painLevel <= 3) return 'Légère';
    if (painLevel <= 6) return 'Modérée';
    return 'Intense';
  }
}