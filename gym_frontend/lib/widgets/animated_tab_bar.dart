import 'package:flutter/material.dart';

class AnimatedTabBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<Map<String, dynamic>> items;

  const AnimatedTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isActive = currentIndex == index;
          final item = items[index];
          final badgeCount = item['badgeCount'] as int? ?? 0;

          return GestureDetector(
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 16 : 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? Color(0xFF00897B).withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Icône avec badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isActive ? item['filledIcon'] : item['outlinedIcon'],
                        color: isActive
                            ? const Color(0xFF00897B)
                            : Color(0xFF6B7A99),
                        size: 22,
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          right: -8,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              badgeCount > 99 ? '99+' : '$badgeCount',
                              style: const TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Text(
                      item['label'],
                      style: const TextStyle(
                        color: Color(0xFF00897B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
