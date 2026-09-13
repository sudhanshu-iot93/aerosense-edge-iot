import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/air_quality_state.dart';

class AqiHistoryChart extends StatelessWidget {
  final ForecastData forecast;

  const AqiHistoryChart({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    if (forecast.forecastHorizons.isEmpty) return SizedBox.shrink();

    // Map forecast horizons to chart spots
    final spots = forecast.forecastHorizons.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.predictedAqi.toDouble());
    }).toList();

    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AeroTheme>()!.bgDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AQI Forecast Trend',
            style: TextStyle(
              color: Theme.of(context).extension<AeroTheme>()!.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < forecast.forecastHorizons.length) {
                          return Text(
                            forecast.forecastHorizons[value.toInt()].label,
                            style: TextStyle(color: Theme.of(context).extension<AeroTheme>()!.textMuted, fontSize: 10),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald.withValues(alpha: 0.2),
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
}
