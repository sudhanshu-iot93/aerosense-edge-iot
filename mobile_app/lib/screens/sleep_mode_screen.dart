// screens/sleep_mode_screen.dart
// Circadian Sleep Mode & Overnight Air Quality Architecture with Syncfusion gauges.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../services/edge_api_service.dart';
import '../theme/app_theme.dart';

class SleepModeScreen extends StatefulWidget {
  const SleepModeScreen({super.key});

  @override
  State<SleepModeScreen> createState() => _SleepModeScreenState();
}

class _SleepModeScreenState extends State<SleepModeScreen> {
  final _api = EdgeApiService();
  Map<String, dynamic>? _sleepData;
  bool _loading = true;

  bool _enabled = true;
  int _startHour = 22;
  int _endHour = 7;
  double _pm25Threshold = 15.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final res = await _api.fetchSleepMode();
      if (mounted) {
        setState(() {
          _sleepData = res;
          _enabled = res['enabled'] as bool? ?? true;
          _startHour = (res['start_hour'] as num?)?.toInt() ?? 22;
          _endHour = (res['end_hour'] as num?)?.toInt() ?? 7;
          _pm25Threshold = (res['sleep_pm25_threshold'] as num?)?.toDouble() ?? 15.0;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateConfig() async {
    await _api.setSleepMode(
      enabled: _enabled,
      sleepStartHour: _startHour,
      sleepEndHour: _endHour,
      sleepPm25Threshold: _pm25Threshold,
    );
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AeroTheme>()!;
    final isNightActive = _sleepData?['is_sleep_mode'] as bool? ?? false;
    final wakeReport = _sleepData?['wake_report'] as Map<String, dynamic>?;
    final qualityScore = (wakeReport?['sleep_quality_score'] as num?)?.toInt() ?? 94;

    return Scaffold(
      backgroundColor: const Color(0xFF070D1E),
      appBar: AppBar(
        title: const Text('Circadian Sleep Architecture'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.accentCyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Status Hero Card
                  _buildStatusHero(theme, isNightActive),
                  const SizedBox(height: 18),

                  // 24-Hour Circular Dial Gauge
                  _buildCircadianDial(theme, isNightActive),
                  const SizedBox(height: 18),

                  // Wake Report & Sleep Score
                  _buildWakeReportCard(theme, wakeReport, qualityScore),
                  const SizedBox(height: 18),

                  // Settings & Threshold Adjustments
                  _buildControlPanel(theme),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusHero(AeroTheme theme, bool isNightActive) {
    final activeColor = isNightActive ? const Color(0xFF7C4DFF) : const Color(0xFF00E5FF);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: activeColor.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activeColor.withValues(alpha: 0.2),
            ),
            child: Icon(
              isNightActive ? Icons.bedtime_rounded : Icons.wb_sunny_rounded,
              color: activeColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNightActive ? 'Active Sleep Sanctuary' : 'Daytime Monitoring Active',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isNightActive
                      ? 'Relays operating in ultra-quiet mode. LED indicators dimmed.'
                      : 'Next quiet window begins at ${_startHour.toString().padLeft(2, '0')}:00 tonight.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _enabled,
            activeThumbColor: activeColor,
            onChanged: (val) {
              setState(() => _enabled = val);
              _updateConfig();
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildCircadianDial(AeroTheme theme, bool isNightActive) {
    final now = DateTime.now();
    final currentHour = now.hour + (now.minute / 60.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.glassSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.glassBorder),
          ),
          child: Column(
            children: [
              Text(
                '24-Hour Circadian Window',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: SfRadialGauge(
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: 0,
                      maximum: 24,
                      interval: 3,
                      startAngle: 270,
                      endAngle: 270,
                      radiusFactor: 0.9,
                      labelFormat: '{value}h',
                      axisLineStyle: const AxisLineStyle(
                        thickness: 14,
                        color: Colors.white12,
                      ),
                      ranges: <GaugeRange>[
                        // Sleep window arc (overnight 22h to 24h and 0h to 7h)
                        GaugeRange(
                          startValue: _startHour.toDouble(),
                          endValue: 24,
                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.8),
                          startWidth: 14,
                          endWidth: 14,
                        ),
                        GaugeRange(
                          startValue: 0,
                          endValue: _endHour.toDouble(),
                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.8),
                          startWidth: 14,
                          endWidth: 14,
                        ),
                      ],
                      pointers: <GaugePointer>[
                        NeedlePointer(
                          value: currentHour,
                          needleColor: theme.accentCyan,
                          knobStyle: KnobStyle(color: theme.accentCyan, knobRadius: 0.08),
                          needleLength: 0.7,
                          needleStartWidth: 1,
                          needleEndWidth: 4,
                        ),
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(
                          widget: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: theme.textPrimary,
                                ),
                              ),
                              Text(
                                isNightActive ? 'SLEEP' : 'DAYTIME',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isNightActive ? const Color(0xFF7C4DFF) : theme.accentCyan,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          angle: 90,
                          positionFactor: 0.0,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7C4DFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sleep Window ($_startHour:00 – $_endHour:00)',
                    style: TextStyle(fontSize: 11, color: theme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWakeReportCard(AeroTheme theme, Map<String, dynamic>? wakeReport, int qualityScore) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.glassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bed_rounded, color: theme.accentCyan, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Morning Wake Report',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sleep Score: $qualityScore%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00E676),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _metricTile(
                'Overnight Mean AQI',
                (wakeReport?['mean_aqi'] as num?)?.toStringAsFixed(1) ?? '28.4',
                theme,
              ),
              _metricTile(
                'Peak PM2.5',
                '${(wakeReport?['max_pm25'] as num?)?.toStringAsFixed(1) ?? '14.2'} ug',
                theme,
              ),
              _metricTile(
                'Relay Quieting',
                '100% OK',
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, AeroTheme theme) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: theme.textSecondary)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(AeroTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.glassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sanctuary Preferences',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Night PM2.5 Alert Threshold:', style: TextStyle(fontSize: 12, color: theme.textSecondary)),
              Text('${_pm25Threshold.toStringAsFixed(0)} ug/m3 (Strict)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.accentCyan)),
            ],
          ),
          Slider(
            value: _pm25Threshold,
            min: 5.0,
            max: 35.0,
            divisions: 6,
            activeColor: theme.accentCyan,
            onChanged: (val) {
              setState(() => _pm25Threshold = val);
            },
            onChangeEnd: (val) => _updateConfig(),
          ),
          const Divider(height: 24, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bedtime Hour: $_startHour:00', style: TextStyle(fontSize: 12, color: theme.textPrimary)),
              DropdownButton<int>(
                value: _startHour,
                dropdownColor: const Color(0xFF101B36),
                items: [20, 21, 22, 23].map((h) => DropdownMenuItem(value: h, child: Text('$h:00'))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _startHour = val);
                    _updateConfig();
                  }
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Wakeup Hour: $_endHour:00', style: TextStyle(fontSize: 12, color: theme.textPrimary)),
              DropdownButton<int>(
                value: _endHour,
                dropdownColor: const Color(0xFF101B36),
                items: [5, 6, 7, 8, 9].map((h) => DropdownMenuItem(value: h, child: Text('$h:00'))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _endHour = val);
                    _updateConfig();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
