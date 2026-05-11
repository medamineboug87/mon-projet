import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Future<void> Function()? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final IconData? icon;
  final String? iconPath;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.icon,
    this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Color(0xFF00897B),
          foregroundColor: textColor ?? Color(0xFF1A2340),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Color(0xFFFFFFFF))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ] else if (iconPath != null) ...[
                    SvgPicture.asset(
                      iconPath!,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        textColor ?? Color(0xFF1A2340),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}