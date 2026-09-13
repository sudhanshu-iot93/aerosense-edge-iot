// screens/sensors_screen.dart

import 'package:flutter/material.dart';
import '../models/air_quality_state.dart';
import '../theme/app_theme.dart';
import '../widgets/telemetry_card.dart';

class SensorsScreen extends StatelessWidget {
  final AeroSenseState state;

  const SensorsScreen({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final telemetry = state.telemetry;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 8-Channel Real-Time Hardware Telemetry Grid
          TelemetryGridWidget(telemetry: telemetry),
          SizedBox(height: 14),

          // Solar & LiFePO4 Battery Subsystem Card
          Container(
            padding: EdgeInsets.all(20),
            decoration: Theme.of(context).extension<AeroTheme>()!.glassCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.solar_power_outlined, size: 20, color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald),
                    SizedBox(width: 8),
                    Text(
                      'POWER & ENERGY HARVESTING',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Theme.of(context).extension<AeroTheme>()!.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildEnergyMetric(context, 
                        label: 'LiFePO4 Chemistry',
                        value: '${telemetry.battery}%',
                        sub: '2,500+ Cycles Lifespan',
                        color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildEnergyMetric(context, 
                        label: 'Bus Voltage',
                        value: '${telemetry.vin.toStringAsFixed(2)} V',
                        sub: telemetry.isCharging ? 'Solar MPPT Active' : 'Battery Discharge',
                        color: Theme.of(context).extension<AeroTheme>()!.accentCyan,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).extension<AeroTheme>()!.bgSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Zero Grid Outage Risk: Node operates 36+ continuous hours on solar reserve.',
                          style: TextStyle(fontSize: 11, color: Theme.of(context).extension<AeroTheme>()!.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14),

          // Heterogeneous Dual-Compute Architecture
          Container(
            padding: EdgeInsets.all(20),
            decoration: Theme.of(context).extension<AeroTheme>()!.glassCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.memory, size: 20, color: Theme.of(context).extension<AeroTheme>()!.accentIndigo),
                    SizedBox(width: 8),
                    Text(
                      'ARDUINO UNO Q DUAL-COMPUTE CORE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Theme.of(context).extension<AeroTheme>()!.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),

                _buildComputeLayer(context,
                  chipLabel: 'KPU',
                  chipColor: Theme.of(context).extension<AeroTheme>()!.glowEmerald,
                  title: 'Neural Engine',
                  desc: 'Running local anomaly detection model with 8-bit quantization.',
                ),
                SizedBox(height: 12),
                _buildComputeLayer(context,
                  chipLabel: 'BLE',
                  chipColor: Theme.of(context).extension<AeroTheme>()!.accentCyan,
                  title: 'Mesh Network',
                  desc: 'Synchronizing sensor data with 2 nearby nodes. Latency 14ms.',
                ),
                SizedBox(height: 12),
                _buildComputeLayer(context,
                  chipLabel: 'MCU',
                  chipColor: Theme.of(context).extension<AeroTheme>()!.accentAmber,
                  title: 'Sensor Hub',
                  desc: 'Polling BME688 & SCD41 at 1Hz over I2C. Bus load 4%.',
                ),
                SizedBox(height: 12),

                // Cloud Independence Item
                _buildComputeLayer(context, 
                  chipLabel: 'COST',
                  chipColor: Theme.of(context).extension<AeroTheme>()!.aqiModerate,
                  title: 'Cloud Dependency: 0% (\$0.00 / year)',
                  desc: 'All inference, database retention, and dashboard serving happen 100% locally on the device.',
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEnergyMetric(BuildContext context, {
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AeroTheme>()!.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).extension<AeroTheme>()!.textSecondary)),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
          ),
          SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 10, color: Theme.of(context).extension<AeroTheme>()!.textMuted)),
        ],
      ),
    );
  }

  Widget _buildComputeLayer(BuildContext context, {
    required String chipLabel,
    required Color chipColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AeroTheme>()!.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: chipColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              chipLabel,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: chipColor),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(fontSize: 11, color: Theme.of(context).extension<AeroTheme>()!.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
