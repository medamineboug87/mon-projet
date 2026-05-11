import 'package:flutter/material.dart';

class NeonButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final bool outlined;

  const NeonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? Color(0xFF00897B);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: outlined
            ? null
            : LinearGradient(
                colors: [buttonColor, buttonColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        border: outlined ? Border.all(color: buttonColor, width: 1.5) : null,
        boxShadow: outlined
            ? null
            : [
                BoxShadow(
                  color: buttonColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: outlined ? buttonColor : Color(0xFF1A2340),
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: outlined ? buttonColor : Color(0xFF1A2340),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          color: outlined ? buttonColor : Color(0xFF1A2340),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}