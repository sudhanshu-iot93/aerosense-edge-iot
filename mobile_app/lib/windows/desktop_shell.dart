// windows/desktop_shell.dart
// Production-Grade Workstation Shell for AeroSense Edge on Windows

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/air_quality_state.dart';
import '../services/edge_api_service.dart';
import '../theme/app_theme.dart';
import '../screens/desktop_dashboard_view.dart';
import '../screens/sensors_screen.dart';
import '../screens/advisory_screen.dart';
import '../screens/mesh_sync_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/notifications_screen.dart';
import '../widgets/ambient_background.dart';

class DesktopShell extends StatefulWidget {
  final AeroSenseState state;
  final VoidCallback onToggleTheme;
  final bool isDark;

  const DesktopShell({
    super.key,
    required this.state,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _selectedIndex = 0;
  final EdgeApiService _api = EdgeApiService();

  final List<String> _scenarios = [
    'Clean Baseline',
    'Traffic Jam',
    'Garbage Fire',
    'Construction Dust',
    'Cooking Smoke',
    'Crop Residue',
  ];

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrl = HardwareKeyboard.instance.isControlPressed;
      // F5 Refresh
      if (event.logicalKey == LogicalKeyboardKey.f5) {
        _api.fetchAndUpdateState();
      }
      // Ctrl+T Theme toggle
      else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyT) {
        widget.onToggleTheme();
      }
      // Ctrl+1 to Ctrl+6 tab switching
      else if (isCtrl && event.logicalKey == LogicalKeyboardKey.digit1) {
        setState(() => _selectedIndex = 0);
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.digit2) {
        setState(() => _selectedIndex = 1);
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.digit3) {
        setState(() => _selectedIndex = 2);
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.digit4) {
        setState(() => _selectedIndex = 3);
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.digit5) {
        setState(() => _selectedIndex = 4);
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.digit6) {
        setState(() => _selectedIndex = 5);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeExt = Theme.of(context).extension<AeroTheme>()!;
    final state = widget.state;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: AmbientBackground(
          child: Row(
            children: [
              // ════════════════════════════════════════════════════════════════
              //  LEFT ACRYLIC SIDEBAR NAVIGATION (WINDOWS 11 FLUENT STYLE)
              // ════════════════════════════════════════════════════════════════
              _buildSidebar(context, themeExt, state),

              // Vertical divider
              Container(
                width: 1,
                color: themeExt.cardBorder,
              ),

              // ════════════════════════════════════════════════════════════════
              //  MAIN WORKSTATION CONTENT AREA
              // ════════════════════════════════════════════════════════════════
              Expanded(
                child: Column(
                  children: [
                    // Top Command & Scenario Toolbar
                    _buildTopCommandBar(context, themeExt, state),

                    // Active screen view
                    Expanded(
                      child: _buildActiveScreen(state),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SIDEBAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSidebar(
      BuildContext context, AeroTheme themeExt, AeroSenseState state) {
    return Container(
      width: 270,
      color: themeExt.cardBg.withValues(alpha: 0.85),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Brand Header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Logo shield
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF141E30),
                            themeExt.primaryEmerald.withValues(alpha: 0.4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: themeExt.primaryEmerald.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: themeExt.primaryEmerald.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(Icons.blur_on_rounded,
                            color: themeExt.primaryEmerald, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'AeroSense',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: themeExt.textPrimary,
                                letterSpacing: -0.03,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: themeExt.primaryEmerald.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: themeExt.primaryEmerald,
                                  letterSpacing: 0.05,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'ARDUINO UNO Q',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: themeExt.accentCyan,
                            fontFamily: 'monospace',
                            letterSpacing: 0.04,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Live Connection Status badge
                ValueListenableBuilder<bool>(
                  valueListenable: _api.isConnectedNotifier,
                  builder: (context, isConnected, _) {
                    final color = isConnected
                        ? themeExt.primaryEmerald
                        : themeExt.aqiModerate;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color,
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isConnected
                                ? 'Live Daemon :8090'
                                : 'Offline Standalone',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Navigation Menu Items ─────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                _navCategoryHeader('MONITORING & INTELLIGENCE', themeExt),
                _navItem(
                  index: 0,
                  icon: Icons.speed_rounded,
                  label: 'Workstation Overview',
                  shortcut: 'Ctrl+1',
                  themeExt: themeExt,
                ),
                _navItem(
                  index: 1,
                  icon: Icons.grid_view_rounded,
                  label: '12-Channel Telemetry',
                  shortcut: 'Ctrl+2',
                  themeExt: themeExt,
                ),
                _navItem(
                  index: 2,
                  icon: Icons.psychology_rounded,
                  label: 'Action Advisories',
                  shortcut: 'Ctrl+3',
                  themeExt: themeExt,
                ),
                const SizedBox(height: 16),
                _navCategoryHeader('CAMPUS MESH & OFFLINE', themeExt),
                _navItem(
                  index: 3,
                  icon: Icons.share_rounded,
                  label: 'Campus Mesh (ESP-NOW)',
                  shortcut: 'Ctrl+4',
                  themeExt: themeExt,
                ),
                _navItem(
                  index: 4,
                  icon: Icons.notifications_none_rounded,
                  label: 'System Event Log',
                  shortcut: 'Ctrl+5',
                  themeExt: themeExt,
                ),
                _navItem(
                  index: 5,
                  icon: Icons.tune_rounded,
                  label: 'Station Settings & Specs',
                  shortcut: 'Ctrl+6',
                  themeExt: themeExt,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Bottom Sidebar Utilities ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LiFePO4 & Hardware Telemetry readout
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: themeExt.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: themeExt.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.battery_charging_full_rounded,
                              size: 16, color: themeExt.primaryEmerald),
                          const SizedBox(width: 6),
                          Text(
                            '${state.telemetry.battery}% LiFePO₄',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: themeExt.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '12ms DMA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: themeExt.accentCyan,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Theme Toggle & Export buttons row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onToggleTheme,
                        icon: Icon(
                            widget.isDark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            size: 15),
                        label: Text(widget.isDark ? 'Light' : 'Dark',
                            style: const TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: themeExt.textPrimary,
                          side: BorderSide(color: themeExt.cardBorder),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _api.fetchAndUpdateState(),
                      tooltip: 'Refresh Telemetry (F5)',
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      style: IconButton.styleFrom(
                        foregroundColor: themeExt.textPrimary,
                        side: BorderSide(color: themeExt.cardBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navCategoryHeader(String title, AeroTheme themeExt) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: themeExt.textSecondary.withValues(alpha: 0.7),
          letterSpacing: 0.08,
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
    required String shortcut,
    required AeroTheme themeExt,
  }) {
    final isSelected = _selectedIndex == index;
    final activeColor = themeExt.primaryEmerald;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: activeColor.withValues(alpha: 0.35))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? activeColor : themeExt.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? themeExt.textPrimary : themeExt.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  shortcut,
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    color: isSelected
                        ? activeColor
                        : themeExt.textSecondary.withValues(alpha: 0.6),
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
  //  TOP COMMAND BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTopCommandBar(
      BuildContext context, AeroTheme themeExt, AeroSenseState state) {
    const titles = [
      'Autonomous Air Quality Workstation Dashboard',
      '12-Channel Real-Time Hardware Sensor Telemetry',
      'AI-Driven Public Health & Citizen Action Advisories',
      'ESP-NOW Campus Peer-to-Peer Mesh Synchronization',
      'Real-Time Environmental Incident & Anomaly Event Log',
      'Arduino UNO Q Hardware Specifications & Configuration',
    ];

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: themeExt.cardBg.withValues(alpha: 0.7),
        border: Border(bottom: BorderSide(color: themeExt.cardBorder)),
      ),
      child: Row(
        children: [
          // Breadcrumb Title
          Expanded(
            child: Row(
              children: [
                Text(
                  'AeroSense Pro',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: themeExt.textSecondary,
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: themeExt.textSecondary),
                Text(
                  titles[_selectedIndex.clamp(0, titles.length - 1)],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: themeExt.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Scenario selector dropdown
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scenario: ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: themeExt.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: themeExt.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: themeExt.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _scenarios.contains(state.activeScenario)
                        ? state.activeScenario
                        : _scenarios.first,
                    isDense: true,
                    dropdownColor: themeExt.cardBg,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: themeExt.textPrimary,
                    ),
                    icon: Icon(Icons.arrow_drop_down_rounded,
                        color: themeExt.textPrimary, size: 20),
                    items: _scenarios.map((sc) {
                      return DropdownMenuItem<String>(
                        value: sc,
                        child: Text(sc),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        _api.setScenario(val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Direct F5 Refresh button
              IconButton(
                onPressed: () => _api.fetchAndUpdateState(),
                tooltip: 'Refresh (F5)',
                icon: const Icon(Icons.refresh_rounded, size: 20),
                style: IconButton.styleFrom(
                  foregroundColor: themeExt.textPrimary,
                  backgroundColor: themeExt.cardBg,
                  side: BorderSide(color: themeExt.cardBorder),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ACTIVE CONTENT SCREEN SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActiveScreen(AeroSenseState state) {
    switch (_selectedIndex) {
      case 0:
        return DesktopDashboardView(
          state: state,
          onScenarioChange: (s) => _api.setScenario(s),
          onRefresh: () => _api.fetchAndUpdateState(),
        );
      case 1:
        return SensorsScreen(state: state);
      case 2:
        return AdvisoryScreen(state: state);
      case 3:
        return MeshSyncScreen(state: state);
      case 4:
        return NotificationsScreen(state: state);
      case 5:
        return SettingsScreen(
          currentNodeIp: _api.baseUrl,
          onNodeIpChanged: (ip) => _api.baseUrl = ip,
        );
      default:
        return DesktopDashboardView(
          state: state,
          onScenarioChange: (s) => _api.setScenario(s),
          onRefresh: () => _api.fetchAndUpdateState(),
        );
    }
  }
}
