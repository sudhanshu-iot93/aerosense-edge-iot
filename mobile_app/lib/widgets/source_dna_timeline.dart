// widgets/source_dna_timeline.dart
// Feature 3: Pollution Source DNA Timeline
// Scrollable 24h horizontal timeline showing which source dominated each hour

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class SourceTimelineData {
  final List<TimelineSlot> timeline;
  final Map<String, int> sourceDistribution;
  final TimelineSlot? cleanestHour;
  final TimelineSlot? worstHour;
  final int hoursQueried;

  const SourceTimelineData({
    this.timeline = const [],
    this.sourceDistribution = const {},
    this.cleanestHour,
    this.worstHour,
    this.hoursQueried = 24,
  });

  factory SourceTimelineData.fromJson(Map<String, dynamic> j) {
    final rawTimeline = j['timeline'];
    if (rawTimeline == null || (rawTimeline is List && rawTimeline.isEmpty)) {
      return SourceTimelineData.simulated();
    }
    return SourceTimelineData(
      timeline: (rawTimeline as List)
          .whereType<Map>()
          .map((e) => TimelineSlot.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      sourceDistribution: Map<String, int>.from(
          (j['source_distribution'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toInt()))),
      cleanestHour: j['cleanest_hour'] != null && j['cleanest_hour'] is Map
          ? TimelineSlot.fromJson(Map<String, dynamic>.from(j['cleanest_hour'] as Map))
          : null,
      worstHour: j['worst_hour'] != null && j['worst_hour'] is Map
          ? TimelineSlot.fromJson(Map<String, dynamic>.from(j['worst_hour'] as Map))
          : null,
      hoursQueried: (j['hours_queried'] as num?)?.toInt() ?? 24,
    );
  }

  static SourceTimelineData simulated() {
    final now = DateTime.now().hour;
    const sources = [
      ('Clean Baseline', '🌿', '#10B981', 32),
      ('Traffic Exhaust', '🚗', '#F97316', 155),
      ('Clean Baseline', '🌿', '#10B981', 45),
      ('Cooking Smoke', '🍳', '#8B5CF6', 88),
      ('Construction Dust', '🏗️', '#EAB308', 112),
      ('Garbage Burning', '🔥', '#EF4444', 210),
      ('Clean Baseline', '🌿', '#10B981', 38),
    ];
    return SourceTimelineData(
      timeline: List.generate(14, (i) {
        final s = sources[i % sources.length];
        final hour = (now - 13 + i + 24) % 24;
        return TimelineSlot(
          hour: '${hour.toString().padLeft(2, '0')}:00',
          source: s.$1, emoji: s.$2, color: s.$3,
          avgAqi: s.$4, avgPm25: s.$4 / 2.1,
        );
      }),
      sourceDistribution: const {
        'Clean Baseline': 8, 'Traffic Exhaust': 3,
        'Cooking Smoke': 1, 'Construction Dust': 1, 'Garbage Burning': 1,
      },
    );
  }
}

class TimelineSlot {
  final String hour, source, emoji, color;
  final int avgAqi;
  final double avgPm25;

  const TimelineSlot({
    this.hour = '', this.source = '', this.emoji = '🌿',
    this.color = '#10B981', this.avgAqi = 50, this.avgPm25 = 15.0,
  });

  factory TimelineSlot.fromJson(Map<String, dynamic> j) => TimelineSlot(
    hour:    j['hour'] ?? '',
    source:  j['source'] ?? 'Clean Baseline',
    emoji:   j['emoji'] ?? '🌿',
    color:   j['color'] ?? '#10B981',
    avgAqi:  (j['avg_aqi'] ?? 50).toInt(),
    avgPm25: (j['avg_pm25'] ?? 15.0).toDouble(),
  );
}

Color _hex(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

class SourceDnaTimeline extends StatefulWidget {
  final SourceTimelineData data;
  const SourceDnaTimeline({super.key, required this.data});
  @override
  State<SourceDnaTimeline> createState() => _SourceDnaTimelineState();
}

class _SourceDnaTimelineState extends State<SourceDnaTimeline>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _selectedSlot = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AeroTheme>()!;
    final data  = widget.data;
    final total = data.sourceDistribution.values.fold(0, (a, b) => a + b);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Icon(Icons.timeline_rounded, color: theme.accentCyan, size: 18),
            const SizedBox(width: 8),
            Text('Pollution Source Timeline',
                style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
            const Spacer(),
            Text('Last ${data.hoursQueried}h',
                style: TextStyle(color: theme.textSecondary, fontSize: 11)),
          ]),

          const SizedBox(height: 14),

          // DNA strand timeline - scrollable horizontal blocks
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: data.timeline.length,
              itemBuilder: (_, i) {
                final slot = data.timeline[i];
                final isSelected = _selectedSlot == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSlot = isSelected ? -1 : i),
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, _) {
                      final progress = (_ctrl.value - i * 0.04).clamp(0.0, 1.0);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 58 : 46,
                        height: 64,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: _hex(slot.color).withValues(alpha: 0.15 + 0.6 * progress),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.7)
                                : _hex(slot.color).withValues(alpha: 0.4),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(slot.emoji, style: TextStyle(fontSize: isSelected ? 20 : 16)),
                            const SizedBox(height: 2),
                            Text(slot.hour,
                                style: TextStyle(
                                    color: theme.textSecondary,
                                    fontSize: isSelected ? 10 : 9,
                                    fontWeight: FontWeight.w500)),
                            if (isSelected) ...[
                              Text('${slot.avgAqi}',
                                  style: TextStyle(
                                      color: _hex(slot.color),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Selected slot detail
          if (_selectedSlot >= 0 && _selectedSlot < data.timeline.length) ...[
            const SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _hex(data.timeline[_selectedSlot].color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _hex(data.timeline[_selectedSlot].color).withValues(alpha: 0.35)),
                ),
                child: Row(children: [
                  Text(data.timeline[_selectedSlot].emoji,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(data.timeline[_selectedSlot].source,
                        style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(
                        '${data.timeline[_selectedSlot].hour}  •  AQI ${data.timeline[_selectedSlot].avgAqi}  •  PM2.5 ${data.timeline[_selectedSlot].avgPm25.toStringAsFixed(1)} µg/m³',
                        style: TextStyle(color: theme.textSecondary, fontSize: 11)),
                  ]),
                ]),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Source composition pie-equivalent (horizontal bar)
          Text("Today's Source Composition",
              style: TextStyle(color: theme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 14,
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, _) => Row(
                    children: data.sourceDistribution.entries.map((e) {
                      final frac = e.value / total;
                      final color = _sourceColor(e.key);
                      return Expanded(
                        flex: (frac * 100).round(),
                        child: Tooltip(
                          message: '${e.key}: ${e.value}h',
                          child: Container(
                            color: color.withValues(alpha: 0.7 + 0.3 * _ctrl.value),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Legend
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: data.sourceDistribution.entries.map((e) {
              final color = _sourceColor(e.key);
              final pct = total > 0 ? (e.value / total * 100).round() : 0;
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 4),
                Text('${e.key} ($pct%)',
                    style: TextStyle(color: theme.textSecondary, fontSize: 10)),
              ]);
            }).toList(),
          ),

          if (data.cleanestHour != null || data.worstHour != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              if (data.cleanestHour != null)
                _BadgePill(
                    emoji: '🌿',
                    label: 'Cleanest: ${data.cleanestHour!.hour} (AQI ${data.cleanestHour!.avgAqi})',
                    color: const Color(0xFF10B981),
                    theme: theme),
              const SizedBox(width: 8),
              if (data.worstHour != null)
                _BadgePill(
                    emoji: '🔴',
                    label: 'Worst: ${data.worstHour!.hour} (AQI ${data.worstHour!.avgAqi})',
                    color: const Color(0xFFEF4444),
                    theme: theme),
            ]),
          ],
        ],
      ),
    );
  }

  Color _sourceColor(String source) {
    const map = {
      'Clean Baseline':    Color(0xFF10B981),
      'Traffic Exhaust':   Color(0xFFF97316),
      'Garbage Burning':   Color(0xFFEF4444),
      'Construction Dust': Color(0xFFEAB308),
      'Cooking Smoke':     Color(0xFF8B5CF6),
      'Crop Residue':      Color(0xFFDC2626),
    };
    return map[source] ?? const Color(0xFF6B7280);
  }
}

class _BadgePill extends StatelessWidget {
  final String emoji, label;
  final Color color;
  final AeroTheme theme;
  const _BadgePill({required this.emoji, required this.label, required this.color, required this.theme});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text('$emoji $label',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}
