// screens/settings_screen.dart
// App settings: node connection, notifications, AQI standard, display, about

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  final String currentNodeIp;
  final ValueChanged<String> onNodeIpChanged;

  const SettingsScreen({
    super.key,
    required this.currentNodeIp,
    required this.onNodeIpChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _ipController;
  int _pollingInterval = 1;
  String _aqiStandard = 'NAQI India (CPCB 2014)';
  bool _notifyUrgent = true;
  bool _notifyDaily = false;
  bool _notifyBattery = true;
  bool _autoReconnect = true;
  bool _compressData = true;

  final List<String> _aqiStandards = [
    'NAQI India (CPCB 2014)',
    'AQI US (EPA)',
    'WHO 2021 Guidelines',
  ];

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.currentNodeIp);
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).extension<AeroTheme>()!.bgDark,
      appBar: _buildAppBar(context),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildSectionHeader('NODE CONNECTION', Icons.router_rounded,
              Theme.of(context).extension<AeroTheme>()!.accentCyan),
          SizedBox(height: 8),
          GlassCard(
            padding: EdgeInsets.all(18),
            glow: false,
            borderColor: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arduino UNO Q Node IP',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).extension<AeroTheme>()!.textSecondary,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _ipController,
                        hint: 'http://192.168.4.1:8000',
                        icon: Icons.wifi_rounded,
                        keyboardType: TextInputType.url,
                      ),
                    ),
                    SizedBox(width: 10),
                    _buildIconButton(
                      icon: Icons.check_rounded,
                      color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
                      onTap: () {
                        widget.onNodeIpChanged(_ipController.text.trim());
                        ScaffoldMessenger.of(context).showSnackBar(
                          _snackBar('Node IP updated', Theme.of(context).extension<AeroTheme>()!.primaryEmerald),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 14),
                Text(
                  'Polling Interval',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).extension<AeroTheme>()!.textSecondary),
                ),
                SizedBox(height: 8),
                Row(
                  children: [1, 2, 5, 10].map((s) {
                    final active = _pollingInterval == s;
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _pollingInterval = s),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald.withValues(alpha: 0.18)
                                : Theme.of(context).extension<AeroTheme>()!.glassSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: active
                                  ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald
                                  : Theme.of(context).extension<AeroTheme>()!.glassBorder,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            '${s}s',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald
                                  : Theme.of(context).extension<AeroTheme>()!.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 14),
                _buildToggleRow(
                  'Auto-Reconnect on Wi-Fi change',
                  Icons.sync_rounded,
                  Theme.of(context).extension<AeroTheme>()!.accentCyan,
                  _autoReconnect,
                  (v) => setState(() => _autoReconnect = v),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          _buildSectionHeader('NOTIFICATIONS', Icons.notifications_outlined,
              Theme.of(context).extension<AeroTheme>()!.accentAmber),
          SizedBox(height: 8),
          GlassCard(
            padding: EdgeInsets.all(18),
            borderColor: Theme.of(context).extension<AeroTheme>()!.accentAmber.withValues(alpha: 0.20),
            child: Column(
              children: [
                _buildToggleRow(
                  'Urgent pollution alerts',
                  Icons.warning_amber_rounded,
                  Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor,
                  _notifyUrgent,
                  (v) => setState(() => _notifyUrgent = v),
                ),
                Divider(color: Theme.of(context).extension<AeroTheme>()!.glassBorder, height: 20),
                _buildToggleRow(
                  'Daily AQI summary',
                  Icons.calendar_today_rounded,
                  Theme.of(context).extension<AeroTheme>()!.accentCyan,
                  _notifyDaily,
                  (v) => setState(() => _notifyDaily = v),
                ),
                Divider(color: Theme.of(context).extension<AeroTheme>()!.glassBorder, height: 20),
                _buildToggleRow(
                  'Battery low warning',
                  Icons.battery_alert_rounded,
                  Theme.of(context).extension<AeroTheme>()!.accentAmber,
                  _notifyBattery,
                  (v) => setState(() => _notifyBattery = v),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          _buildSectionHeader('AQI STANDARD', Icons.analytics_outlined,
              Theme.of(context).extension<AeroTheme>()!.accentIndigo),
          SizedBox(height: 8),
          GlassCard(
            padding: EdgeInsets.all(18),
            borderColor: Theme.of(context).extension<AeroTheme>()!.accentIndigo.withValues(alpha: 0.22),
            child: Column(
              children: _aqiStandards.map((std) {
                final active = _aqiStandard == std;
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _aqiStandard = std),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: active
                            ? Theme.of(context).extension<AeroTheme>()!.accentIndigo.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active
                              ? Theme.of(context).extension<AeroTheme>()!.accentIndigo
                              : Theme.of(context).extension<AeroTheme>()!.glassBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            active
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 18,
                            color: active
                                ? Theme.of(context).extension<AeroTheme>()!.accentIndigo
                                : Theme.of(context).extension<AeroTheme>()!.textMuted,
                          ),
                          SizedBox(width: 12),
                          Text(
                            std,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: active
                                  ? Theme.of(context).extension<AeroTheme>()!.textPrimary
                                  : Theme.of(context).extension<AeroTheme>()!.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 20),

          _buildSectionHeader(
              'DATA', Icons.storage_rounded, Theme.of(context).extension<AeroTheme>()!.primaryEmerald),
          SizedBox(height: 8),
          GlassCard(
            padding: EdgeInsets.all(18),
            child: Column(
              children: [
                _buildToggleRow(
                  'Adaptive Gorilla compression',
                  Icons.compress_rounded,
                  Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
                  _compressData,
                  (v) => setState(() => _compressData = v),
                ),
                Divider(color: Theme.of(context).extension<AeroTheme>()!.glassBorder, height: 20),
                _buildInfoRow('Local retention', '30 days (SQLite)'),
                SizedBox(height: 8),
                _buildInfoRow('Compression ratio', '~74% (Delta-Run LZ4)'),
                SizedBox(height: 8),
                _buildInfoRow('24h packet size', '< 42 KB'),
              ],
            ),
          ),
          SizedBox(height: 20),

          _buildSectionHeader('ABOUT', Icons.info_outline_rounded,
              Theme.of(context).extension<AeroTheme>()!.textSecondary),
          SizedBox(height: 8),
          GlassCard(
            padding: EdgeInsets.all(18),
            child: Column(
              children: [
                _buildInfoRow('App version', 'v2.4.0 Edge AI Edition'),
                SizedBox(height: 8),
                _buildInfoRow('Flutter SDK', '3.x'),
                SizedBox(height: 8),
                _buildInfoRow('Hardware', 'Arduino UNO Q'),
                SizedBox(height: 8),
                _buildInfoRow('AI Engine', 'Offline Decision Forest'),
                SizedBox(height: 8),
                _buildInfoRow('Standard', 'India NAQI / CPCB 2014'),
                SizedBox(height: 8),
                _buildInfoRow('Edition', 'Edge AI Production Build'),
              ],
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AppBar(
            backgroundColor: Theme.of(context).extension<AeroTheme>()!.bgSurface.withValues(alpha: 0.85),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Theme.of(context).extension<AeroTheme>()!.textPrimary, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'App Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow(String label, IconData icon, Color color, bool value,
      ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: color,
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return color.withValues(alpha: 0.25);
            }
            return Theme.of(context).extension<AeroTheme>()!.glassSurface;
          }),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AeroTheme>()!.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.glassBorder),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              fontSize: 12, color: Theme.of(context).extension<AeroTheme>()!.textMuted),
          prefixIcon: Icon(icon, size: 16, color: Theme.of(context).extension<AeroTheme>()!.textMuted),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.40)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  SnackBar _snackBar(String msg, Color color) {
    return SnackBar(
      content: Text(msg,
          style: TextStyle(color: Theme.of(context).extension<AeroTheme>()!.textPrimary)),
      backgroundColor: color.withValues(alpha: 0.90),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    );
  }
}
