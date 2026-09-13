// widgets/compliance_streak_card.dart
// Feature 4: WHO Compliance Streak & Zone Leaderboard
// Flame streak counter + 30-day calendar heatmap

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class ComplianceStreakData {
  final int currentStreakDays;
  final int longestStreakDays;
  final bool todayCompliant;
  final double todayAvgPm25;
  final String lastBreachDate;
  final List<String> streakBadges;
  final List<DayCalendar> dailyCalendar;

  const ComplianceStreakData({
    this.currentStreakDays = 0,
    this.longestStreakDays = 0,
    this.todayCompliant = false,
    this.todayAvgPm25 = 0.0,
    this.lastBreachDate = '',
    this.streakBadges = const [],
    this.dailyCalendar = const [],
  });

  factory ComplianceStreakData.fromJson(Map<String, dynamic> j) => ComplianceStreakData(
    currentStreakDays: j['current_streak_days'] ?? 0,
    longestStreakDays: j['longest_streak_days'] ?? 0,
    todayCompliant:    j['today_compliant'] ?? false,
    todayAvgPm25:      (j['today_avg_pm25'] ?? 0).toDouble(),
    lastBreachDate:    j['last_breach_date'] ?? '',
    streakBadges:      List<String>.from(j['streak_badges'] ?? []),
    dailyCalendar:     (j['daily_calendar'] as List? ?? [])
        .map((e) => DayCalendar.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  static ComplianceStreakData simulated() => ComplianceStreakData(
    currentStreakDays: 7,
    longestStreakDays: 12,
    todayCompliant:    true,
    todayAvgPm25:      11.2,
    lastBreachDate:    '2026-09-04',
    streakBadges:      ['🟢 Active Green Streak', '✨ 3-Day Clean Air Run', '🔥 7-Day WHO Compliant Week'],
    dailyCalendar:     List.generate(30, (i) {
      final compliant = i > 7 || (i >= 3 && i <= 5) ? false : true;
      return DayCalendar(
        date: DateTime.now().subtract(Duration(days: 29 - i)).toIso8601String().substring(0, 10),
        avgPm25: compliant ? 10.0 + math.Random(i).nextDouble() * 4 : 20.0 + math.Random(i).nextDouble() * 20,
        avgAqi: compliant ? 35 + (math.Random(i).nextInt(20)) : 80 + math.Random(i).nextInt(80),
        compliant: compliant,
      );
    }),
  );
}

class DayCalendar {
  final String date;
  final double avgPm25;
  final int avgAqi;
  final bool compliant;

  const DayCalendar({this.date = '', this.avgPm25 = 0, this.avgAqi = 0, this.compliant = false});

  factory DayCalendar.fromJson(Map<String, dynamic> j) => DayCalendar(
    date:      j['date'] ?? '',
    avgPm25:   (j['avg_pm25'] ?? 0).toDouble(),
    avgAqi:    (j['avg_aqi'] ?? 0).toInt(),
    compliant: j['compliant'] ?? false,
  );
}

class ComplianceStreakCard extends StatefulWidget {
  final ComplianceStreakData data;
  const ComplianceStreakCard({super.key, required this.data});
  @override
  State<ComplianceStreakCard> createState() => _ComplianceStreakCardState();
}

class _ComplianceStreakCardState extends State<ComplianceStreakCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _flame;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _flame = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Icon(Icons.local_fire_department_rounded,
                color: const Color(0xFFF97316), size: 18),
            const SizedBox(width: 8),
            Text('WHO Compliance Streak',
                style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: data.todayCompliant
                    ? theme.primaryEmerald.withValues(alpha: 0.15)
                    : theme.aqiVeryPoor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: data.todayCompliant
                      ? theme.primaryEmerald.withValues(alpha: 0.5)
                      : theme.aqiVeryPoor.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                data.todayCompliant ? '✅ Today Compliant' : '❌ Non-Compliant',
                style: TextStyle(
                    color: data.todayCompliant ? theme.primaryEmerald : theme.aqiVeryPoor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // Streak counter row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StreakCounter(
                value: data.currentStreakDays,
                label: 'Current Streak',
                icon: '🔥',
                flameAnim: _flame,
                color: const Color(0xFFF97316),
                theme: theme,
              ),
              Container(width: 1, height: 48, color: theme.textSecondary.withValues(alpha: 0.2)),
              _StreakCounter(
                value: data.longestStreakDays,
                label: 'Best Streak',
                icon: '🏆',
                flameAnim: null,
                color: const Color(0xFFEAB308),
                theme: theme,
              ),
              Container(width: 1, height: 48, color: theme.textSecondary.withValues(alpha: 0.2)),
              Column(
                children: [
                  Text(data.todayAvgPm25.toStringAsFixed(1),
                      style: TextStyle(
                          color: data.todayAvgPm25 <= 15
                              ? theme.primaryEmerald
                              : theme.aqiVeryPoor,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                  Text('µg/m³ today',
                      style: TextStyle(color: theme.textSecondary, fontSize: 10)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Badges
          if (data.streakBadges.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: data.streakBadges.map((badge) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.accentCyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.accentCyan.withValues(alpha: 0.25)),
                ),
                child: Text(badge,
                    style: TextStyle(
                        color: theme.textSecondary, fontSize: 10)),
              )).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // 30-day calendar heatmap
          Text('30-Day Compliance Calendar',
              style: TextStyle(color: theme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _CalendarHeatmap(calendar: data.dailyCalendar, theme: theme),

          if (data.lastBreachDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Last breach: ${data.lastBreachDate}',
                style: TextStyle(color: theme.textSecondary.withValues(alpha: 0.6), fontSize: 10)),
          ],
        ],
      ),
    );
  }
}

class _StreakCounter extends StatelessWidget {
  final int value;
  final String label, icon;
  final Animation<double>? flameAnim;
  final Color color;
  final AeroTheme theme;

  const _StreakCounter({
    required this.value, required this.label, required this.icon,
    required this.flameAnim, required this.color, required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final child = Column(children: [
      Text(icon, style: const TextStyle(fontSize: 20)),
      Text('$value',
          style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w800)),
      Text('days', style: TextStyle(color: theme.textSecondary, fontSize: 10)),
      Text(label, style: TextStyle(color: theme.textSecondary, fontSize: 9)),
    ]);

    if (flameAnim != null) {
      return AnimatedBuilder(
        animation: flameAnim!,
        builder: (_, _) => Transform.scale(scale: flameAnim!.value, child: child),
      );
    }
    return child;
  }
}

class _CalendarHeatmap extends StatelessWidget {
  final List<DayCalendar> calendar;
  final AeroTheme theme;

  const _CalendarHeatmap({required this.calendar, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: calendar.map((day) {
        final color = day.compliant
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444);
        final parts = day.date.split('-');
        final d = parts.length == 3 ? parts[2] : '?';
        return Tooltip(
          message: '${day.date}\nPM2.5: ${day.avgPm25.toStringAsFixed(1)} µg/m³\nAQI: ${day.avgAqi}\n${day.compliant ? "✅ WHO Compliant" : "❌ Non-Compliant"}',
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: day.compliant ? 0.7 : 0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(d,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 8,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
