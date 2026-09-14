// main.dart
// AeroSense Edge — premium shell with drawer, NavigationBar, notification badge

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/air_quality_state.dart';
import 'services/edge_api_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/advisory_screen.dart';
import 'screens/sensors_screen.dart';
import 'screens/mesh_sync_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notifications_screen.dart';
import 'widgets/app_drawer.dart';
import 'widgets/scenario_selector_sheet.dart';
import 'package:flutter/foundation.dart';
import 'widgets/health_points_badge.dart';
import 'windows/desktop_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      await NotificationService().init();
    } catch (_) {}
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));
  }
  runApp(const AeroSenseApp());
}

class AeroSenseApp extends StatefulWidget {
  const AeroSenseApp({super.key});

  @override
  State<AeroSenseApp> createState() => _AeroSenseAppState();
}

class _AeroSenseAppState extends State<AeroSenseApp> {
  // Follows phone dark / light mode by default!
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.system) {
        _themeMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
    });
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeroSense Pro — Autonomous Edge AI Air Intelligence',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return MainNavigationShell(
            onToggleTheme: _toggleTheme,
            onThemeModeChanged: _setThemeMode,
            currentThemeMode: _themeMode,
            isDark: isDark,
          );
        },
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ThemeMode currentThemeMode;
  final bool isDark;

  const MainNavigationShell({
    super.key,
    required this.onToggleTheme,
    required this.onThemeModeChanged,
    required this.currentThemeMode,
    required this.isDark,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  final EdgeApiService _apiService = EdgeApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Node IP (editable from settings)
  String _nodeIp = 'http://192.168.4.1:8000';

  // Notification badge count
  int _notifCount = 2;

  bool _hasNotifiedHighAqi = false;

  @override
  void initState() {
    super.initState();
    _apiService.startPolling();
    _apiService.stateNotifier.addListener(_checkAqiAlert);
  }

  void _checkAqiAlert() {
    final state = _apiService.stateNotifier.value;
    if (state != null) {
      if (state.features.aqi > 150 && !_hasNotifiedHighAqi) {
        NotificationService().showWarningNotification(
          title: 'High AQI Alert: ${state.features.aqi}',
          body: 'Air quality is very poor. Please stay indoors.',
        );
        _hasNotifiedHighAqi = true;
      } else if (state.features.aqi <= 150) {
        _hasNotifiedHighAqi = false;
      }
    }
  }

  @override
  void dispose() {
    _apiService.stateNotifier.removeListener(_checkAqiAlert);
    _apiService.stopPolling();
    super.dispose();
  }

  void _onScenarioChanged(String scenario) {
    _apiService.setScenario(scenario);
  }

  void _openSettings() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, anim, secondary) => SettingsScreen(
          currentNodeIp: _nodeIp,
          onNodeIpChanged: (ip) => setState(() => _nodeIp = ip),
          currentThemeMode: widget.currentThemeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
        ),
        transitionsBuilder: (context, anim, secondary, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  void _openNotifications(AeroSenseState? state) {
    if (state == null) return;
    setState(() => _notifCount = 0);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, anim, secondary) =>
            NotificationsScreen(state: state),
        transitionsBuilder: (context, anim, secondary, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  void _openNodeConfig(BuildContext context) {
    final ctrl = TextEditingController(text: _nodeIp);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).extension<AeroTheme>()!.bgSurface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.15),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.35)),
                        ),
                        child: Icon(Icons.router_rounded,
                            color: Theme.of(context).extension<AeroTheme>()!.accentCyan, size: 20),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Node Configuration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
                            ),
                          ),
                          Text(
                            'Arduino UNO Q Wi-Fi AP',
                            style: TextStyle(
                                fontSize: 11, color: Theme.of(context).extension<AeroTheme>()!.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Node IP Address',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).extension<AeroTheme>()!.textSecondary),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).extension<AeroTheme>()!.glassSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.glassBorder),
                    ),
                    child: TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.url,
                      style: TextStyle(
                          color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'http://192.168.4.1:8000',
                        hintStyle: TextStyle(
                            color: Theme.of(context).extension<AeroTheme>()!.textMuted, fontSize: 12),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.wifi_rounded,
                            color: Theme.of(context).extension<AeroTheme>()!.textMuted, size: 16),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Cancel',
                              style: TextStyle(
                                  color: Theme.of(context).extension<AeroTheme>()!.textSecondary)),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _nodeIp = ctrl.text.trim());
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text('Node IP updated'),
                              backgroundColor: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
                            foregroundColor: Colors.black,
                            padding:
                                EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text('Connect',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).extension<AeroTheme>()!.bgSurface.withValues(alpha: 0.95),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                    color: Theme.of(context).extension<AeroTheme>()!.glassBorderBright, width: 1.0),
              ),
              padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).extension<AeroTheme>()!.glassBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.5),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.3),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Icon(
                          Icons.eco_rounded,
                          size: 36,
                          color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'AeroSense Edge',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Version 2.4.0 • Autonomous Edge AI Edition',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).extension<AeroTheme>()!.accentCyan,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).extension<AeroTheme>()!.glassSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.glassBorder),
                    ),
                    child: Column(
                      children: [
                        _SpecRow(
                            label: 'Hardware Platform',
                            value: 'Arduino UNO Q'),
                        SizedBox(height: 8),
                        _SpecRow(
                            label: 'Linux MPU',
                            value: 'Qualcomm QRB2210 (Debian)'),
                        SizedBox(height: 8),
                        _SpecRow(
                            label: 'Real-Time MCU',
                            value: 'STM32 ARM Cortex-M4'),
                        SizedBox(height: 8),
                        _SpecRow(
                            label: 'AI Fingerprinting',
                            value: 'Offline Decision Forest'),
                        SizedBox(height: 8),
                        _SpecRow(
                            label: 'Compression',
                            value: 'Adaptive LZ4 Delta-Run (74%)'),
                        SizedBox(height: 8),
                        _SpecRow(
                            label: 'Standard',
                            value: 'India NAQI / CPCB 2014'),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Close',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AeroSenseState?>(
      valueListenable: _apiService.stateNotifier,
      builder: (context, state, child) {
        // ── Splash / loading screen ────────────────────────────────────────
        if (state == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).extension<AeroTheme>()!.bgDark,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.5),
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Icon(
                          Icons.eco_rounded,
                          size: 48,
                          color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'AeroSense Edge',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Offline Edge AI Air Intelligence',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).extension<AeroTheme>()!.accentCyan,
                      letterSpacing: 0.4,
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Initializing Neural Inference Engine...',
                    style: TextStyle(
                        color: Theme.of(context).extension<AeroTheme>()!.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        // ── Desktop or Widescreen Workstation Layout ──────────────────────
        if ((!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) ||
            MediaQuery.of(context).size.width >= 960) {
          return DesktopShell(
            state: state,
            onToggleTheme: widget.onToggleTheme,
            isDark: widget.isDark,
            currentThemeMode: widget.currentThemeMode,
            onThemeModeChanged: widget.onThemeModeChanged,
          );
        }

        // ── Compact / Mobile shell ────────────────────────────────────────
        final screens = [
          DashboardScreen(
            state: state,
            onScenarioChange: _onScenarioChanged,
            onRefresh: _apiService.fetchAndUpdateState,
            onNavigateTab: (idx) => setState(() => _currentIndex = idx),
          ),
          AdvisoryScreen(state: state),
          SensorsScreen(state: state),
          MeshSyncScreen(state: state),
        ];

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).extension<AeroTheme>()!.bgDark,
          // ── Slide-out drawer ─────────────────────────────────────────────
          drawer: AppDrawer(
            currentIndex: _currentIndex,
            onNavigate: (i) => setState(() => _currentIndex = i),
            onOpenSettings: _openSettings,
            onOpenNotifications: () => _openNotifications(state),
            onOpenAbout: () => _showAboutSheet(context),
            onOpenScenario: () => ScenarioSelectorSheet.show(
              context,
              state.activeScenario,
              _onScenarioChanged,
            ),
            onOpenNodeConfig: () => _openNodeConfig(context),
            onToggleTheme: widget.onToggleTheme,
            currentThemeMode: widget.currentThemeMode,
            isLive: state.isLiveConnected,
            activeScenario: state.activeScenario,
          ),
          // ── Premium AppBar ───────────────────────────────────────────────
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).extension<AeroTheme>()!.bgDark.withValues(alpha: 0.92),
                        Theme.of(context).extension<AeroTheme>()!.bgDark.withValues(alpha: 0.70),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                          color: Theme.of(context).extension<AeroTheme>()!.glassBorder, width: 0.8),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          // Hamburger menu button
                          IconButton(
                            icon: Icon(Icons.menu_rounded,
                                color: Theme.of(context).extension<AeroTheme>()!.textPrimary, size: 24),
                            onPressed: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            tooltip: 'Open menu',
                          ),
                          // Logo + name
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Theme.of(context).extension<AeroTheme>()!.bgSurface,
                                border: Border.all(
                                  color: Theme.of(context).extension<AeroTheme>()!.accentCyan
                                      .withValues(alpha: 0.40),
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).extension<AeroTheme>()!.accentCyan
                                        .withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Center(
                                  child: Icon(Icons.eco_rounded,
                                      size: 20,
                                      color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'AeroSense',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).extension<AeroTheme>()!.accentCyan
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(5),
                                        border: Border.all(
                                          color: Theme.of(context).extension<AeroTheme>()!.accentCyan
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                      child: Text(
                                        'EDGE AI',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          color: Theme.of(context).extension<AeroTheme>()!.accentCyan,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 1),
                                Text(
                                  state.isLiveConnected
                                      ? 'Live Node Connected'
                                      : 'Offline Intelligence Active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).extension<AeroTheme>()!.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Gamification HP Badge
                          const HealthPointsBadge(),
                          SizedBox(width: 8),
                          // Notification bell with badge
                          Stack(
                            children: [
                              IconButton(
                                icon: Icon(
                                    Icons.notifications_outlined,
                                    color: Theme.of(context).extension<AeroTheme>()!.textSecondary,
                                    size: 22),
                                onPressed: () =>
                                    _openNotifications(state),
                                tooltip: 'Notifications',
                              ),
                              if (_notifCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Theme.of(context).extension<AeroTheme>()!.bgDark, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor
                                              .withValues(alpha: 0.5),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$_notifCount',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          // Scenario quick pick
                          IconButton(
                            icon: Icon(Icons.tune_rounded,
                                color: Theme.of(context).extension<AeroTheme>()!.textPrimary, size: 22),
                            tooltip: 'Simulate Scenario',
                            onPressed: () => ScenarioSelectorSheet.show(
                              context,
                              state.activeScenario,
                              _onScenarioChanged,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: screens[_currentIndex],
          // ── Frosted glass NavigationBar ──────────────────────────────────
          bottomNavigationBar: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).extension<AeroTheme>()!.bgDark.withValues(alpha: 0.75),
                      Theme.of(context).extension<AeroTheme>()!.bgDark.withValues(alpha: 0.95),
                    ],
                  ),
                  border: Border(
                    top: BorderSide(
                        color: Theme.of(context).extension<AeroTheme>()!.glassBorder, width: 0.8),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (i) =>
                      setState(() => _currentIndex = i),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  height: 68,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: 'Overview',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.shield_outlined),
                      selectedIcon: Icon(Icons.shield_rounded),
                      label: 'Advisory',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.sensors_outlined),
                      selectedIcon: Icon(Icons.sensors_rounded),
                      label: 'Telemetry',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.hub_outlined),
                      selectedIcon: Icon(Icons.hub_rounded),
                      label: 'Mesh',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Spec row for about sheet ─────────────────────────────────────────────────

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12, color: Theme.of(context).extension<AeroTheme>()!.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).extension<AeroTheme>()!.textPrimary)),
      ],
    );
  }
}
