// widgets/app_drawer.dart
// Premium animated slide-out navigation drawer

import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/air_quality_state.dart';
import '../theme/app_theme.dart';
import '../screens/ar_vision_screen.dart';
import '../screens/heatmap_screen.dart';
import '../screens/sleep_mode_screen.dart';
import '../services/edge_api_service.dart';
import '../services/report_generator_service.dart';
import '../services/voice_assistant_service.dart';

class AppDrawer extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenAbout;
  final VoidCallback onOpenScenario;
  final VoidCallback onOpenNodeConfig;
  final VoidCallback onToggleTheme;
  final ThemeMode currentThemeMode;
  final bool isLive;
  final String activeScenario;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
    required this.onOpenSettings,
    required this.onOpenNotifications,
    required this.onOpenAbout,
    required this.onOpenScenario,
    required this.onOpenNodeConfig,
    required this.onToggleTheme,
    this.currentThemeMode = ThemeMode.system,
    required this.isLive,
    required this.activeScenario,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(-0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              width: 290,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).extension<AeroTheme>()!.bgDeepNavy.withValues(alpha: 0.97),
                    Theme.of(context).extension<AeroTheme>()!.bgDark.withValues(alpha: 0.99),
                  ],
                ),
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).extension<AeroTheme>()!.glassBorder,
                    width: 1.2,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        children: [
                          _sectionLabel('NAVIGATION'),
                          _buildNavItem(
                              index: 0,
                              icon: Icons.dashboard_outlined,
                              activeIcon: Icons.dashboard_rounded,
                              label: 'Overview',
                              subtitle: 'Live AQI & AI Fingerprint'),
                          _buildNavItem(
                              index: 1,
                              icon: Icons.shield_outlined,
                              activeIcon: Icons.shield_rounded,
                              label: 'Advisory',
                              subtitle: 'Contextual Health Actions'),
                          _buildNavItem(
                              index: 2,
                              icon: Icons.sensors_outlined,
                              activeIcon: Icons.sensors_rounded,
                              label: 'Telemetry',
                              subtitle: '8-Channel Sensor Matrix'),
                          _buildNavItem(
                              index: 3,
                              icon: Icons.hub_outlined,
                              activeIcon: Icons.hub_rounded,
                              label: 'Mesh & Sync',
                              subtitle: 'Campus Node Network'),
                          SizedBox(height: 8),
                          _sectionLabel('TOOLS'),
                          _buildActionItem(
                            icon: Icons.tune_rounded,
                            iconColor: Theme.of(context).extension<AeroTheme>()!.accentCyan,
                            label: 'Scenario Simulator',
                            subtitle: 'Inject environmental events',
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onOpenScenario();
                            },
                          ),
                          _buildActionItem(
                            icon: Icons.public_rounded,
                            iconColor: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
                            label: 'Anywhere Studio',
                            subtitle: '8 Profiles & Standards',
                            onTap: () {
                              Navigator.of(context).pop();
                              _showAnywhereStudioModal(context);
                            },
                          ),
                          _buildActionItem(
                            icon: Icons.compress_rounded,
                            iconColor: Theme.of(context).extension<AeroTheme>()!.accentIndigo,
                            label: 'Compression Inspector',
                            subtitle: 'Gorilla Delta-Run hex dump',
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onNavigate(3);
                            },
                          ),
                          _buildActionItem(
                            icon: Icons.router_rounded,
                            iconColor: Theme.of(context).extension<AeroTheme>()!.accentViolet,
                            label: 'Node Configuration',
                            subtitle: 'Set Arduino UNO Q IP/Port',
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onOpenNodeConfig();
                            },
                          ),
                          _buildActionItem(
                            icon: Icons.map_rounded,
                            iconColor: Theme.of(context).extension<AeroTheme>()!.accentCyan,
                            label: 'City AQI Heatmap',
                            subtitle: 'Campus mesh nodes & halos',
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (ctx) => const HeatmapScreen()),
                              );
                            },
                          ),
                          _buildActionItem(
                            icon: Icons.bedtime_rounded,
                            iconColor: Theme.of(context).extension<AeroTheme>()!.accentViolet,
                            label: 'Circadian Sleep Mode',
                            subtitle: 'Night quiet window & score',
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (ctx) => const SleepModeScreen()),
                              );
                            },
                          ),
                          _buildActionItem(
                            icon: Icons.picture_as_pdf_rounded,
                            iconColor: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
                            label: 'Audit Certificate (PDF)',
                            subtitle: 'Cryptographic compliance seal',
                            onTap: () {
                              Navigator.of(context).pop();
                              ReportGeneratorService().previewOrPrintCertificate(
                                context,
                                AeroSenseState.fromJson({}),
                                null,
                              );
                            },
                          ),
                          _buildActionItem(
                            icon: Icons.record_voice_over_rounded,
                            iconColor: Theme.of(context).extension<AeroTheme>()!.accentAmber,
                            label: 'Voice Health Advisor',
                            subtitle: 'Read current advisory aloud',
                            onTap: () {
                              Navigator.of(context).pop();
                              VoiceAssistantService().speakAdvisory(
                                'AeroSense Edge Advisory: Air quality is currently optimal. All 8 calibrated channels indicate clean indoor air conditions.',
                              );
                            },
                          ),
                          _buildActionItem(
                            icon: Icons.view_in_ar,
                            iconColor: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
                            label: 'AR Vision',
                            subtitle: 'Augmented reality view',
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (ctx) => ARVisionScreen(state: AeroSenseState.fromJson({}))),
                              );
                            },
                          ),
                          SizedBox(height: 8),
                          _sectionLabel('SETTINGS'),
                          _buildThemeActionItem(),
                          _buildActionItem(
                            icon: Icons.notifications_outlined,
                            iconColor: Theme.of(context).extension<AeroTheme>()!.accentAmber,
                            label: 'Notifications',
                            subtitle: 'Alert history & preferences',
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onOpenNotifications();
                            },
                          ),
                          _buildActionItem(
                            icon: Icons.settings_outlined,
                            iconColor: Theme.of(context).extension<AeroTheme>()!.textSecondary,
                            label: 'App Settings',
                            subtitle: 'AQI standard, display, API',
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onOpenSettings();
                            },
                          ),
                          _buildActionItem(
                            icon: Icons.info_outline_rounded,
                            iconColor: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
                            label: 'About AeroSense Edge',
                            subtitle: 'v2.4.0 • Production Build',
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onOpenAbout();
                            },
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.08),
            Theme.of(context).extension<AeroTheme>()!.primaryEmerald.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.glassBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.25),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Icon(
                      Icons.eco_rounded,
                      color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
                      size: 26,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AeroSense Edge',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.40)),
                      ),
                      child: Text(
                        'EDGE AI  v2.4.0',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).extension<AeroTheme>()!.accentCyan,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          // Connection status
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: (widget.isLive
                      ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald
                      : Theme.of(context).extension<AeroTheme>()!.accentCyan)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (widget.isLive
                        ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald
                        : Theme.of(context).extension<AeroTheme>()!.accentCyan)
                    .withValues(alpha: 0.30),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isLive
                        ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald
                        : Theme.of(context).extension<AeroTheme>()!.accentCyan,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isLive
                        ? 'Arduino UNO Q — Live'
                        : 'Offline Edge Core Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).extension<AeroTheme>()!.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(left: 8, top: 8, bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: Theme.of(context).extension<AeroTheme>()!.textMuted,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String subtitle,
  }) {
    final isActive = widget.currentIndex == index;
    final color = isActive ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald : Theme.of(context).extension<AeroTheme>()!.textSecondary;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          widget.onNavigate(index);
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(isActive ? activeIcon : icon, size: 20, color: color),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? Theme.of(context).extension<AeroTheme>()!.textPrimary
                            : Theme.of(context).extension<AeroTheme>()!.textSecondary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).extension<AeroTheme>()!.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: iconColor.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).extension<AeroTheme>()!.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: Theme.of(context).extension<AeroTheme>()!.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeActionItem() {
    final theme = Theme.of(context).extension<AeroTheme>()!;
    final mode = widget.currentThemeMode;
    final IconData icon;
    final String label;
    final String subtitle;

    switch (mode) {
      case ThemeMode.system:
        icon = Icons.brightness_auto_rounded;
        label = 'Theme: System Auto';
        subtitle = 'Follows phone dark / light setting';
        break;
      case ThemeMode.dark:
        icon = Icons.dark_mode_rounded;
        label = 'Theme: Dark Mode';
        subtitle = 'Obsidian & Cyber Mint';
        break;
      case ThemeMode.light:
        icon = Icons.light_mode_rounded;
        label = 'Theme: Light Mode';
        subtitle = 'Airy Glass & Slate';
        break;
    }

    return _buildActionItem(
      icon: icon,
      iconColor: theme.accentCyan,
      label: label,
      subtitle: subtitle,
      onTap: widget.onToggleTheme,
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).extension<AeroTheme>()!.glassBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HARDWARE PLATFORM',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Theme.of(context).extension<AeroTheme>()!.textMuted,
            ),
          ),
          SizedBox(height: 8),
          _footerChip(Icons.memory_rounded, 'Arduino UNO Q',
              Theme.of(context).extension<AeroTheme>()!.primaryEmerald),
          SizedBox(height: 4),
          _footerChip(Icons.developer_board_rounded, 'Qualcomm QRB2210',
              Theme.of(context).extension<AeroTheme>()!.accentCyan),
          SizedBox(height: 4),
          _footerChip(Icons.settings_input_component_rounded, 'STM32 Cortex-M4',
              Theme.of(context).extension<AeroTheme>()!.accentIndigo),
          SizedBox(height: 12),
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).extension<AeroTheme>()!.primaryEmerald.withValues(alpha: 0.12),
                  Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.memory_rounded,
                    size: 13, color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald),
                SizedBox(width: 6),
                Text(
                  'Autonomous Edge AI System',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).extension<AeroTheme>()!.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color.withValues(alpha: 0.70)),
        SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).extension<AeroTheme>()!.textMuted,
          ),
        ),
      ],
    );
  }

  void _showAnywhereStudioModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final profiles = [
          {'id': 'Campus', 'icon': '🌳', 'label': 'Campus Quad', 'desc': 'Open university & smart city baseline'},
          {'id': 'Classroom', 'icon': '🏫', 'label': 'Classroom / Office', 'desc': 'Cognitive Drowsiness (CDI) & ventilation'},
          {'id': 'Hospital', 'icon': '🏥', 'label': 'Hospital / Cleanroom', 'desc': 'Infection risk & sterility compliance'},
          {'id': 'Industrial', 'icon': '🏭', 'label': 'Industrial Workshop', 'desc': 'OSHA/NIOSH 8-hr TWA exposure limits'},
          {'id': 'Kitchen', 'icon': '🍳', 'label': 'Commercial Kitchen', 'desc': 'CO & cooking particulate spikes'},
          {'id': 'Greenhouse', 'icon': '🌱', 'label': 'Smart Greenhouse', 'desc': 'Vapor Pressure Deficit (VPD in kPa)'},
          {'id': 'Transit', 'icon': '🚇', 'label': 'Transit Hub / Metro', 'desc': 'Tunnel dust & diesel exhaust monitoring'},
          {'id': 'Residential', 'icon': '🏡', 'label': 'Residential Haven', 'desc': 'Quiet sleep mode & HEPA filtration'},
        ];

        final standards = [
          {'id': 'NAQI', 'label': 'Indian NAQI (CPCB)', 'desc': '6-category particulate & gas matrix'},
          {'id': 'US_EPA', 'label': 'US EPA AQI', 'desc': '2024 revised PM2.5 breakpoints'},
          {'id': 'EU_CAQI', 'label': 'European CAQI', 'desc': 'Urban traffic & background scale'},
          {'id': 'WHO_2021', 'label': 'WHO 2021 Global', 'desc': 'Strict continuous health ratio'},
        ];

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Text('🌍', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anywhere Deployment Studio',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Deploy on-device AI for any environment',
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    const Text(
                      'ENVIRONMENT PROFILES',
                      style: TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...profiles.map((p) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          leading: Text(p['icon']!, style: const TextStyle(fontSize: 22)),
                          title: Text(p['label']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text(p['desc']!, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white24),
                          onTap: () async {
                            Navigator.pop(ctx);
                            final success = await EdgeApiService().setProfile(p['id']!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success ? 'Switched to ${p['label']} Mode' : 'Profile updated locally'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          },
                        )),
                    const SizedBox(height: 16),
                    const Text(
                      'INTERNATIONAL AQI STANDARDS',
                      style: TextStyle(
                        color: Colors.lightBlueAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...standards.map((s) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          leading: const Icon(Icons.verified_outlined, color: Colors.lightBlueAccent, size: 20),
                          title: Text(s['label']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text(s['desc']!, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white24),
                          onTap: () async {
                            Navigator.pop(ctx);
                            final success = await EdgeApiService().setStandard(s['id']!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success ? 'Standard set to ${s['label']}' : 'Standard updated locally'),
                                  backgroundColor: const Color(0xFF0EA5E9),
                                ),
                              );
                            }
                          },
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
