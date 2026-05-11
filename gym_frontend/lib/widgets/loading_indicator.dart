import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final Color? color;
  final double? size;

  const LoadingIndicator({super.key, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: color ?? Color(0xFF00897B),
        strokeWidth: size ?? 4.0,
      ),
    );
  }
}
