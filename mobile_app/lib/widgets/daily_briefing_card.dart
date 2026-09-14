// widgets/daily_briefing_card.dart
// Feature 5: Smart AI Daily Briefing Generator
// Morning/evening contextual briefing with risk level and key actions

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class DailyBriefingData {
  final String type;
  final String headline;
  final String briefingText;
  final List<String> keyActions;
  final String riskLevel;
  final String riskEmoji;
  final int currentAqi;
  final String currentSource;
  final String forecastTrend;
  final String? communityAlert;
  final String generatedAt;

  const DailyBriefingData({
    this.type = 'MORNING',
    this.headline = '',
    this.briefingText = '',
    this.keyActions = const [],
    this.riskLevel = 'LOW',
    this.riskEmoji = '✅',
    this.currentAqi = 50,
    this.currentSource = 'Clean Baseline',
    this.forecastTrend = 'STABLE',
    this.communityAlert,
    this.generatedAt = '',
  });

  factory DailyBriefingData.fromJson(Map<String, dynamic> j) => DailyBriefingData(
    type:           j['type'] ?? 'MORNING',
    headline:       j['headline'] ?? '',
    briefingText:   j['briefing_text'] ?? '',
    keyActions:     List<String>.from(j['key_actions'] ?? []),
    riskLevel:      j['risk_level'] ?? 'LOW',
    riskEmoji:      j['risk_emoji'] ?? '✅',
    currentAqi:     (j['current_aqi'] ?? 50).toInt(),
    currentSource:  j['current_source'] ?? 'Clean Baseline',
    forecastTrend:  j['forecast_trend'] ?? 'STABLE',
    communityAlert: j['community_alert'],
    generatedAt:    j['generated_at'] ?? '',
  );

  static DailyBriefingData simulated() => DailyBriefingData(
    type: 'MORNING',
    headline: 'Good morning! Clean air today — AQI 38. Perfect conditions for outdoor activities.',
    briefingText: 'Air quality is pristine this morning at AQI 38 (PM2.5: 12.1 µg/m³). Today is an excellent day for outdoor sports, open-window ventilation, and school recess. Conditions are expected to remain stable.',
    keyActions: [
      '🏃 Ideal conditions for outdoor jogging and sports all morning',
      '🪟 Open windows for maximum natural cross-ventilation',
      '🏫 Outdoor school recess and PT fully approved — no restrictions',
      '🌿 Great day to air out indoor spaces and mattresses',
    ],
    riskLevel: 'LOW',
    riskEmoji: '✅',
    currentAqi: 38,
    currentSource: 'Clean Baseline',
    forecastTrend: 'STABLE',
    communityAlert: null,
    generatedAt: DateTime.now().toIso8601String(),
  );

  bool get isMorning => type == 'MORNING';
}

Color _riskColor(String riskLevel) {
  switch (riskLevel) {
    case 'LOW':      return const Color(0xFF10B981);
    case 'MODERATE': return const Color(0xFF84CC16);
    case 'ELEVATED': return const Color(0xFFEAB308);
    case 'HIGH':     return const Color(0xFFF97316);
    case 'SEVERE':   return const Color(0xFFEF4444);
    case 'HAZARDOUS':return const Color(0xFF7C3AED);
    default:         return const Color(0xFF10B981);
  }
}

class DailyBriefingCard extends StatefulWidget {
  final DailyBriefingData data;
  final VoidCallback? onOpenFullAdvisory;
  const DailyBriefingCard({super.key, required this.data, this.onOpenFullAdvisory});
  @override
  State<DailyBriefingCard> createState() => _DailyBriefingCardState();
}

class _DailyBriefingCardState extends State<DailyBriefingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context).extension<AeroTheme>()!;
    final data   = widget.data;
    final color  = _riskColor(data.riskLevel);
    final isAM   = data.isMorning;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Gradient header strip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.25),
                      theme.cardBg.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(children: [
                  Text(isAM ? '🌅' : '🌙', style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(isAM ? 'Morning Briefing' : 'Evening Summary',
                          style: TextStyle(color: theme.textSecondary, fontSize: 11)),
                      Text(data.generatedAt.length >= 16
                          ? data.generatedAt.substring(11, 16)
                          : '',
                          style: TextStyle(color: theme.textSecondary.withValues(alpha: 0.6), fontSize: 10)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Text('${data.riskEmoji} ${data.riskLevel}',
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Community alert banner (if any)
                    if (data.communityAlert != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
                        ),
                        child: Text(data.communityAlert!,
                            style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Headline
                    Text(data.headline,
                        style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.4)),

                    const SizedBox(height: 8),

                    // Briefing text (collapsible)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Text(
                        data.briefingText,
                        maxLines: _expanded ? null : 2,
                        overflow: _expanded ? null : TextOverflow.ellipsis,
                        style: TextStyle(
                            color: theme.textSecondary, fontSize: 11, height: 1.5),
                      ),
                    ),

                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Text(
                        _expanded ? 'Show less ▲' : 'Read full briefing ▼',
                        style: TextStyle(
                            color: theme.accentCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Key actions
                    Text('Key Actions',
                        style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ...data.keyActions.map((action) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(action,
                                style: TextStyle(
                                    color: theme.textSecondary,
                                    fontSize: 11,
                                    height: 1.4)),
                          ),
                        ],
                      ),
                    )),
                    if (widget.onOpenFullAdvisory != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: widget.onOpenFullAdvisory,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: color.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Full Advisory',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: color),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
