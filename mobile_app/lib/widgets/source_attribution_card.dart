// widgets/source_attribution_card.dart

import 'package:flutter/material.dart';
import '../models/air_quality_state.dart';
import '../theme/app_theme.dart';

class SourceAttributionCard extends StatelessWidget {
  final SourceAttribution attribution;
  final FeaturesData features;

  const SourceAttributionCard({
    super.key,
    required this.attribution,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final icon = AeroTheme.getSourceIcon(attribution.primarySource);
    final aqiColor = AeroTheme.getAqiColor(features.aqi);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: Theme.of(context).extension<AeroTheme>()!.glassCardDecoration(
        borderColor: aqiColor.withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology, size: 20, color: Theme.of(context).extension<AeroTheme>()!.accentCyan),
                  SizedBox(width: 8),
                  Text(
                    'AI SOURCE ATTRIBUTION',
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
                  color: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${attribution.confidencePercent}% Confidence',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).extension<AeroTheme>()!.accentCyan,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Primary Source Result Box
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).extension<AeroTheme>()!.bgSurface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: aqiColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: aqiColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(icon, style: TextStyle(fontSize: 28)),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attribution.primarySource,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        attribution.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).extension<AeroTheme>()!.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 18),
          Text(
            'Stoichiometric Chemical Fingerprints:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Theme.of(context).extension<AeroTheme>()!.textSecondary,
            ),
          ),
          SizedBox(height: 12),

          // Ratio 1: PM2.5 / PM10
          _buildRatioMeter(context, label: 'Fine Particle Ratio (PM2.5 / PM10)',
            valStr: '${features.pmRatio.toStringAsFixed(2)} ${features.pmRatio > 0.65 ? '(Combustion)' : (features.pmRatio < 0.35 ? '(Coarse Dust)' : '(Normal)')}',
            progress: (features.pmRatio).clamp(0.0, 1.0),
            color: features.pmRatio > 0.65 ? Theme.of(context).extension<AeroTheme>()!.aqiPoor : Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
          ),
          SizedBox(height: 10),

          // Ratio 2: CO / CO2
          _buildRatioMeter(context, label: 'Combustion Inefficiency (CO / CO2)',
            valStr: '${features.coToCo2Ratio.toStringAsFixed(2)} ${features.coToCo2Ratio > 3.0 ? '(Smoldering Fire)' : '(Clean)'}',
            progress: (features.coToCo2Ratio / 5.0).clamp(0.0, 1.0),
            color: features.coToCo2Ratio > 3.0 ? Theme.of(context).extension<AeroTheme>()!.aqiVeryPoor : Theme.of(context).extension<AeroTheme>()!.accentCyan,
          ),
          SizedBox(height: 10),

          // Ratio 3: NO2 / VOC
          _buildRatioMeter(context, label: 'Traffic NOx Index (NO2 / VOC)',
            valStr: '${features.no2ToVocRatio.toStringAsFixed(2)} ${features.no2ToVocRatio > 0.8 ? '(High Diesel)' : '(Low)'}',
            progress: (features.no2ToVocRatio / 1.5).clamp(0.0, 1.0),
            color: features.no2ToVocRatio > 0.8 ? Theme.of(context).extension<AeroTheme>()!.aqiModerate : Theme.of(context).extension<AeroTheme>()!.accentIndigo,
          ),

          SizedBox(height: 16),

          // Explainable AI Evidence Chips
          Text(
            'Explainable AI (XAI) Attribution Evidence:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Theme.of(context).extension<AeroTheme>()!.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: attribution.attributions.map((attr) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).extension<AeroTheme>()!.cardHover,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 14, color: Theme.of(context).extension<AeroTheme>()!.accentCyan),
                    SizedBox(width: 6),
                    Text(
                      '${attr.factor}: ${attr.evidence}',
                      style: TextStyle(fontSize: 11, color: Theme.of(context).extension<AeroTheme>()!.textPrimary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRatioMeter(BuildContext context, {
    required String label,
    required String valStr,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 11, color: Theme.of(context).extension<AeroTheme>()!.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              valStr,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).extension<AeroTheme>()!.bgSurface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
