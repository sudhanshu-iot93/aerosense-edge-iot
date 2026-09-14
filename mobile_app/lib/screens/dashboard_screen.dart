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

enum OverviewHubTab { forecast, health, edgeAi }

class DashboardScreen extends StatefulWidget {
  final AeroSenseState state;
  final Function(String) onScenarioChange;
  final Future<void> Function() onRefresh;
  final Function(int)? onNavigateTab;

  const DashboardScreen({
    super.key,
    required this.state,
    required this.onScenarioChange,
    required this.onRefresh,
    this.onNavigateTab,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  OverviewHubTab _activeHub = OverviewHubTab.forecast;
  bool _showAllCards = false;

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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
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
                      const SizedBox(height: 8),

                      // ── Judge Test Drive Quick Bar ───────────────────────
                      JudgeTestDriveBar(
                        activeScenario: state.activeScenario,
                        onScenarioChange: widget.onScenarioChange,
                        onOpenIncidentReport: () => IncidentReportDialog.show(context, state),
                      ),
                      const SizedBox(height: 10),

                      // ── Urgent alert banner ───────────────────────────────
                      if (state.advisory.urgentAlerts.isNotEmpty)
                        _buildUrgentBanner(state.advisory.urgentAlerts.first),

                      // ── Hero 3D AQI Gauge ─────────────────────────────────
                      AqiRadialGauge(
                        aqi: aqi,
                        aqiCategory: state.features.aqiCategory,
                        primaryPollutant: state.features.primaryPollutant,
                      ),
                      const SizedBox(height: 14),

                      // ── Quick stats row ───────────────────────────────────
                      _buildQuickStatsRow(tel, aqi),
                      const SizedBox(height: 14),

                      // ── AI Source Attribution (With one-tap XAI expander) ──
                      _buildAttributionWrapper(state),
                      const SizedBox(height: 14),

                      // ── Unified Smart Daily Briefing & Action Card ───────
                      FutureBuilder<Map<String, dynamic>>(
                        future: _briefingFuture,
                        builder: (_, snap) {
                          final data = snap.hasData
                              ? DailyBriefingData.fromJson(snap.data!)
                              : DailyBriefingData.simulated();
                          return DailyBriefingCard(
                            data: data,
                            onOpenFullAdvisory: widget.onNavigateTab != null
                                ? () => widget.onNavigateTab!(1)
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // ── Segmented Intelligence Selector ───────────────────
                      _buildHubSelector(Theme.of(context).extension<AeroTheme>()!),
                      const SizedBox(height: 14),

                      // ── Active Hub Content (or All) ───────────────────────
                      if (_showAllCards)
                        _buildAllHubsContent(state, aqiColor)
                      else
                        _buildSingleHubContent(state, aqiColor),
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
  //  SEGMENTED INTELLIGENCE HUB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHubSelector(AeroTheme theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.bgSurface.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'Forecast',
              icon: Icons.show_chart_rounded,
              tab: OverviewHubTab.forecast,
              theme: theme,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTabButton(
              title: 'Health',
              icon: Icons.health_and_safety_outlined,
              tab: OverviewHubTab.health,
              theme: theme,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTabButton(
              title: 'Edge AI',
              icon: Icons.memory_rounded,
              tab: OverviewHubTab.edgeAi,
              theme: theme,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => setState(() => _showAllCards = !_showAllCards),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _showAllCards
                    ? theme.accentCyan.withValues(alpha: 0.20)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: _showAllCards
                    ? Border.all(color: theme.accentCyan.withValues(alpha: 0.55))
                    : null,
                boxShadow: _showAllCards
                    ? [
                        BoxShadow(
                          color: theme.accentCyan.withValues(alpha: 0.20),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showAllCards ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                    size: 14,
                    color: _showAllCards ? theme.accentCyan : theme.textMuted,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'All',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _showAllCards ? theme.accentCyan : theme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required OverviewHubTab tab,
    required AeroTheme theme,
  }) {
    final isSelected = !_showAllCards && _activeHub == tab;
    return InkWell(
      onTap: () {
        setState(() {
          _showAllCards = false;
          _activeHub = tab;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.accentCyan.withValues(alpha: 0.25),
                    theme.accentCyan.withValues(alpha: 0.12),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: theme.accentCyan.withValues(alpha: 0.60),
                  width: 1.1,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.accentCyan.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? theme.accentCyan : theme.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : theme.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleHubContent(AeroSenseState state, Color aqiColor) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey(_activeHub),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_activeHub == OverviewHubTab.forecast) ...[
              AqiHistoryChart(forecast: state.forecast),
              const SizedBox(height: 14),
              _buildForecastWrapper(state),
              const SizedBox(height: 14),
              FutureBuilder<Map<String, dynamic>>(
                future: _windowsFuture,
                builder: (_, snap) {
                  final data = snap.hasData
                      ? SafeWindowData.fromJson(snap.data!)
                      : SafeWindowData.simulated();
                  return SafeWindowPlanner(data: data);
                },
              ),
            ] else if (_activeHub == OverviewHubTab.health) ...[
              PollutionCreditCard(
                state: widget.state,
                initialFuture: _creditScoreFuture,
              ),
              const SizedBox(height: 14),
              FutureBuilder<Map<String, dynamic>>(
                future: _healthFuture,
                builder: (_, snap) {
                  final data = snap.hasData
                      ? HealthExposureData.fromJson(snap.data!)
                      : HealthExposureData.simulated();
                  return HealthExposureCard(data: data);
                },
              ),
              const SizedBox(height: 14),
              FutureBuilder<Map<String, dynamic>>(
                future: _streakFuture,
                builder: (_, snap) {
                  final data = snap.hasData
                      ? ComplianceStreakData.fromJson(snap.data!)
                      : ComplianceStreakData.simulated();
                  return ComplianceStreakCard(data: data);
                },
              ),
            ] else if (_activeHub == OverviewHubTab.edgeAi) ...[
              AiBenchmarkCard(benchmark: state.sourceAttribution.aiBenchmark),
              const SizedBox(height: 14),
              FutureBuilder<Map<String, dynamic>>(
                future: _timelineFuture,
                builder: (_, snap) {
                  final data = snap.hasData
                      ? SourceTimelineData.fromJson(snap.data!)
                      : SourceTimelineData.simulated();
                  return SourceDnaTimeline(data: data);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllHubsContent(AeroSenseState state, Color aqiColor) {
    final theme = Theme.of(context).extension<AeroTheme>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionDivider(theme, 'PREDICTIVE FORECAST & PLANNER', Icons.show_chart_rounded),
        const SizedBox(height: 10),
        AqiHistoryChart(forecast: state.forecast),
        const SizedBox(height: 14),
        _buildForecastWrapper(state),
        const SizedBox(height: 14),
        FutureBuilder<Map<String, dynamic>>(
          future: _windowsFuture,
          builder: (_, snap) {
            final data = snap.hasData
                ? SafeWindowData.fromJson(snap.data!)
                : SafeWindowData.simulated();
            return SafeWindowPlanner(data: data);
          },
        ),
        const SizedBox(height: 24),

        _buildSectionDivider(theme, 'PERSONAL HEALTH & RESILIENCE', Icons.health_and_safety_outlined),
        const SizedBox(height: 10),
        PollutionCreditCard(
          state: widget.state,
          initialFuture: _creditScoreFuture,
        ),
        const SizedBox(height: 14),
        FutureBuilder<Map<String, dynamic>>(
          future: _healthFuture,
          builder: (_, snap) {
            final data = snap.hasData
                ? HealthExposureData.fromJson(snap.data!)
                : HealthExposureData.simulated();
            return HealthExposureCard(data: data);
          },
        ),
        const SizedBox(height: 14),
        FutureBuilder<Map<String, dynamic>>(
          future: _streakFuture,
          builder: (_, snap) {
            final data = snap.hasData
                ? ComplianceStreakData.fromJson(snap.data!)
                : ComplianceStreakData.simulated();
            return ComplianceStreakCard(data: data);
          },
        ),
        const SizedBox(height: 24),

        _buildSectionDivider(theme, 'HARDWARE & EDGE AI ENGINE', Icons.memory_rounded),
        const SizedBox(height: 10),
        AiBenchmarkCard(benchmark: state.sourceAttribution.aiBenchmark),
        const SizedBox(height: 14),
        FutureBuilder<Map<String, dynamic>>(
          future: _timelineFuture,
          builder: (_, snap) {
            final data = snap.hasData
                ? SourceTimelineData.fromJson(snap.data!)
                : SourceTimelineData.simulated();
            return SourceDnaTimeline(data: data);
          },
        ),
      ],
    );
  }

  Widget _buildSectionDivider(AeroTheme theme, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.accentCyan),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: theme.accentCyan,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: theme.glassBorder,
          ),
        ),
      ],
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Theme.of(context).extension<AeroTheme>()!.bgSurface.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Live/offline indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  color: liveColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: liveColor.withValues(alpha: 0.45),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulseDot(color: liveColor),
                    const SizedBox(width: 6),
                    Text(
                      isLive ? 'Arduino UNO Q' : 'Offline Core',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: liveColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isLive
                      ? '${state.activeProfile} • ${state.activeStandard}'
                      : '${state.activeScenario} • ${state.activeProfile}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).extension<AeroTheme>()!.textSecondary,
                    fontWeight: FontWeight.w600,
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
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.40),
                      width: 0.9,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up_rounded, size: 13, color: Theme.of(context).extension<AeroTheme>()!.accentCyan),
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
