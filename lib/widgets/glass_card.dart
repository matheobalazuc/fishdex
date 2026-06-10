import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/fishdex_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 12,
    this.padding,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                FishdexTheme.glassWhite,
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: borderColor ?? FishdexTheme.glassBorder,
              width: 0.5,
            ),
          ),
          child: padding != null ? Padding(padding: padding!, child: child) : child,
        ),
      ),
    );
  }
}