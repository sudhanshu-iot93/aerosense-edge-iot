// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:aerosense_edge/models/air_quality_state.dart';
import 'package:aerosense_edge/theme/app_theme.dart';
import 'package:aerosense_edge/services/edge_api_service.dart';

void main() {
  group('AeroSense Edge Models & Simulation Tests', () {
    test('State model parses JSON payload correctly', () {
      final sampleJson = {
        'telemetry': {
          'pm1': 12.0,
          'pm25': 18.5,
          'pm10': 32.0,
          'no2': 0.025,
          'co': 0.65,
          'co2': 450.0,
          'voc': 35.0,
          'tmp': 27.2,
          'hum': 48.0,
          'bat': 94,
          'vin': 3.31,
          'charging': true,
        },
        'features': {
          'pm_ratio': 0.58,
          'co_to_co2_ratio': 1.44,
          'no2_to_voc_ratio': 0.71,
          'aqi': 55,
          'aqi_category': 'Satisfactory',
          'primary_pollutant': 'PM2.5',
        },
        'source_attribution': {
          'primary_source': 'Clean Baseline',
          'confidence_percent': 95,
          'description': 'Normal ambient atmosphere.',
          'attributions': [
            {'factor': 'Ratio', 'evidence': 'Normal'}
          ],
        },
        'forecast': {
          'overall_trend': 'STABLE',
          'forecast_horizons': [
            {'label': '+1 Hour', 'target_time_str': '16:00', 'predicted_pm25': 19.0, 'predicted_aqi': 56}
          ],
          'diurnal_tip': 'Good ventilation window.',
        },
        'advisory': {
          'headline': 'Satisfactory air quality.',
          'urgent_alerts': <String>[],
          'citizen_actions': [
            {'action': 'Outdoor cardio safe', 'timing': 'Current'}
          ],
        },
        'mesh_topology': [
          {'node_id': 'NODE-01', 'node_name': 'Central Quad', 'aqi': 55, 'source': 'Clean Baseline', 'battery': 94}
        ],
        'compression_stats': {
          'raw_bytes': 12000,
          'compressed_bytes': 1200,
          'bandwidth_savings_pct': 90.0,
        },
        'system_info': {
          'hardware': 'Arduino UNO Q',
          'mpu': 'Qualcomm QRB2210',
          'mcu': 'STM32U585',
        }
      };

      final state = AeroSenseState.fromJson(sampleJson, isLiveConnected: true);
      expect(state.features.aqi, 55);
      expect(state.features.aqiCategory, 'Satisfactory');
      expect(state.sourceAttribution.primarySource, 'Clean Baseline');
      expect(state.meshTopology.length, 1);
      expect(state.meshTopology.first.nodeName, 'Central Quad');
      expect(state.compressionStats.bandwidthSavingsPct, 90.0);
    });

    test('NAQI Color scale helper returns accurate category colors', () {
      expect(AeroTheme.getAqiCategory(30), 'Good');
      expect(AeroTheme.getAqiCategory(85), 'Satisfactory');
      expect(AeroTheme.getAqiCategory(150), 'Moderate');
      expect(AeroTheme.getAqiCategory(250), 'Poor');
      expect(AeroTheme.getAqiCategory(350), 'Very Poor');
      expect(AeroTheme.getAqiCategory(450), 'Severe');

      expect(AeroTheme.getAqiColor(30), AeroTheme.dark.aqiGood);
      expect(AeroTheme.getAqiColor(350), AppTheme.aqiVeryPoor);
    });

    test('Source icons mapping returns emoji', () {
      expect(AeroTheme.getSourceIcon('Traffic Exhaust'), '🚗');
      expect(AeroTheme.getSourceIcon('Garbage Burning'), '🔥');
      expect(AeroTheme.getSourceIcon('Construction Dust'), '🏗️');
      expect(AeroTheme.getSourceIcon('Cooking Smoke'), '🍳');
      expect(AeroTheme.getSourceIcon('Crop Residue'), '🌾');
      expect(AeroTheme.getSourceIcon('Clean Baseline'), '🌿');
    });

    test('EdgeApiService generates accurate offline scenario simulation', () async {
      final service = EdgeApiService();
      await service.setScenario('Garbage Fire');
      final state = await service.fetchAndUpdateState();

      expect(state.sourceAttribution.primarySource, 'Garbage Burning');
      expect(state.features.aqi, greaterThan(250));
      expect(state.features.coToCo2Ratio, greaterThan(3.0));
      expect(state.advisory.urgentAlerts.isNotEmpty, true);
    });
  });
}
