// widgets/glass_card.dart
// Reusable true-frosted-glass card using BackdropFilter

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final Color? fillColor;
  final double blurSigma;
  final bool glow;
  final Color? glowColor;
  final double glowIntensity;
  final double elevation;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20.0,
    this.borderColor,
    this.fillColor,
    this.blurSigma = 18.0,
    this.glow = false,
    this.glowColor,
    this.glowIntensity = 0.22,
    this.elevation = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Theme.of(context).extension<AeroTheme>()!.glassCardDecoration(
        borderColor: borderColor,
        borderRadius: borderRadius,
        glow: glow,
        glowColor: glowColor,
        glowIntensity: glowIntensity,
        fillColor: fillColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.055),
                  Colors.white.withValues(alpha: 0.025),
                  Colors.white.withValues(alpha: 0.01),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Deep hero variant with stronger gradients and glow
class HeroGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? glowColor;
  final Color? borderColor;

  const HeroGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24.0,
    this.glowColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Theme.of(context).extension<AeroTheme>()!.deepCardDecoration(
        borderRadius: borderRadius,
        glowColor: glowColor,
        borderColor: borderColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.035),
                  Colors.white.withValues(alpha: 0.008),
                ],
                stops: const [0.0, 0.35, 1.0],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
