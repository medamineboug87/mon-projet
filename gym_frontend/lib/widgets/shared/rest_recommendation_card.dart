import 'package:flutter/material.dart';

const Color _kGreen = Color(0xFF00897B);
const Color _kOrange = Color(0xFFF57C00);
const Color _kRed = Color(0xFFE53935);
const Color _kText = Color(0xFF1A2340);

class RestRecommendationCard extends StatelessWidget {
  final int days;

  const RestRecommendationCard({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final (cardColor, intensity, icon) = _getStyle(days);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text('💤', style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Repos recommandé', style: TextStyle(color: _kText, fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 4),
                Text('$days jour${days > 1 ? 's' : ''} de repos', style: TextStyle(color: cardColor, fontSize: 20, fontWeight: FontWeight.w900)),
                Text(intensity, style: TextStyle(color: cardColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
          ),
        ],
      ),
    );
  }

  (Color, String, String) _getStyle(int days) {
    if (days >= 3) {
      return (_kRed, 'Repos prolongé requis', '🛌');
    } else if (days >= 2) {
      return (_kOrange, 'Repos actif recommandé', '🚶');
    } else {
      return (_kGreen, 'Repos léger', '💪');
    }
  }
}