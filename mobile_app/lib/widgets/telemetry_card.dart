// widgets/telemetry_card.dart

import 'package:flutter/material.dart';
import '../models/air_quality_state.dart';
import '../theme/app_theme.dart';

class TelemetryGridWidget extends StatelessWidget {
  final TelemetryData telemetry;

  const TelemetryGridWidget({
    super.key,
    required this.telemetry,
  });

  @override
  Widget build(BuildContext context) {
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
                  Icon(Icons.developer_board, size: 20, color: Theme.of(context).extension<AeroTheme>()!.accentCyan),
                  SizedBox(width: 8),
                  Text(
                    'HARDWARE TELEMETRY',
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
                  color: Theme.of(context).extension<AeroTheme>()!.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      telemetry.isCharging ? Icons.battery_charging_full : Icons.battery_full,
                      size: 14,
                      color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '${telemetry.battery}% • ${telemetry.vin.toStringAsFixed(2)}V',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).extension<AeroTheme>()!.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Real-Time STM32U585 Microcontroller Ingestion (8 Channels):',
            style: TextStyle(fontSize: 12, color: Theme.of(context).extension<AeroTheme>()!.textMuted),
          ),
          SizedBox(height: 16),

          // 2-Column Responsive Grid of Sensors
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _buildSensorTile(context,
                name: 'PM2.5 (Fine)',
                value: telemetry.pm25.toStringAsFixed(1),
                unit: 'µg/m³',
                status: telemetry.pm25 <= 30 ? 'Normal' : (telemetry.pm25 <= 60 ? 'Moderate' : 'High'),
                statusColor: telemetry.pm25 <= 30 ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald : (telemetry.pm25 <= 60 ? Theme.of(context).extension<AeroTheme>()!.aqiModerate : Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor),
                progress: (telemetry.pm25 / 150).clamp(0.0, 1.0),
              ),
              _buildSensorTile(context,
                name: 'PM10 (Coarse)',
                value: telemetry.pm10.toStringAsFixed(1),
                unit: 'µg/m³',
                status: telemetry.pm10 <= 50 ? 'Normal' : (telemetry.pm10 <= 100 ? 'Moderate' : 'High'),
                statusColor: telemetry.pm10 <= 50 ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald : (telemetry.pm10 <= 100 ? Theme.of(context).extension<AeroTheme>()!.aqiModerate : Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor),
                progress: (telemetry.pm10 / 300).clamp(0.0, 1.0),
              ),
              _buildSensorTile(context,
                name: 'NO2 (Traffic)',
                value: telemetry.no2.toStringAsFixed(3),
                unit: 'ppm',
                status: telemetry.no2 <= 0.04 ? 'Safe' : 'Elevated',
                statusColor: telemetry.no2 <= 0.04 ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald : Theme.of(context).extension<AeroTheme>()!.aqiModerate,
                progress: (telemetry.no2 / 0.1).clamp(0.0, 1.0),
              ),
              _buildSensorTile(context,
                name: 'CO (Carbon Mono)',
                value: telemetry.co.toStringAsFixed(2),
                unit: 'ppm',
                status: telemetry.co <= 2.0 ? 'Safe' : 'Smoldering',
                statusColor: telemetry.co <= 2.0 ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald : Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor,
                progress: (telemetry.co / 10.0).clamp(0.0, 1.0),
              ),
              _buildSensorTile(context,
                name: 'CO2 (SCD41)',
                value: telemetry.co2.toStringAsFixed(0),
                unit: 'ppm',
                status: telemetry.co2 <= 600 ? 'Fresh' : (telemetry.co2 <= 1000 ? 'Normal' : 'Stuffy'),
                statusColor: telemetry.co2 <= 800 ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald : Theme.of(context).extension<AeroTheme>()!.aqiModerate,
                progress: (telemetry.co2 / 2000).clamp(0.0, 1.0),
              ),
              _buildSensorTile(context,
                name: 'VOC Index (BME688)',
                value: telemetry.voc.toStringAsFixed(0),
                unit: 'Index',
                status: telemetry.voc <= 50 ? 'Pristine' : (telemetry.voc <= 100 ? 'Good' : 'Spike'),
                statusColor: telemetry.voc <= 100 ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald : Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor,
                progress: (telemetry.voc / 300).clamp(0.0, 1.0),
              ),
              _buildSensorTile(context,
                name: 'Temperature',
                value: telemetry.temp.toStringAsFixed(1),
                unit: '°C',
                status: 'Ambient',
                statusColor: Theme.of(context).extension<AeroTheme>()!.accentCyan,
                progress: (telemetry.temp / 50).clamp(0.0, 1.0),
              ),
              _buildSensorTile(context,
                name: 'Humidity',
                value: telemetry.humidity.toStringAsFixed(1),
                unit: '% RH',
                status: 'Comfort',
                statusColor: Theme.of(context).extension<AeroTheme>()!.accentIndigo,
                progress: (telemetry.humidity / 100).clamp(0.0, 1.0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorTile(BuildContext context, {
    required String name,
    required String value,
    required String unit,
    required String status,
    required Color statusColor,
    required double progress,
  }) {
    return Container(
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
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(fontSize: 11, color: Theme.of(context).extension<AeroTheme>()!.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).extension<AeroTheme>()!.textPrimary),
              ),
              SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(fontSize: 10, color: Theme.of(context).extension<AeroTheme>()!.textMuted),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).extension<AeroTheme>()!.cardHover,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
