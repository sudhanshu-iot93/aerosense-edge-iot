// widgets/safe_window_planner.dart
// Feature 2: Predictive Safe Window Activity Planner
// 24-hour color ribbon + activity-specific safe time slot recommendations

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class SafeWindowData {
  final String generatedAt;
  final List<ActivityWindow> windows;
  final WorstWindow worstWindow;
  final List<RibbonSlot> ribbon;

  const SafeWindowData({
    this.generatedAt = '',
    this.windows = const [],
    this.worstWindow = const WorstWindow(),
    this.ribbon = const [],
  });

  factory SafeWindowData.fromJson(Map<String, dynamic> j) {
    final rawWindows = j['windows'];
    final rawWorst = j['worst_window'];
    final rawRibbon = j['ribbon'];

    // Gracefully fallback to rich simulation if lists are empty or null
    if ((rawWindows == null || (rawWindows is List && rawWindows.isEmpty)) &&
        (rawRibbon == null || (rawRibbon is List && rawRibbon.isEmpty))) {
      return SafeWindowData.simulated();
    }

    return SafeWindowData(
      generatedAt: j['generated_at']?.toString() ?? '',
      windows: (rawWindows as List? ?? [])
          .whereType<Map>()
          .map((e) => ActivityWindow.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      worstWindow: rawWorst is Map
          ? WorstWindow.fromJson(Map<String, dynamic>.from(rawWorst))
          : const WorstWindow(),
      ribbon: (rawRibbon as List? ?? [])
          .whereType<Map>()
          .map((e) => RibbonSlot.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  static SafeWindowData simulated() {
    final now = DateTime.now();
    return SafeWindowData(
      generatedAt: now.toIso8601String(),
      windows: [
        ActivityWindow(activity: 'Outdoor Jogging', emoji: '🏃', fromTime: '13:00', toTime: '15:30', durationMin: 150, avgPredictedAqi: 48, confidence: 'HIGH', reason: 'Solar heating disperses pollution vertically'),
        ActivityWindow(activity: "Children's Outdoor Play", emoji: '🧒', fromTime: '14:00', toTime: '16:00', durationMin: 120, avgPredictedAqi: 42, confidence: 'HIGH', reason: 'Best afternoon dispersion window'),
        ActivityWindow(activity: 'Open Windows / Ventilation', emoji: '🪟', fromTime: '13:30', toTime: '16:00', durationMin: 150, avgPredictedAqi: 44, confidence: 'MEDIUM', reason: 'Afternoon cross-ventilation ideal'),
        ActivityWindow(activity: 'Cycling / E-Bike', emoji: '🚴', fromTime: '13:00', toTime: '15:00', durationMin: 120, avgPredictedAqi: 51, confidence: 'MEDIUM', reason: 'Moderate conditions, use N95 on longer rides'),
      ],
      worstWindow: const WorstWindow(from: '08:00', peakAqi: 168, reason: 'Morning traffic inversion traps soot near ground'),
      ribbon: List.generate(24, (i) {
        final h = (now.hour + i) % 24;
        final aqi = 50 + (h >= 7 && h <= 9 ? 120 : h >= 13 && h <= 16 ? -20 : h >= 18 && h <= 20 ? 80 : 0).toInt() + (i * 2 % 20);
        final color = aqi <= 50 ? '#10B981' : aqi <= 100 ? '#84CC16' : aqi <= 150 ? '#EAB308' : aqi <= 200 ? '#F97316' : '#EF4444';
        return RibbonSlot(hour: '${h.toString().padLeft(2, '0')}:00', predictedAqi: aqi.clamp(10, 350), color: color, label: aqi <= 50 ? 'Good' : aqi <= 100 ? 'Moderate' : 'Unhealthy');
      }),
    );
  }
}

class ActivityWindow {
  final String activity, emoji, fromTime, toTime, confidence, reason;
  final int durationMin, avgPredictedAqi;
  const ActivityWindow({this.activity='', this.emoji='🏃', this.fromTime='', this.toTime='', this.durationMin=0, this.avgPredictedAqi=50, this.confidence='', this.reason=''});
  factory ActivityWindow.fromJson(Map<String, dynamic> j) => ActivityWindow(
    activity: j['activity']?.toString() ?? '',
    emoji: j['emoji']?.toString() ?? '🏃',
    fromTime: j['from_time']?.toString() ?? '',
    toTime: j['to_time']?.toString() ?? '',
    durationMin: (j['duration_min'] as num?)?.toInt() ?? 0,
    avgPredictedAqi: (j['avg_predicted_aqi'] as num?)?.toInt() ?? 50,
    confidence: j['confidence']?.toString() ?? '',
    reason: j['reason']?.toString() ?? '',
  );
}

class WorstWindow {
  final String from, reason;
  final int peakAqi;
  const WorstWindow({this.from='', this.peakAqi=0, this.reason=''});
  factory WorstWindow.fromJson(Map<String, dynamic> j) => WorstWindow(
    from: j['from']?.toString() ?? '',
    peakAqi: (j['peak_aqi'] as num?)?.toInt() ?? 0,
    reason: j['reason']?.toString() ?? '',
  );
}

class RibbonSlot {
  final String hour, color, label;
  final int predictedAqi;
  const RibbonSlot({this.hour='', this.predictedAqi=50, this.color='#10B981', this.label='Good'});
  factory RibbonSlot.fromJson(Map<String, dynamic> j) => RibbonSlot(
    hour: j['hour']?.toString() ?? '',
    predictedAqi: (j['predicted_aqi'] as num?)?.toInt() ?? 50,
    color: j['color']?.toString() ?? '#10B981',
    label: j['label']?.toString() ?? 'Good',
  );
}

Color _hex(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

class SafeWindowPlanner extends StatefulWidget {
  final SafeWindowData data;
  const SafeWindowPlanner({super.key, required this.data});
  @override
  State<SafeWindowPlanner> createState() => _SafeWindowPlannerState();
}

class _SafeWindowPlannerState extends State<SafeWindowPlanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  int _selectedSlot = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AeroTheme>()!;
    final data  = widget.data;
    final now   = DateTime.now().hour;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: FadeTransition(
        opacity: _fade,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Icon(Icons.schedule_rounded, color: theme.accentCyan, size: 18),
              const SizedBox(width: 8),
              Text('Safe Activity Planner',
                  style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.primaryEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.primaryEmerald.withValues(alpha: 0.4)),
                ),
                child: Text('Next 24h', style: TextStyle(color: theme.primaryEmerald, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ]),

            const SizedBox(height: 14),

            // 24-hour AQI ribbon
            Text('24-Hour AQI Forecast Ribbon',
                style: TextStyle(color: theme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: data.ribbon.length,
                itemBuilder: (_, i) {
                  final slot = data.ribbon[i];
                  final isNow = slot.hour.startsWith(now.toString().padLeft(2, '0'));
                  final isSelected = i == _selectedSlot;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSlot = isSelected ? -1 : i),
                    child: Tooltip(
                      message: '${slot.hour}\nAQI ${slot.predictedAqi}\n${slot.label}',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 30 : 22,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: _hex(slot.color).withValues(alpha: isSelected ? 1.0 : 0.75),
                          borderRadius: BorderRadius.circular(4),
                          border: isNow ? Border.all(color: Colors.white, width: 1.5) : null,
                        ),
                        child: Center(
                          child: isNow
                              ? const Icon(Icons.arrow_drop_up_rounded, size: 14, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_selectedSlot >= 0 && _selectedSlot < data.ribbon.length) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _hex(data.ribbon[_selectedSlot].color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _hex(data.ribbon[_selectedSlot].color).withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  Text(data.ribbon[_selectedSlot].hour, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(width: 8),
                  Text('AQI ${data.ribbon[_selectedSlot].predictedAqi} · ${data.ribbon[_selectedSlot].label}',
                      style: TextStyle(color: theme.textSecondary, fontSize: 11)),
                ]),
              ),
            ],

            const SizedBox(height: 14),

            // Activity windows
            Text('Best Times for Activities',
                style: TextStyle(color: theme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ...data.windows.take(4).map((w) => _ActivityWindowTile(window: w, theme: theme)),

            if (data.worstWindow.peakAqi > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
                ),
                child: Row(children: [
                  const Text('⚠️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Worst Window: ${data.worstWindow.from}',
                        style: TextStyle(color: const Color(0xFFEF4444), fontWeight: FontWeight.w700, fontSize: 12)),
                    Text('Peak AQI ${data.worstWindow.peakAqi} · ${data.worstWindow.reason}',
                        style: TextStyle(color: theme.textSecondary, fontSize: 11)),
                  ])),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityWindowTile extends StatelessWidget {
  final ActivityWindow window;
  final AeroTheme theme;
  const _ActivityWindowTile({required this.window, required this.theme});

  Color get _aqiColor {
    final a = window.avgPredictedAqi;
    if (a <= 50) return const Color(0xFF10B981);
    if (a <= 80) return const Color(0xFF84CC16);
    if (a <= 100) return const Color(0xFFEAB308);
    return const Color(0xFFF97316);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _aqiColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _aqiColor.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Text(window.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(window.activity,
                style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
            Text('${window.fromTime} – ${window.toTime} · ${window.reason}',
                style: TextStyle(color: theme.textSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('AQI ${window.avgPredictedAqi}',
                style: TextStyle(color: _aqiColor, fontWeight: FontWeight.w800, fontSize: 12)),
            Text(window.confidence,
                style: TextStyle(color: theme.textSecondary, fontSize: 9)),
          ]),
        ]),
      ),
    );
  }
}
