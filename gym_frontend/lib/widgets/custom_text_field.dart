import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int? maxLines;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixPressed;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.suffixIcon,
    this.onSuffixPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: const TextStyle(color: Color(0xFF1A2340)),
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        fillColor: const Color(0xFFE8EEF7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00897B)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00897B)),
        ),
        suffixIcon: suffixIcon != null
            ? IconButton(icon: suffixIcon!, onPressed: onSuffixPressed)
            : null,
      ),
      style: const TextStyle(color: Color(0xFFFFFFFF)),
    );
  }
}
