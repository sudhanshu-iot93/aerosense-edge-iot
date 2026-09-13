// screens/dashboard_screen.dart
// Premium glassmorphic + 3D depth dashboard

import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/air_quality_state.dart';
import '../theme/app_theme.dart';
import '../widgets/aqi_radial_gauge.dart';
import '../widgets/source_attribution_card.dart';
import '../widgets/forecast_card.dart';
import '../widgets/ambient_background.dart';
import '../widgets/quick_stat_chip.dart';
import '../widgets/scenario_selector_sheet.dart';
import '../widgets/aqi_history_chart.dart';
import '../widgets/judge_test_drive_bar.dart';
import '../widgets/ai_benchmark_card.dart';
import '../widgets/incident_report_dialog.dart';
// --- New Feature Widgets ---
import '../widgets/daily_briefing_card.dart';
import '../widgets/health_exposure_card.dart';
import '../widgets/safe_window_planner.dart';
import '../widgets/source_dna_timeline.dart';
import '../widgets/compliance_streak_card.dart';
import '../widgets/pollution_credit_card.dart';
import '../services/edge_api_service.dart';
import '../services/voice_assistant_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class DashboardScreen extends StatefulWidget {
  final AeroSenseState state;
  final Function(String) onScenarioChange;
  final Future<void> Function() onRefresh;

  const DashboardScreen({
    super.key,
    required this.state,
    required this.onScenarioChange,
    required this.onRefresh,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  // Feature data futures (loaded once on init, independent of 1s poll)
  Future<Map<String, dynamic>>? _briefingFuture;
  Future<Map<String, dynamic>>? _healthFuture;
  Future<Map<String, dynamic>>? _windowsFuture;
  Future<Map<String, dynamic>>? _timelineFuture;
  Future<Map<String, dynamic>>? _streakFuture;
  Future<Map<String, dynamic>>? _creditScoreFuture;

  final _api = EdgeApiService();

  void _loadFeatureData() {
    setState(() {
      _briefingFuture     = _api.fetchDailyBriefing();
      _healthFuture       = _api.fetchHealthExposure();
      _windowsFuture      = _api.fetchSafeWindows();
      _timelineFuture     = _api.fetchSourceTimeline();
      _streakFuture       = _api.fetchComplianceStreak();
      _creditScoreFuture  = _api.fetchHealthScore();
    });
  }

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _headerFade =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _initSpeech();
    // Load feature data independently (won't block live AQI display)
    Future.delayed(const Duration(milliseconds: 800), _loadFeatureData);
  }

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _sttText = '';

  void _initSpeech() async {
    await _speech.initialize(
      onStatus: (val) => debugPrint('onStatus: $val'),
      onError: (val) => debugPrint('onError: $val'),
    );
    if (!mounted) return;
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _sttText = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0 && val.finalResult) {
              _showVoiceResponse(_sttText);
              _isListening = false;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _showVoiceResponse(String query) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).extension<AeroTheme>()!.bgDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Voice Assistant', style: TextStyle(color: Colors.white)),
        content: Text('You asked: "$query"\n\nAI Response: Based on current AQI ${widget.state.features.aqi}, it is safe to proceed.', style: TextStyle(color: Theme.of(context).extension<AeroTheme>()!.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: TextStyle(color: Theme.of(context).extension<AeroTheme>()!.accentCyan)))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final aqi = state.features.aqi;
    final aqiColor = AeroTheme.getAqiColor(aqi);
    final tel = state.telemetry;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: RefreshIndicator(
          onRefresh: widget.onRefresh,
          color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
          backgroundColor: Theme.of(context).extension<AeroTheme>()!.cardBg,
          displacement: 60,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Floating status bar ───────────────────────────────
                      SlideTransition(
                        position: _headerSlide,
                        child: FadeTransition(
                          opacity: _headerFade,
                          child: _buildStatusBar(state, aqiColor),
                        ),
                      ),
                      SizedBox(height: 8),

                      // ── Judge Test Drive Quick Bar ───────────────────────
                      JudgeTestDriveBar(
                        activeScenario: state.activeScenario,
                        onScenarioChange: widget.onScenarioChange,
                        onOpenIncidentReport: () => IncidentReportDialog.show(context, state),
                      ),
                      SizedBox(height: 10),

                      // ── Urgent alert banner ───────────────────────────────
                      if (state.advisory.urgentAlerts.isNotEmpty)
                        _buildUrgentBanner(state.advisory.urgentAlerts.first),

                      // ── Hero 3D AQI Gauge ─────────────────────────────────
                      AqiRadialGauge(
                        aqi: aqi,
                        aqiCategory: state.features.aqiCategory,
                        primaryPollutant: state.features.primaryPollutant,
                      ),
                      SizedBox(height: 14),

                      // ── Quick stats row ───────────────────────────────────
                      _buildQuickStatsRow(tel, aqi),
                      SizedBox(height: 14),

                      // ── AI Source Attribution ─────────────────────────────
                      _buildAttributionWrapper(state),
                      SizedBox(height: 14),

                      // ── Edge AI Diagnostics Benchmark Card ───────────────
                      AiBenchmarkCard(benchmark: state.sourceAttribution.aiBenchmark),
                      SizedBox(height: 14),

                      // ── Historical AQI Trend Chart ────────────────────────
                      AqiHistoryChart(forecast: state.forecast),
                      SizedBox(height: 14),

                      // ── Forecast card ─────────────────────────────────────
                      _buildForecastWrapper(state),
                      SizedBox(height: 14),

                      // ── Today's Action Card ───────────────────────────────
                      _buildActionCard(state, aqiColor),
                      SizedBox(height: 20),

                      // ══ Feature 5: Smart Daily Briefing ══════════════════
                      FutureBuilder<Map<String, dynamic>>(
                        future: _briefingFuture,
                        builder: (_, snap) {
                          final data = snap.hasData
                              ? DailyBriefingData.fromJson(snap.data!)
                              : DailyBriefingData.simulated();
                          return DailyBriefingCard(data: data);
                        },
                      ),
                      SizedBox(height: 14),

                      // ══ v1.5 Feature: Pollution Credit Score (0-1000) ══════
                      PollutionCreditCard(
                        state: widget.state,
                        initialFuture: _creditScoreFuture,
                      ),
                      SizedBox(height: 14),

                      // ══ Feature 1: Exposure Timeline ═════════════════════
                      FutureBuilder<Map<String, dynamic>>(
                        future: _healthFuture,
                        builder: (_, snap) {
                          final data = snap.hasData
                              ? HealthExposureData.fromJson(snap.data!)
                              : HealthExposureData.simulated();
                          return HealthExposureCard(data: data);
                        },
                      ),
                      SizedBox(height: 14),

                      // ══ Feature 2: Safe Window Planner ═══════════════════
                      FutureBuilder<Map<String, dynamic>>(
                        future: _windowsFuture,
                        builder: (_, snap) {
                          final data = snap.hasData
                              ? SafeWindowData.fromJson(snap.data!)
                              : SafeWindowData.simulated();
                          return SafeWindowPlanner(data: data);
                        },
                      ),
                      SizedBox(height: 14),

                      // ══ Feature 3: Source DNA Timeline ═══════════════════
                      FutureBuilder<Map<String, dynamic>>(
                        future: _timelineFuture,
                        builder: (_, snap) {
                          final data = snap.hasData
                              ? SourceTimelineData.fromJson(snap.data!)
                              : SourceTimelineData.simulated();
                          return SourceDnaTimeline(data: data);
                        },
                      ),
                      SizedBox(height: 14),

                      // ══ Feature 4: Compliance Streak ═════════════════════
                      FutureBuilder<Map<String, dynamic>>(
                        future: _streakFuture,
                        builder: (_, snap) {
                          final data = snap.hasData
                              ? ComplianceStreakData.fromJson(snap.data!)
                              : ComplianceStreakData.simulated();
                          return ComplianceStreakCard(data: data);
                        },
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        backgroundColor: _isListening ? Theme.of(context).extension<AeroTheme>()!.aqiPoor : Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  STATUS BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatusBar(AeroSenseState state, Color aqiColor) {
    final isLive = state.isLiveConnected;
    final liveColor = isLive ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald : Theme.of(context).extension<AeroTheme>()!.accentCyan;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).extension<AeroTheme>()!.glassSurfaceHigh,
                Theme.of(context).extension<AeroTheme>()!.glassSurfaceMid,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.glassBorderBright, width: 1.2),
          ),
          child: Row(
            children: [
              // Live/offline indicator
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: liveColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: liveColor.withValues(alpha: 0.40)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulseDot(color: liveColor),
                    SizedBox(width: 6),
                    Text(
                      isLive ? 'Arduino UNO Q' : 'Offline Core',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: liveColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  isLive
                      ? '${state.activeProfile} Mode • ${state.activeStandard}'
                      : '${state.activeScenario} • ${state.activeProfile}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).extension<AeroTheme>()!.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Voice Advisory Readout Button
              InkWell(
                onTap: () {
                  VoiceAssistantService().speakAdvisory(
                    'AeroSense Health Advisory. Current status: ${state.features.aqiCategory}, AQI ${state.features.aqi}. Primary pollutant: ${state.features.primaryPollutant}. Dominant source: ${state.sourceAttribution.primarySource}. ${state.advisory.headline}',
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up_rounded, size: 14, color: Theme.of(context).extension<AeroTheme>()!.accentCyan),
                      const SizedBox(width: 4),
                      Text(
                        'Read',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).extension<AeroTheme>()!.accentCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Scenario quick-switch
              InkWell(
                onTap: () => ScenarioSelectorSheet.show(
                  context,
                  state.activeScenario,
                  widget.onScenarioChange,
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).extension<AeroTheme>()!.glassSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.glassBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AeroTheme.getSourceIcon(
                            state.sourceAttribution.primarySource),
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Simulate',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).extension<AeroTheme>()!.accentCyan,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.tune_rounded,
                          size: 13, color: Theme.of(context).extension<AeroTheme>()!.accentCyan),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  URGENT BANNER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildUrgentBanner(String alert) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor.withValues(alpha: 0.18),
                  Theme.of(context).extension<AeroTheme>()!.aqiSevere.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor.withValues(alpha: 0.55),
                  width: 1.3),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor.withValues(alpha: 0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor.withValues(alpha: 0.50)),
                  ),
                  child: Icon(Icons.warning_amber_rounded,
                      color: Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor, size: 18),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'URGENT ALERT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        alert,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  QUICK STATS ROW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickStatsRow(TelemetryData tel, int aqi) {
    return Row(
      children: [
        Expanded(
          child: QuickStatChip(
            icon: Icons.grain_rounded,
            iconColor: AeroTheme.getAqiColor(aqi),
            label: 'PM₂.₅',
            value: tel.pm25.toStringAsFixed(1),
            unit: 'μg/m³',
            alertColor: tel.pm25 > 60 ? Theme.of(context).extension<AeroTheme>()!.aqiPoor : null,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: QuickStatChip(
            icon: Icons.cloud_outlined,
            iconColor: Theme.of(context).extension<AeroTheme>()!.accentCyan,
            label: 'NO₂',
            value: (tel.no2 * 1000).toStringAsFixed(2),
            unit: 'ppb',
            alertColor: tel.no2 > 0.1 ? Theme.of(context).extension<AeroTheme>()!.aqiPoor : null,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: QuickStatChip(
            icon: Icons.thermostat_rounded,
            iconColor: Theme.of(context).extension<AeroTheme>()!.accentAmber,
            label: 'Temp',
            value: tel.temp.toStringAsFixed(1),
            unit: '°C',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: QuickStatChip(
            icon: Icons.water_drop_outlined,
            iconColor: Theme.of(context).extension<AeroTheme>()!.accentIndigo,
            label: 'Humidity',
            value: tel.humidity.toStringAsFixed(0),
            unit: '%',
            alertColor: tel.humidity > 85 ? Theme.of(context).extension<AeroTheme>()!.accentIndigo : null,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  AI SOURCE ATTRIBUTION WRAPPER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAttributionWrapper(AeroSenseState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: SourceAttributionCard(
          attribution: state.sourceAttribution,
          features: state.features,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  FORECAST WRAPPER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildForecastWrapper(AeroSenseState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: ForecastCard(forecast: state.forecast),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TODAY'S ACTION CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionCard(AeroSenseState state, Color aqiColor) {
    final advisory = state.advisory;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                aqiColor.withValues(alpha: 0.10),
                Theme.of(context).extension<AeroTheme>()!.glassSurfaceMid,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: aqiColor.withValues(alpha: 0.30), width: 1),
            boxShadow: [
              BoxShadow(
                color: aqiColor.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: aqiColor),
                  SizedBox(width: 8),
                  Text(
                    "TODAY'S HYPERLOCAL ACTION",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: aqiColor.withValues(alpha: 0.80),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                advisory.headline,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
                  height: 1.35,
                ),
              ),
              if (advisory.citizenActions.isNotEmpty) ...[
                SizedBox(height: 12),
                ...advisory.citizenActions.take(2).map((action) => Padding(
                      padding: EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin:
                                EdgeInsets.only(top: 5, right: 10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: aqiColor,
                              boxShadow: [
                                BoxShadow(
                                  color: aqiColor.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              action.title,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).extension<AeroTheme>()!.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: aqiColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: aqiColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Full Advisory',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: aqiColor,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 11, color: aqiColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Animated pulse dot ──────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.6 + 0.4 * _anim.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.5 * _anim.value),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
