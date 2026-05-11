import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool withGlow;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(20),
    this.withGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: withGlow
            ? [
                BoxShadow(
                  color: Color(0xFF00897B).withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF).withValues(alpha: 0.95),
                  Color(0xFFE8EEF7).withValues(alpha: 0.95),
                ],
              ),
              border: Border.all(
                color: Color(0xFF00897B).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
