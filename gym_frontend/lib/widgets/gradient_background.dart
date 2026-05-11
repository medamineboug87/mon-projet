import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool animated;

  const GradientBackground({
    super.key,
    required this.child,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: animated
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0F1A),
                    Color(0xFF0D111D),
                    Color(0xFF141828),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A0F1A), Color(0xFF141828)],
                ),
        ),
        child: child,
      ),
    );
  }
}
