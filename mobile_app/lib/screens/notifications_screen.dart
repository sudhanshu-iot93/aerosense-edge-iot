// screens/notifications_screen.dart
// Chronological alert history with AQI color coding and dismiss

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/air_quality_state.dart';
import '../widgets/glass_card.dart';

class NotificationsScreen extends StatefulWidget {
  final AeroSenseState state;
  const NotificationsScreen({super.key, required this.state});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<_NotifItem> _items;

  @override
  void initState() {
    super.initState();
    _items = _buildItems();
  }

  List<_NotifItem> _buildItems() {
    final now = DateTime.now();
    final aqi = widget.state.features.aqi;
    final aqiColor = AeroTheme.getAqiColor(aqi);
    final source = widget.state.sourceAttribution.primarySource;
    final sourceIcon = AeroTheme.getSourceIcon(source);

    final items = <_NotifItem>[];

    // Urgent alerts from the live state
    for (int i = 0;
        i < widget.state.advisory.urgentAlerts.length;
        i++) {
      items.add(_NotifItem(
        title: 'URGENT: Pollution Alert',
        body: widget.state.advisory.urgentAlerts[i],
        time: now.subtract(Duration(minutes: i * 3)),
        color: Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor,
        icon: Icons.warning_amber_rounded,
        aqi: aqi,
      ));
    }

    // Current AQI reading
    items.add(_NotifItem(
      title: 'AQI Reading — ${widget.state.features.aqiCategory}',
      body:
          'Current AQI: $aqi — Primary pollutant: ${widget.state.features.primaryPollutant}. $sourceIcon Source identified: $source.',
      time: now.subtract(const Duration(minutes: 1)),
      color: aqiColor,
      icon: Icons.air_outlined,
      aqi: aqi,
    ));

    // Forecast notification
    final horizons = widget.state.forecast.forecastHorizons;
    if (horizons.isNotEmpty) {
      final f = horizons.first;
      items.add(_NotifItem(
        title: 'Forecast: ${f.label}',
        body:
            'Predicted AQI ${f.predictedAqi} (±PM₂.₅ ${f.predictedPm25.toStringAsFixed(1)} μg/m³) — ${f.targetTimeStr}',
        time: now.subtract(const Duration(minutes: 8)),
        color: AeroTheme.getAqiColor(f.predictedAqi),
        icon: Icons.schedule_rounded,
        aqi: f.predictedAqi,
      ));
    }

    // Battery level
    final bat = widget.state.telemetry.battery;
    if (bat < 25) {
      items.add(_NotifItem(
        title: 'Battery Low',
        body:
            'Edge node battery at $bat%. Solar MPPT charging: ${widget.state.telemetry.isCharging ? "Active" : "Idle"}.',
        time: now.subtract(Duration(minutes: 22)),
        color: Theme.of(context).extension<AeroTheme>()!.accentAmber,
        icon: Icons.battery_alert_rounded,
        aqi: null,
      ));
    }

    // Simulated historical entries for richness
    final historicalColors = [
      Theme.of(context).extension<AeroTheme>()!.aqiModerate,
      Theme.of(context).extension<AeroTheme>()!.aqiSatisfactory,
      Theme.of(context).extension<AeroTheme>()!.aqiGood,
    ];
    final historicalAqis = [145, 78, 32];
    final historicalLabels = ['Moderate', 'Satisfactory', 'Good'];
    final historicalDelta = [65, 180, 420];

    for (int i = 0; i < 3; i++) {
      items.add(_NotifItem(
        title: 'AQI Summary — ${historicalLabels[i]}',
        body:
            'Station reported AQI ${historicalAqis[i]} (${historicalLabels[i]}). No urgent actions required.',
        time: now.subtract(Duration(minutes: historicalDelta[i])),
        color: historicalColors[i],
        icon: Icons.analytics_outlined,
        aqi: historicalAqis[i],
      ));
    }

    items.sort((a, b) => b.time.compareTo(a.time));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).extension<AeroTheme>()!.bgDark,
      appBar: _buildAppBar(context),
      body: _items.isEmpty
          ? _buildEmpty()
          : ListView.separated(
              padding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              itemCount: _items.length,
              separatorBuilder: (context, index) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _buildNotifCard(_items[index], index);
              },
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
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
              ),
            ),
            actions: [
              if (_items.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _items.clear()),
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                        color: Theme.of(context).extension<AeroTheme>()!.textSecondary, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifCard(_NotifItem item, int index) {
    return Dismissible(
      key: Key('notif_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_sweep_rounded,
            color: Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor, size: 24),
      ),
      onDismissed: (_) {
        setState(() => _items.removeAt(index));
      },
      child: GlassCard(
        padding: EdgeInsets.all(14),
        glow: false,
        borderColor: item.color.withValues(alpha: 0.30),
        fillColor: item.color.withValues(alpha: 0.06),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: item.color.withValues(alpha: 0.35)),
              ),
              child: Icon(item.icon, size: 18, color: item.color),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      if (item.aqi != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: item.color.withValues(alpha: 0.40)),
                          ),
                          child: Text(
                            'AQI ${item.aqi}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: item.color,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.body,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).extension<AeroTheme>()!.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    _formatTime(item.time),
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).extension<AeroTheme>()!.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, HH:mm').format(dt);
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 48, color: Theme.of(context).extension<AeroTheme>()!.textMuted.withValues(alpha: 0.5)),
          SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).extension<AeroTheme>()!.textSecondary),
          ),
          SizedBox(height: 6),
          Text(
            'Pollution alerts will appear here',
            style: TextStyle(fontSize: 12, color: Theme.of(context).extension<AeroTheme>()!.textMuted),
          ),
        ],
      ),
    );
  }
}

class _NotifItem {
  final String title;
  final String body;
  final DateTime time;
  final Color color;
  final IconData icon;
  final int? aqi;
  _NotifItem({
    required this.title,
    required this.body,
    required this.time,
    required this.color,
    required this.icon,
    required this.aqi,
  });
}
