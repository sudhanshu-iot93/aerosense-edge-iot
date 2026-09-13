// screens/advisory_screen.dart

import 'package:flutter/material.dart';
import '../models/air_quality_state.dart';
import '../theme/app_theme.dart';

class AdvisoryScreen extends StatefulWidget {
  final AeroSenseState state;

  const AdvisoryScreen({
    super.key,
    required this.state,
  });

  @override
  State<AdvisoryScreen> createState() => _AdvisoryScreenState();
}

class _AdvisoryScreenState extends State<AdvisoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final advisory = widget.state.advisory;
    final aqi = widget.state.features.aqi;
    final aqiColor = AeroTheme.getAqiColor(aqi);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Headline Banner
          Container(
            padding: EdgeInsets.all(18),
            decoration: Theme.of(context).extension<AeroTheme>()!.glassCardDecoration(
              borderColor: aqiColor.withValues(alpha: 0.4),
              glow: true,
              glowColor: aqiColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: aqiColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: aqiColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'AQI $aqi • ${widget.state.features.aqiCategory}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: aqiColor,
                        ),
                      ),
                    ),
                    Text(
                      'Source: ${widget.state.sourceAttribution.primarySource}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).extension<AeroTheme>()!.textSecondary),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  advisory.headline,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.bolt, size: 14, color: Theme.of(context).extension<AeroTheme>()!.accentCyan),
                    SizedBox(width: 6),
                    Text(
                      'Generated on-board Arduino UNO Q (Zero Cloud LLM)',
                      style: TextStyle(fontSize: 11, color: Theme.of(context).extension<AeroTheme>()!.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 14),

          // Urgent Plume Alert
          if (advisory.urgentAlerts.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Text('🚨', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CRITICAL SMOKE / POLLUTION ALERT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          advisory.urgentAlerts.first,
                          style: TextStyle(fontSize: 12, color: Theme.of(context).extension<AeroTheme>()!.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14),
          ],

          // Persona Tab Selector
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).extension<AeroTheme>()!.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.cardBorder),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
              indicatorWeight: 3,
              labelColor: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
              unselectedLabelColor: Theme.of(context).extension<AeroTheme>()!.textMuted,
              labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.directions_walk, size: 18), text: 'Citizens'),
                Tab(icon: Icon(Icons.school, size: 18), text: 'Schools'),
                Tab(icon: Icon(Icons.location_city, size: 18), text: 'RWA & Body'),
              ],
            ),
          ),
          SizedBox(height: 14),

          // Tab Content Cards
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPersonaCard(
                  icon: '🚶',
                  title: 'Citizens & Joggers',
                  subtitle: 'Daily Life, Walking & Cardio Guidance',
                  actions: advisory.citizenActions,
                  tagline: 'Hyperlocal exposure minimization for commuters & families.',
                ),
                _buildPersonaCard(
                  icon: '🏫',
                  title: 'Schools & Daycares',
                  subtitle: 'Recess, Sports & Classroom Safety',
                  actions: advisory.schoolActions,
                  tagline: 'Child respiratory health protocol for educational institutions.',
                ),
                _buildPersonaCard(
                  icon: '🏛️',
                  title: 'RWA & Local Body',
                  subtitle: 'Source Mitigation & Campus Actions',
                  actions: advisory.communityActions,
                  tagline: 'Immediate security dispatch and pollution containment.',
                ),
              ],
            ),
          ),

          SizedBox(height: 14),

          // Diurnal Physics Ventilation Box
          Container(
            padding: EdgeInsets.all(16),
            decoration: Theme.of(context).extension<AeroTheme>()!.glassCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, size: 18, color: Theme.of(context).extension<AeroTheme>()!.accentCyan),
                    SizedBox(width: 8),
                    Text(
                      'DIURNAL BOUNDARY LAYER WINDOW',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: Theme.of(context).extension<AeroTheme>()!.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  widget.state.forecast.diurnalTip,
                  style: TextStyle(fontSize: 13, color: Theme.of(context).extension<AeroTheme>()!.textPrimary, height: 1.4),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPersonaCard({
    required String icon,
    required String title,
    required String subtitle,
    required List<ActionItem> actions,
    required String tagline,
  }) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: Theme.of(context).extension<AeroTheme>()!.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Theme.of(context).extension<AeroTheme>()!.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            tagline,
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Theme.of(context).extension<AeroTheme>()!.accentCyan),
          ),
          Divider(color: Theme.of(context).extension<AeroTheme>()!.cardBorder, height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: actions.length,
              separatorBuilder: (_, _) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = actions[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 2),
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald.withValues(alpha: 0.2),
                      ),
                      child: Icon(Icons.check, size: 12, color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
                            ),
                          ),
                          if (item.subtitle.isNotEmpty) ...[
                            SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: TextStyle(fontSize: 11, color: Theme.of(context).extension<AeroTheme>()!.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
