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

  void _drawBlob(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    Color color,
    double alpha,
  ) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * 0.35),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Blob 1 – top left emerald
    final b1x = w * (0.1 + 0.15 * sin(t * pi));
    final b1y = h * (0.08 + 0.08 * cos(t * pi));
    _drawBlob(canvas, size, Offset(b1x, b1y), w * 0.55,
        theme.primaryEmerald, 0.11);

    // Blob 2 – top right cyan
    final b2x = w * (0.85 - 0.12 * sin(t * pi * 1.3));
    final b2y = h * (0.05 + 0.1 * cos(t * pi * 0.7));
    _drawBlob(canvas, size, Offset(b2x, b2y), w * 0.50,
        theme.accentCyan, 0.09);

    // Blob 3 – mid indigo
    final b3x = w * (0.5 + 0.1 * cos(t * pi * 1.7));
    final b3y = h * (0.35 + 0.06 * sin(t * pi * 1.1));
    _drawBlob(canvas, size, Offset(b3x, b3y), w * 0.45,
        theme.accentIndigo, 0.07);

    // Blob 4 – bottom violet accent
    final b4x = w * (0.2 + 0.1 * cos(t * pi * 0.9));
    final b4y = h * (0.72 + 0.05 * sin(t * pi * 1.4));
    _drawBlob(canvas, size, Offset(b4x, b4y), w * 0.40,
        theme.accentViolet, 0.06);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.t != t;
}
