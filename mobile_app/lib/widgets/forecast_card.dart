// widgets/forecast_card.dart

import 'package:flutter/material.dart';
import '../models/air_quality_state.dart';
import '../theme/app_theme.dart';

class ForecastCard extends StatelessWidget {
  final ForecastData forecast;

  const ForecastCard({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    Color trendColor = Theme.of(context).extension<AeroTheme>()!.primaryEmerald;
    if (forecast.overallTrend == 'DETERIORATING') {
      trendColor = Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor;
    } else if (forecast.overallTrend == 'STABLE') {
      trendColor = Theme.of(context).extension<AeroTheme>()!.accentCyan;
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: Theme.of(context).extension<AeroTheme>()!.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timeline, size: 20, color: Theme.of(context).extension<AeroTheme>()!.accentCyan),
                  SizedBox(width: 8),
                  Text(
                    'HYPERLOCAL 6-HOUR FORECAST',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Theme.of(context).extension<AeroTheme>()!.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: trendColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'Trend: ${forecast.overallTrend}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: trendColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Autonomous on-device atmospheric boundary layer model (Zero Cloud):',
            style: TextStyle(fontSize: 12, color: Theme.of(context).extension<AeroTheme>()!.textMuted),
          ),
          SizedBox(height: 16),

          // Horizon Cards
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: forecast.forecastHorizons.length,
              separatorBuilder: (_, _) => SizedBox(width: 12),
              itemBuilder: (context, index) {
                final h = forecast.forecastHorizons[index];
                final horizonAqiColor = AeroTheme.getAqiColor(h.predictedAqi);

                return Container(
                  width: 108,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).extension<AeroTheme>()!.bgSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            h.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).extension<AeroTheme>()!.accentCyan,
                            ),
                          ),
                          Text(
                            h.targetTimeStr,
                            style: TextStyle(fontSize: 10, color: Theme.of(context).extension<AeroTheme>()!.textMuted),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${h.predictedAqi}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: horizonAqiColor,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'AQI',
                            style: TextStyle(fontSize: 10, color: Theme.of(context).extension<AeroTheme>()!.textMuted),
                          ),
                        ],
                      ),
                      Text(
                        'PM2.5: ${h.predictedPm25.toStringAsFixed(1)} µg',
                        style: TextStyle(fontSize: 10, color: Theme.of(context).extension<AeroTheme>()!.textSecondary),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 16),

          // Diurnal Ventilation Tip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Text('💡', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    forecast.diurnalTip,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).extension<AeroTheme>()!.textPrimary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
