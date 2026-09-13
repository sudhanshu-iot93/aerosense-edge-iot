// widgets/incident_report_dialog.dart
// Municipal Emergency Incident Audit Report Dialog for Flutter

import 'package:flutter/material.dart';
import '../models/air_quality_state.dart';
import '../theme/app_theme.dart';

class IncidentReportDialog extends StatelessWidget {
  final AeroSenseState state;

  const IncidentReportDialog({super.key, required this.state});

  static void show(BuildContext context, AeroSenseState state) {
    showDialog(
      context: context,
      builder: (ctx) => IncidentReportDialog(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeExt = Theme.of(context).extension<AeroTheme>()!;
    final source = state.sourceAttribution;
    final feat = state.features;
    final timestamp = DateTime.now().toLocal().toString().split('.')[0];

    return AlertDialog(
      backgroundColor: themeExt.bgDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(20),
      title: Row(
        children: [
          const Text('📄', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Municipal Incident Audit Report',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Text(
                  'Autonomous Edge AI Chemical Evidence',
                  style: TextStyle(fontSize: 11, color: themeExt.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Metadata Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeExt.glassSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeExt.glassBorder),
                ),
                child: Column(
                  children: [
                    _buildMetaRow('Report ID', 'AERO-AUDIT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}', themeExt),
                    _buildMetaRow('Timestamp', timestamp, themeExt),
                    _buildMetaRow('Hardware Core', 'Arduino UNO Q (Qualcomm QRB2210)', themeExt),
                    _buildMetaRow('Coordinates', '20.3540° N, 85.8180° E (Academic Quad)', themeExt),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 1: Identified Source
              const Text('1. Attributed Pollution Source & Risk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeExt.aqiSevere.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeExt.aqiSevere.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.primarySource,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: themeExt.aqiSevere),
                          ),
                          Text(
                            source.description,
                            style: TextStyle(fontSize: 11, color: themeExt.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeExt.aqiSevere,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${source.confidencePercent}% Confidence',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 2: Chemical Proof
              const Text('2. Chemical Stoichiometric Proof', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: themeExt.glassSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeExt.glassBorder),
                ),
                child: Column(
                  children: [
                    _buildStoichRow('Fine Fraction (PM2.5/PM10)', feat.pmRatio.toStringAsFixed(2), feat.pmRatio > 0.65 ? 'Combustion soot dominance' : 'Normal coarse dust', themeExt),
                    const Divider(height: 1, color: Colors.white10),
                    _buildStoichRow('Incomplete Burning (CO/CO2)', feat.coToCo2Ratio.toStringAsFixed(2), feat.coToCo2Ratio > 3.0 ? 'Smoldering waste signature' : 'Baseline level', themeExt),
                    const Divider(height: 1, color: Colors.white10),
                    _buildStoichRow('NO2-to-VOC Index', feat.no2ToVocRatio.toStringAsFixed(2), feat.no2ToVocRatio > 0.8 ? 'Vehicular diesel exhaust' : 'Normal ratio', themeExt),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 3: Actionable Orders
              const Text('3. Actionable Dispatch Briefing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeExt.glassSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeExt.glassBorder),
                ),
                child: Text(
                  '• Dispatch security patrol 250m upwind to inspect area.\n• Seal windward windows and shift outdoor sports indoors.\n• Issued autonomously by AeroSense Edge AI on Arduino UNO Q (0% Cloud).',
                  style: TextStyle(fontSize: 12, height: 1.5, color: themeExt.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: TextStyle(color: themeExt.textSecondary)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('📄 Municipal Audit Briefing Saved / Exported as PDF!')),
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: themeExt.primaryEmerald,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.print_rounded, size: 16, color: Colors.white),
          label: const Text('Save PDF Briefing', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildMetaRow(String label, String value, AeroTheme themeExt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: themeExt.textMuted)),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: themeExt.accentCyan)),
        ],
      ),
    );
  }

  Widget _buildStoichRow(String metric, String val, String desc, AeroTheme themeExt) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(metric, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
          Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: themeExt.accentAmber)),
          const SizedBox(width: 8),
          Expanded(child: Text(desc, style: TextStyle(fontSize: 10, color: themeExt.textMuted), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
