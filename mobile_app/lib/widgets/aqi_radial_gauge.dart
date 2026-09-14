// widgets/aqi_radial_gauge.dart
// Animated 3-D glassmorphic AQI gauge with triple-ring depth and shimmer pulse

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AqiRadialGauge extends StatefulWidget {
  final int aqi;
  final String aqiCategory;
  final String primaryPollutant;

  const AqiRadialGauge({
    super.key,
    required this.aqi,
    required this.aqiCategory,
    required this.primaryPollutant,
  });

  @override
  State<AqiRadialGauge> createState() => _AqiRadialGaugeState();
}

class _AqiRadialGaugeState extends State<AqiRadialGauge>
    with TickerProviderStateMixin {
  late AnimationController _sweepCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _sweepAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _sweepAnim = CurvedAnimation(
      parent: _sweepCtrl,
      curve: Curves.easeOutCubic,
    );
    _sweepCtrl.forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant AqiRadialGauge old) {
    super.didUpdateWidget(old);
    if (old.aqi != widget.aqi) {
      _sweepCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AeroTheme>()!;
    final aqiColor = AeroTheme.getAqiColor(widget.aqi);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: theme.deepCardDecoration(
            glowColor: aqiColor,
            glowIntensity: 0.30,
            borderColor: aqiColor.withValues(alpha: 0.50),
            borderRadius: 24,
          ),
          child: Column(
            children: [
              // ── Header row ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.air_outlined, size: 16, color: aqiColor),
                      SizedBox(width: 8),
                      Text(
                        'HYPERLOCAL AQI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryEmerald
                              .withValues(alpha: 0.08 + 0.06 * _pulseAnim.value),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.primaryEmerald
                                .withValues(alpha: 0.30 + 0.20 * _pulseAnim.value),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.primaryEmerald.withValues(
                                    alpha: 0.6 + 0.4 * _pulseAnim.value),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Live • 1 Hz DMA',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),

              // ── 3-D Animated Gauge ────────────────────────────────────────
              AnimatedBuilder(
                animation: Listenable.merge(
                    [_sweepAnim, _pulseAnim, _shimmerCtrl]),
                builder: (context, child) {
                  return SizedBox(
                    width: 240,
                    height: 210,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Layer 1: Outermost deep shadow ring
                        CustomPaint(
                          size: const Size(240, 210),
                          painter: _ShadowRingPainter(
                            theme: theme,
                            aqi: widget.aqi,
                            aqiColor: aqiColor,
                            sweepProgress: _sweepAnim.value,
                          ),
                        ),
                        // Layer 2: Mid glow ring
                        CustomPaint(
                          size: const Size(240, 210),
                          painter: _MidRingPainter(
                            theme: theme,
                            aqi: widget.aqi,
                            aqiColor: aqiColor,
                            sweepProgress: _sweepAnim.value,
                            pulseValue: _pulseAnim.value,
                          ),
                        ),
                        // Layer 3: Bright top ring + shimmer
                        CustomPaint(
                          size: const Size(240, 210),
                          painter: _TopRingPainter(
                            theme: theme,
                            aqi: widget.aqi,
                            aqiColor: aqiColor,
                            sweepProgress: _sweepAnim.value,
                            shimmerAngle: _shimmerCtrl.value * 2 * pi,
                          ),
                        ),
                        // Layer 4: Particle dots on ring
                        CustomPaint(
                          size: const Size(240, 210),
                          painter: _ParticleDotsPainter(
                            aqi: widget.aqi,
                            aqiColor: aqiColor,
                            sweepProgress: _sweepAnim.value,
                          ),
                        ),
                        // ── Centre content ──────────────────────────────────
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: widget.aqi),
                          duration: const Duration(milliseconds: 1400),
                          curve: Curves.easeOutCubic,
                          builder: (context, displayAqi, child) {
                            final col = AeroTheme.getAqiColor(displayAqi);
                            final isLight = theme.bgDark.computeLuminance() > 0.5;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Inner glass disc with dual-ring bevel
                                Container(
                                  width: 126,
                                  height: 126,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        col.withValues(alpha: isLight ? 0.12 : 0.18),
                                        isLight ? const Color(0xFFF1F5F9) : theme.bgDeepNavy.withValues(alpha: 0.85),
                                        isLight ? Colors.white : theme.bgDark.withValues(alpha: 0.95),
                                      ],
                                      stops: const [0.0, 0.65, 1.0],
                                    ),
                                    border: Border.all(
                                      color: isLight ? theme.glassBorder : Colors.white.withValues(alpha: 0.16),
                                      width: 1.4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: col.withValues(alpha: isLight ? 0.15 : 0.28),
                                        blurRadius: 28,
                                        spreadRadius: 2,
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.45),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$displayAqi',
                                        style: TextStyle(
                                          fontSize: 50,
                                          fontWeight: FontWeight.w900,
                                          color: isLight ? theme.textPrimary : Colors.white,
                                          letterSpacing: -1.0,
                                          height: 1.0,
                                          shadows: [
                                            Shadow(
                                              color: col.withValues(alpha: isLight ? 0.35 : 0.85),
                                              blurRadius: 22,
                                            ),
                                            if (!isLight)
                                              Shadow(
                                                color: col.withValues(alpha: 0.40),
                                                blurRadius: 44,
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: col.withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: col.withValues(alpha: 0.45),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          'AQI • NAQI',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: col,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // ── Category badge ──────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                    decoration: BoxDecoration(
                      color: aqiColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: aqiColor.withValues(alpha: 0.55), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: aqiColor.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: aqiColor,
                            boxShadow: [
                              BoxShadow(
                                color: aqiColor,
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.aqiCategory.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: aqiColor,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prominent: ${widget.primaryPollutant}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // ── Continuous NAQI spectrum bar with animated pin indicator ───────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = constraints.maxWidth;
                      final clampedAqi = widget.aqi.clamp(0, 500);
                      final pinRatio = clampedAqi / 500.0;
                      final pinLeft = (barWidth * pinRatio - 7.5).clamp(0.0, barWidth - 15);

                      return SizedBox(
                        height: 20,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.centerLeft,
                          children: [
                            // Continuous gradient track
                            Container(
                              height: 7,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(
                                  colors: [
                                    theme.aqiGood,
                                    theme.aqiSatisfactory,
                                    theme.aqiModerate,
                                    theme.aqiPoor,
                                    theme.aqiVeryPoor,
                                    theme.aqiSevere,
                                  ],
                                  stops: const [0.08, 0.20, 0.40, 0.60, 0.80, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            // Sliding indicator pin
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              left: pinLeft,
                              child: Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: aqiColor,
                                    width: 3.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: aqiColor.withValues(alpha: 0.85),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                    const BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0 Good',
                          style: TextStyle(
                              fontSize: 9.5, fontWeight: FontWeight.w600, color: theme.textMuted)),
                      Text('100',
                          style: TextStyle(
                              fontSize: 9.5, fontWeight: FontWeight.w600, color: theme.textMuted)),
                      Text('200',
                          style: TextStyle(
                              fontSize: 9.5, fontWeight: FontWeight.w600, color: theme.textMuted)),
                      Text('300',
                          style: TextStyle(
                              fontSize: 9.5, fontWeight: FontWeight.w600, color: theme.textMuted)),
                      Text('500+ Severe',
                          style: TextStyle(
                              fontSize: 9.5, fontWeight: FontWeight.w600, color: theme.textMuted)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════════

const double _startDeg = 135.0;
const double _totalDeg = 270.0;
double get _startRad => _startDeg * pi / 180;
double get _totalRad => _totalDeg * pi / 180;

class _ShadowRingPainter extends CustomPainter {
  final AeroTheme theme;
  final int aqi;
  final Color aqiColor;
  final double sweepProgress;
  _ShadowRingPainter({
    required this.theme,
    required this.aqi,
    required this.aqiColor,
    required this.sweepProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 8);
    final radius = size.width / 2 - 14;
    final isLight = theme.bgDark.computeLuminance() > 0.5;

    // Deep shadow track (outermost)
    final bgPaint = Paint()
      ..color = isLight ? Colors.black.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startRad, _totalRad, false, bgPaint,
    );

    // Mid track
    final midPaint = Paint()
      ..color = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF0D1730)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startRad, _totalRad, false, midPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ShadowRingPainter old) =>
      old.aqi != aqi || old.sweepProgress != sweepProgress;
}

class _MidRingPainter extends CustomPainter {
  final AeroTheme theme;
  final int aqi;
  final Color aqiColor;
  final double sweepProgress;
  final double pulseValue;
  _MidRingPainter({
    required this.theme,
    required this.aqi,
    required this.aqiColor,
    required this.sweepProgress,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 8);
    final radius = size.width / 2 - 14;
    final progress = (aqi / 500.0).clamp(0.03, 1.0);
    final activeSweep = _totalRad * progress * sweepProgress;

    // Glowing mid ring (slightly smaller)
    final glowPaint = Paint()
      ..shader = SweepGradient(
        startAngle: _startRad,
        endAngle: _startRad + _totalRad,
        colors: [
          theme.primaryEmerald.withValues(alpha: 0.40),
          aqiColor.withValues(alpha: 0.55 + 0.10 * pulseValue),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + 4 * pulseValue);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startRad, activeSweep, false, glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MidRingPainter old) =>
      old.aqi != aqi ||
      old.sweepProgress != sweepProgress ||
      old.pulseValue != pulseValue;
}

class _TopRingPainter extends CustomPainter {
  final AeroTheme theme;
  final int aqi;
  final Color aqiColor;
  final double sweepProgress;
  final double shimmerAngle;
  _TopRingPainter({
    required this.theme,
    required this.aqi,
    required this.aqiColor,
    required this.sweepProgress,
    required this.shimmerAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 8);
    final radius = size.width / 2 - 14;
    final progress = (aqi / 500.0).clamp(0.03, 1.0);
    final activeSweep = _totalRad * progress * sweepProgress;

    // Bright sharp top ring
    final topPaint = Paint()
      ..shader = SweepGradient(
        startAngle: _startRad,
        endAngle: _startRad + _totalRad,
        colors: [
          theme.primaryEmerald,
          aqiColor,
          theme.glowCyan,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startRad, activeSweep, false, topPaint,
    );

    // Shimmer highlight dot + glowing beacon at arc tip
    if (activeSweep > 0.05) {
      final tipAngle = _startRad + activeSweep;
      final tipX = center.dx + radius * cos(tipAngle);
      final tipY = center.dy + radius * sin(tipAngle);

      final haloPaint = Paint()
        ..color = aqiColor.withValues(alpha: 0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(tipX, tipY), 8, haloPaint);

      final beadPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(tipX, tipY), 4.5, beadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TopRingPainter old) =>
      old.aqi != aqi ||
      old.sweepProgress != sweepProgress ||
      old.shimmerAngle != shimmerAngle;
}

class _ParticleDotsPainter extends CustomPainter {
  final int aqi;
  final Color aqiColor;
  final double sweepProgress;
  _ParticleDotsPainter({
    required this.aqi,
    required this.aqiColor,
    required this.sweepProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 8);
    final radius = size.width / 2 - 14;
    const dotCount = 6;
    final progress = (aqi / 500.0).clamp(0.03, 1.0);
    final activeSweep = _totalRad * progress * sweepProgress;

    for (int i = 0; i < dotCount; i++) {
      final fraction = i / (dotCount - 1);
      if (fraction > progress * sweepProgress) break;
      final angle = _startRad + activeSweep * fraction;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      final dotPaint = Paint()
        ..color = aqiColor.withValues(alpha: 0.5 * (1 - fraction * 0.5))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 - fraction * 1.5);
      canvas.drawCircle(Offset(x, y), 4.0 - fraction * 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleDotsPainter old) =>
      old.aqi != aqi || old.sweepProgress != sweepProgress;
}
