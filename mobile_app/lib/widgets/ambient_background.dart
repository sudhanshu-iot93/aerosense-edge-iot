// widgets/ambient_background.dart
// Animated aurora radial blobs giving 3-D depth to the dashboard

import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AmbientBackground extends StatefulWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AeroTheme>()!;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Animated aurora layer
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(painter: _AuroraPainter(_controller.value, Theme.of(context).extension<AeroTheme>()!),
              child: SizedBox.expand(),
            );
          },
        ),
        // Noise/grain overlay for texture
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.6),
                radius: 1.2,
                colors: [
                  theme.bgDark.withValues(alpha: 0.0),
                  theme.bgDark.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
        ),
        // Content
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final AeroTheme theme;
  final double t; // 0..1 animation progress
  _AuroraPainter(this.t, this.theme);

  void _drawAtmosphericGlow(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    Color color,
    double peakAlpha,
  ) {
    final isLight = theme.bgDark.computeLuminance() > 0.5;
    final effectiveAlpha = isLight ? peakAlpha * 0.70 : peakAlpha;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: effectiveAlpha),
          color.withValues(alpha: effectiveAlpha * 0.55),
          color.withValues(alpha: effectiveAlpha * 0.18),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..blendMode = isLight ? BlendMode.srcOver : BlendMode.screen;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base deep aerospace tint
    final baseGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        theme.bgDeepNavy,
        theme.bgDark,
      ],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = baseGradient.createShader(Offset.zero & size),
    );

    // Primary Focal Aura — centered behind Hero AQI Gauge (top center)
    final heroX = w * (0.50 + 0.06 * sin(t * 2 * pi));
    final heroY = h * (0.16 + 0.04 * cos(t * 2 * pi));
    _drawAtmosphericGlow(
      canvas,
      size,
      Offset(heroX, heroY),
      w * 0.85,
      theme.primaryEmerald,
      0.14,
    );

    // Secondary Accent Aura — Top-Right Azure Cyber Glow
    final cyanX = w * (0.88 - 0.10 * cos(t * 2 * pi * 0.8));
    final cyanY = h * (0.10 + 0.05 * sin(t * 2 * pi * 0.8));
    _drawAtmosphericGlow(
      canvas,
      size,
      Offset(cyanX, cyanY),
      w * 0.75,
      theme.accentCyan,
      0.12,
    );

    // Deep Aerospace Indigo Drift — Mid-lower background
    final indX = w * (0.25 + 0.12 * sin(t * 2 * pi * 1.1));
    final indY = h * (0.48 + 0.06 * cos(t * 2 * pi * 0.9));
    _drawAtmosphericGlow(
      canvas,
      size,
      Offset(indX, indY),
      w * 0.90,
      theme.accentIndigo,
      0.09,
    );

    // Ambient Violet Base Flare — Bottom-Right depth
    final vioX = w * (0.75 + 0.08 * cos(t * 2 * pi * 0.6));
    final vioY = h * (0.80 + 0.04 * sin(t * 2 * pi * 0.7));
    _drawAtmosphericGlow(
      canvas,
      size,
      Offset(vioX, vioY),
      w * 0.80,
      theme.accentViolet,
      0.07,
    );
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.t != t;
}
