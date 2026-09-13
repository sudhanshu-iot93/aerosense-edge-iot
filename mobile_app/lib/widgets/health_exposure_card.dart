// widgets/health_exposure_card.dart
// Feature 1: Cumulative Personal Health Exposure Engine
// Shows cigarette equivalent, lung load score, HP delta, and hourly PM2.5 breakdown

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class HealthExposureData {
  final double cigaretteEquivalent;
  final int healthPointsDelta;
  final double whoCompliancePct;
  final int compliantHours;
  final int hoursMonitored;
  final int lungLoadScore;
  final double avgPm25Today;
  final String exposureNarrative;
  final List<HourlyExposure> hourlyBreakdown;

  const HealthExposureData({
    this.cigaretteEquivalent = 0.0,
    this.healthPointsDelta = 0,
    this.whoCompliancePct = 100.0,
    this.compliantHours = 0,
    this.hoursMonitored = 0,
    this.lungLoadScore = 0,
    this.avgPm25Today = 0.0,
    this.exposureNarrative = '',
    this.hourlyBreakdown = const [],
  });

  factory HealthExposureData.fromJson(Map<String, dynamic> j) => HealthExposureData(
    cigaretteEquivalent: (j['cigarette_equivalent'] ?? 0).toDouble(),
    healthPointsDelta:   (j['health_points_delta'] ?? 0).toInt(),
    whoCompliancePct:    (j['who_compliance_pct'] ?? 100).toDouble(),
    compliantHours:      (j['compliant_hours'] ?? 0).toInt(),
    hoursMonitored:      (j['hours_monitored'] ?? 0).toInt(),
    lungLoadScore:       (j['lung_load_score'] ?? 0).toInt(),
    avgPm25Today:        (j['avg_pm25_today'] ?? 0).toDouble(),
    exposureNarrative:   j['exposure_narrative'] ?? '',
    hourlyBreakdown:     (j['hourly_breakdown'] as List? ?? [])
        .map((e) => HourlyExposure.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  /// Simulated data when API is unavailable
  static HealthExposureData simulated() => HealthExposureData(
    cigaretteEquivalent: 0.8,
    healthPointsDelta:   -12,
    whoCompliancePct:    68.0,
    compliantHours:      10,
    hoursMonitored:      14,
    lungLoadScore:       45,
    avgPm25Today:        28.3,
    exposureNarrative:
        "Today's exposure ≈ 0.8 cigarettes. WHO compliance 68%. Peak at 08:00 (Traffic Exhaust).",
    hourlyBreakdown: List.generate(14, (i) => HourlyExposure(
      hour: '${(7 + i).toString().padLeft(2, '0')}:00',
      pm25: 12.0 + math.sin(i * 0.7) * 22.0 + 15.0,
      source: i >= 1 && i <= 3 ? 'Traffic Exhaust' : 'Clean Baseline',
    )),
  );
}

class HourlyExposure {
  final String hour;
  final double pm25;
  final String source;

  const HourlyExposure({required this.hour, required this.pm25, required this.source});

  factory HourlyExposure.fromJson(Map<String, dynamic> j) => HourlyExposure(
    hour:   j['hour'] ?? '',
    pm25:   (j['pm25'] ?? 0).toDouble(),
    source: j['source'] ?? 'Unknown',
  );
}

class HealthExposureCard extends StatefulWidget {
  final HealthExposureData data;
  const HealthExposureCard({super.key, required this.data});

  @override
  State<HealthExposureCard> createState() => _HealthExposureCardState();
}

class _HealthExposureCardState extends State<HealthExposureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _progressAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _pm25ToColor(double pm25) {
    if (pm25 <= 15) return const Color(0xFF10B981);
    if (pm25 <= 35) return const Color(0xFF84CC16);
    if (pm25 <= 55) return const Color(0xFFEAB308);
    if (pm25 <= 75) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context).extension<AeroTheme>()!;
    final data     = widget.data;
    final lungLoad = data.lungLoadScore / 100.0;
    final hpNeg    = data.healthPointsDelta < 0;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.monitor_heart_rounded,
                  color: theme.accentCyan, size: 18),
              const SizedBox(width: 8),
              Text('Personal Health Exposure',
                  style: TextStyle(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hpNeg
                      ? theme.aqiVeryPoor.withValues(alpha: 0.2)
                      : theme.primaryEmerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hpNeg
                        ? theme.aqiVeryPoor.withValues(alpha: 0.6)
                        : theme.primaryEmerald.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  '${hpNeg ? "" : "+"}${data.healthPointsDelta} HP today',
                  style: TextStyle(
                    color: hpNeg ? theme.aqiVeryPoor : theme.primaryEmerald,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Main metrics row
          Row(
            children: [
              // Lung Load Gauge
              SizedBox(
                width: 90,
                height: 90,
                child: AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (_, _) => CustomPaint(
                    painter: _LungLoadPainter(
                      progress: lungLoad * _progressAnim.value,
                      theme: theme,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${data.lungLoadScore}',
                              style: TextStyle(
                                  color: theme.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          Text('%', style: TextStyle(
                              color: theme.textSecondary, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetricRow(
                      icon: '🚬',
                      label: 'Cigarette Equivalent',
                      value: '${data.cigaretteEquivalent.toStringAsFixed(1)} cigs',
                      valueColor: data.cigaretteEquivalent >= 2.0
                          ? theme.aqiVeryPoor
                          : data.cigaretteEquivalent >= 1.0
                              ? theme.aqiPoor
                              : theme.primaryEmerald,
                    ),
                    const SizedBox(height: 8),
                    _MetricRow(
                      icon: '✅',
                      label: 'WHO Compliance',
                      value: '${data.whoCompliancePct.toStringAsFixed(0)}%',
                      valueColor: data.whoCompliancePct >= 80
                          ? theme.primaryEmerald
                          : data.whoCompliancePct >= 60
                              ? theme.aqiModerate
                              : theme.aqiVeryPoor,
                    ),
                    const SizedBox(height: 8),
                    _MetricRow(
                      icon: '📊',
                      label: 'Avg PM2.5 Today',
                      value: '${data.avgPm25Today.toStringAsFixed(1)} µg/m³',
                      valueColor: theme.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Hourly bar chart
          if (data.hourlyBreakdown.isNotEmpty) ...[
            Text('Hourly PM2.5 Exposure',
                style: TextStyle(
                    color: theme.textSecondary, fontSize: 11,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            AnimatedBuilder(
              animation: _progressAnim,
              builder: (_, _) {
                final maxPm = data.hourlyBreakdown
                    .map((h) => h.pm25)
                    .fold(1.0, math.max);
                return SizedBox(
                  height: 40,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: data.hourlyBreakdown.map((h) {
                      final norm = (h.pm25 / maxPm) * _progressAnim.value;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Tooltip(
                            message:
                                '${h.hour}\nPM2.5: ${h.pm25.toStringAsFixed(1)} µg/m³\n${h.source}',
                            child: Container(
                              height: math.max(3, 40 * norm),
                              decoration: BoxDecoration(
                                color: _pm25ToColor(h.pm25),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 10),

          // Narrative
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.accentCyan.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: theme.accentCyan.withValues(alpha: 0.18)),
            ),
            child: Text(
              data.exposureNarrative,
              style: TextStyle(
                  color: theme.textSecondary, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color valueColor;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AeroTheme>()!;
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(label,
              style: TextStyle(color: theme.textSecondary, fontSize: 11)),
        ),
        Text(value,
            style: TextStyle(
                color: valueColor, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _LungLoadPainter extends CustomPainter {
  final double progress;
  final AeroTheme theme;

  _LungLoadPainter({required this.progress, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75, math.pi * 1.5, false,
      Paint()
        ..color = theme.textSecondary.withValues(alpha: 0.15)
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc (red when high, green when low)
    final color = progress > 0.7
        ? const Color(0xFFEF4444)
        : progress > 0.4
            ? const Color(0xFFF97316)
            : const Color(0xFF10B981);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75, math.pi * 1.5 * progress, false,
      Paint()
        ..color = color
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_LungLoadPainter old) => old.progress != progress;
}
