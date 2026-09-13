// screens/desktop_dashboard_view.dart
// Production-grade widescreen workstation view for Windows desktop

import 'package:flutter/material.dart';
import '../models/air_quality_state.dart';
import '../theme/app_theme.dart';
import '../widgets/aqi_radial_gauge.dart';
import '../widgets/source_attribution_card.dart';
import '../widgets/forecast_card.dart';
import '../widgets/quick_stat_chip.dart';
import '../widgets/aqi_history_chart.dart';
import '../widgets/glass_card.dart';
import '../widgets/judge_test_drive_bar.dart';
import '../widgets/ai_benchmark_card.dart';
import '../widgets/incident_report_dialog.dart';

class DesktopDashboardView extends StatelessWidget {
  final AeroSenseState state;
  final Function(String) onScenarioChange;
  final Future<void> Function() onRefresh;

  const DesktopDashboardView({
    super.key,
    required this.state,
    required this.onScenarioChange,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final aqi = state.features.aqi;
    final aqiColor = AeroTheme.getAqiColor(aqi);
    final tel = state.telemetry;
    final themeExt = Theme.of(context).extension<AeroTheme>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Station Banner & Device Status ────────────────────────────────
          _buildDesktopHeader(context, aqiColor, themeExt),
          const SizedBox(height: 10),

          // ── Judge Test Drive Preset Bar ────────────────────────────────────
          JudgeTestDriveBar(
            activeScenario: state.activeScenario,
            onScenarioChange: onScenarioChange,
            onOpenIncidentReport: () => IncidentReportDialog.show(context, state),
          ),
          const SizedBox(height: 16),

          // ── Urgent alert if present ─────────────────────────────────────────
          if (state.advisory.urgentAlerts.isNotEmpty) ...[
            _buildUrgentAlert(state.advisory.urgentAlerts.first, themeExt),
            const SizedBox(height: 20),
          ],

          // ── Multi-Column Desktop Workstation Grid ──────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1050) {
                // Wide Screen: Dual Columns
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Real-time Telemetry & Intelligence
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AqiRadialGauge(
                            aqi: aqi,
                            aqiCategory: state.features.aqiCategory,
                            primaryPollutant: state.features.primaryPollutant,
                          ),
                          const SizedBox(height: 18),
                          _buildDesktopQuickStats(context, tel, aqi, themeExt),
                          const SizedBox(height: 18),
                          SourceAttributionCard(
                            attribution: state.sourceAttribution,
                            features: state.features,
                          ),
                          const SizedBox(height: 18),
                          AiBenchmarkCard(benchmark: state.sourceAttribution.aiBenchmark),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right Column: Predictive Analytics & Advisories
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AqiHistoryChart(forecast: state.forecast),
                          const SizedBox(height: 18),
                          ForecastCard(forecast: state.forecast),
                          const SizedBox(height: 18),
                          _buildDesktopActionCard(context, state, aqiColor, themeExt),
                          const SizedBox(height: 18),
                          _buildMeshOverviewCard(context, state, themeExt),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // Compact Desktop Layout: Single Column Stack
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AqiRadialGauge(
                      aqi: aqi,
                      aqiCategory: state.features.aqiCategory,
                      primaryPollutant: state.features.primaryPollutant,
                    ),
                    const SizedBox(height: 16),
                    _buildDesktopQuickStats(context, tel, aqi, themeExt),
                    const SizedBox(height: 16),
                    SourceAttributionCard(
                      attribution: state.sourceAttribution,
                      features: state.features,
                    ),
                    const SizedBox(height: 16),
                    AqiHistoryChart(forecast: state.forecast),
                    const SizedBox(height: 16),
                    ForecastCard(forecast: state.forecast),
                    const SizedBox(height: 16),
                    _buildDesktopActionCard(context, state, aqiColor, themeExt),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DESKTOP HEADER BANNER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktopHeader(
      BuildContext context, Color aqiColor, AeroTheme themeExt) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: aqiColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: aqiColor.withValues(alpha: 0.35)),
            ),
            child: Icon(Icons.hub_rounded, color: aqiColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AeroSense Node #01',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: themeExt.textPrimary,
                        letterSpacing: -0.02,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: themeExt.primaryEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: themeExt.primaryEmerald.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'ARDUINO UNO Q',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: themeExt.primaryEmerald,
                          letterSpacing: 0.04,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Qualcomm QRB2210 Quad-Core A53 Linux + STM32U585 Real-Time MCU',
                  style: TextStyle(
                    fontSize: 12,
                    color: themeExt.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // System metrics chips
          Row(
            children: [
              _desktopStatusPill(
                icon: Icons.cloud_off_rounded,
                label: 'Cloud: 0% Offline',
                color: themeExt.primaryEmerald,
                themeExt: themeExt,
              ),
              const SizedBox(width: 10),
              _desktopStatusPill(
                icon: Icons.speed_rounded,
                label: 'Latency: 12ms',
                color: themeExt.accentCyan,
                themeExt: themeExt,
              ),
              const SizedBox(width: 10),
              _desktopStatusPill(
                icon: Icons.battery_charging_full_rounded,
                label: 'LiFePO₄: ${state.telemetry.battery}%',
                color: themeExt.primaryEmerald,
                themeExt: themeExt,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _desktopStatusPill({
    required IconData icon,
    required String label,
    required Color color,
    required AeroTheme themeExt,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: themeExt.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  URGENT ALERT BANNER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildUrgentAlert(String alert, AeroTheme themeExt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: themeExt.aqiPoor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeExt.aqiPoor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: themeExt.aqiPoor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: themeExt.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DESKTOP QUICK STATS MATRIX
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktopQuickStats(BuildContext context,
      TelemetryData tel, int aqi, AeroTheme themeExt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: QuickStatChip(
                icon: Icons.grain_rounded,
                iconColor: AeroTheme.getAqiColor(aqi),
                label: 'PM2.5',
                value: tel.pm25.toStringAsFixed(1),
                unit: 'µg/m³',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: QuickStatChip(
                icon: Icons.blur_on_rounded,
                iconColor: themeExt.accentCyan,
                label: 'PM10',
                value: tel.pm10.toStringAsFixed(1),
                unit: 'µg/m³',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: QuickStatChip(
                icon: Icons.traffic_rounded,
                iconColor: themeExt.aqiModerate,
                label: 'NO₂',
                value: tel.no2.toStringAsFixed(3),
                unit: 'ppm',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: QuickStatChip(
                icon: Icons.local_fire_department_rounded,
                iconColor: themeExt.primaryEmerald,
                label: 'CO',
                value: tel.co.toStringAsFixed(2),
                unit: 'ppm',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: QuickStatChip(
                icon: Icons.co2_rounded,
                iconColor: themeExt.textPrimary,
                label: 'CO₂',
                value: tel.co2.toStringAsFixed(0),
                unit: 'ppm',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: QuickStatChip(
                icon: Icons.science_rounded,
                iconColor: themeExt.accentCyan,
                label: 'VOCs',
                value: tel.voc.toStringAsFixed(0),
                unit: 'ppb',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DESKTOP ACTION ADVISORIES CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktopActionCard(BuildContext context, AeroSenseState state,
      Color aqiColor, AeroTheme themeExt) {
    final adv = state.advisory;
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: aqiColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.health_and_safety_rounded,
                    color: aqiColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  adv.headline.isNotEmpty ? adv.headline : 'Environmental Recommendations',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: themeExt.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (adv.citizenActions.isNotEmpty) ...[
            _actionBullet(
                'Citizen / Resident', adv.citizenActions.first.title, Icons.person_rounded, themeExt),
            const SizedBox(height: 8),
          ],
          if (adv.schoolActions.isNotEmpty) ...[
            _actionBullet(
                'Schools & Children', adv.schoolActions.first.title, Icons.school_rounded, themeExt),
            const SizedBox(height: 8),
          ],
          if (adv.communityActions.isNotEmpty) ...[
            _actionBullet(
                'Municipal / Ward', adv.communityActions.first.title, Icons.apartment_rounded, themeExt),
          ],
        ],
      ),
    );
  }

  Widget _actionBullet(String target, String action, IconData icon, AeroTheme themeExt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: themeExt.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: themeExt.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: themeExt.primaryEmerald),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: themeExt.textSecondary, height: 1.4),
                children: [
                  TextSpan(
                    text: '$target: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: themeExt.textPrimary,
                    ),
                  ),
                  TextSpan(text: action),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  CAMPUS MESH LIVE OVERVIEW CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMeshOverviewCard(
      BuildContext context, AeroSenseState state, AeroTheme themeExt) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.wifi_tethering_rounded,
                      color: themeExt.accentCyan, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Campus Mesh Topology (ESP-NOW)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: themeExt.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: themeExt.accentCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '5 Nodes Active',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: themeExt.accentCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _meshNodePill('Node 01: Main Quad', 'Master', themeExt.primaryEmerald, themeExt),
              const SizedBox(width: 8),
              _meshNodePill('Node 02: Sports Oval', 'Peer', themeExt.accentCyan, themeExt),
              const SizedBox(width: 8),
              _meshNodePill('Node 03: North Gate', 'Peer', themeExt.accentCyan, themeExt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meshNodePill(
      String title, String role, Color color, AeroTheme themeExt) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: themeExt.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
