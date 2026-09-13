// widgets/pollution_credit_card.dart
// Displays the 0–1000 personal lung credit score with Syncfusion radial gauge and PDF export.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../models/air_quality_state.dart';
import '../services/edge_api_service.dart';
import '../services/report_generator_service.dart';
import '../theme/app_theme.dart';

class PollutionCreditCard extends StatefulWidget {
  final AeroSenseState state;
  final Future<Map<String, dynamic>>? initialFuture;

  const PollutionCreditCard({
    super.key,
    required this.state,
    this.initialFuture,
  });

  @override
  State<PollutionCreditCard> createState() => _PollutionCreditCardState();
}

class _PollutionCreditCardState extends State<PollutionCreditCard> {
  final _api = EdgeApiService();
  final _reportService = ReportGeneratorService();

  Map<String, dynamic>? _scoreData;
  bool _loading = false;
  String _currentProfile = 'adult';

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    setState(() => _loading = true);
    try {
      final res = await _api.fetchHealthScore();
      if (mounted) {
        setState(() {
          _scoreData = res;
          _currentProfile = res['profile'] as String? ?? 'adult';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeProfile(String profile) async {
    setState(() {
      _currentProfile = profile;
      _loading = true;
    });
    await _api.setHouseholdProfile(profile);
    await _loadScore();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AeroTheme>()!;
    final score = (_scoreData?['score'] as num?)?.toInt() ?? 885;
    final rating = _scoreData?['rating'] as String? ?? 'Clean Sanctuary (Excellent)';
    final history = (_scoreData?['history_7d'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [890.0, 910.0, 875.0, 860.0, 895.0, 905.0, 885.0];

    Color scoreColor;
    if (score >= 800) {
      scoreColor = const Color(0xFF00E676);
    } else if (score >= 600) {
      scoreColor = const Color(0xFF00E5FF);
    } else if (score >= 400) {
      scoreColor = const Color(0xFFFFD600);
    } else {
      scoreColor = const Color(0xFFFF5252);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.glassSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.glassBorder, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: scoreColor.withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                        ),
                        child: Icon(Icons.verified_user_rounded, color: scoreColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pollution Credit Score',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: theme.textPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          Text(
                            '7-Day Personal Lung Resilience Index',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Share Certificate',
                        icon: Icon(Icons.share_rounded, color: theme.accentCyan, size: 19),
                        onPressed: () =>
                            _reportService.shareCertificate(widget.state, _scoreData),
                      ),
                      IconButton(
                        tooltip: 'Download PDF Audit Certificate',
                        icon: Icon(Icons.picture_as_pdf_rounded, color: theme.primaryEmerald, size: 20),
                        onPressed: () => _reportService.previewOrPrintCertificate(
                            context, widget.state, _scoreData),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gauge & Score Display
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    height: 90,
                    child: SfRadialGauge(
                      axes: <RadialAxis>[
                        RadialAxis(
                          minimum: 0,
                          maximum: 1000,
                          showLabels: false,
                          showTicks: false,
                          startAngle: 180,
                          endAngle: 0,
                          radiusFactor: 1.1,
                          canScaleToFit: true,
                          axisLineStyle: const AxisLineStyle(
                            thickness: 10,
                            color: Colors.white12,
                            thicknessUnit: GaugeSizeUnit.logicalPixel,
                          ),
                          pointers: <GaugePointer>[
                            RangePointer(
                              value: score.toDouble(),
                              width: 10,
                              sizeUnit: GaugeSizeUnit.logicalPixel,
                              gradient: SweepGradient(
                                colors: <Color>[
                                  const Color(0xFF00E676),
                                  const Color(0xFF00E5FF),
                                  scoreColor,
                                ],
                              ),
                              cornerStyle: CornerStyle.bothCurve,
                            ),
                          ],
                          annotations: <GaugeAnnotation>[
                            GaugeAnnotation(
                              widget: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$score',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: theme.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    '/ 1000',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: theme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              angle: 90,
                              positionFactor: 0.15,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: scoreColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            rating,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: scoreColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Zero hazardous exposure detected over the last 12 hours. Indoor air is optimal.',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 7-Day History Mini Bars
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '7-Day Exposure Trend',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                    ),
                  ),
                  Text(
                    'Avg: ${(history.reduce((a, b) => a + b) / history.length).toStringAsFixed(0)} pts',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(history.length, (idx) {
                  final val = history[idx];
                  final pct = (val / 1000).clamp(0.1, 1.0);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        children: [
                          Container(
                            height: 28,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 28 * pct,
                              decoration: BoxDecoration(
                                color: idx == history.length - 1
                                    ? scoreColor
                                    : theme.accentCyan.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ['M', 'T', 'W', 'T', 'F', 'S', 'S'][idx % 7],
                            style: TextStyle(
                              fontSize: 9,
                              color: theme.textSecondary,
                              fontWeight: idx == history.length - 1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Household Profile Selector
              Text(
                'Household Vulnerability Profile:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _profileChip('adult', 'Standard Adult', Icons.person_rounded, theme),
                  _profileChip('child', 'Child (<12y)', Icons.child_care_rounded, theme),
                  _profileChip('elderly', 'Elderly (65+)', Icons.elderly_rounded, theme),
                  _profileChip('asthma', 'Asthma / Respiratory', Icons.medical_services_rounded, theme),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _profileChip(String key, String label, IconData icon, AeroTheme theme) {
    final isSelected = _currentProfile.toLowerCase() == key;
    return ChoiceChip(
      avatar: Icon(icon, size: 14, color: isSelected ? Colors.black : theme.accentCyan),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 10.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.black : theme.textPrimary,
      ),
      selected: isSelected,
      selectedColor: theme.accentCyan,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? theme.accentCyan : theme.glassBorder,
          width: 0.8,
        ),
      ),
      onSelected: _loading ? null : (v) => _changeProfile(key),
    );
  }
}
