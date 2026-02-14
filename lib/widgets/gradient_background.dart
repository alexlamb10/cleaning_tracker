import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFB8E6D5), // Light mint
            Color(0xFFE8F5F1), // Very light mint
            Colors.white,
          ],
          stops: [0.0, 0.3, 0.7],
        ),
      ),
      child: child,
    );
  }
}
