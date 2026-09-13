// widgets/ai_benchmark_card.dart
// Glassmorphic Edge AI Execution Diagnostics Card

import 'package:flutter/material.dart';
import '../models/air_quality_state.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class AiBenchmarkCard extends StatelessWidget {
  final AiBenchmark benchmark;

  const AiBenchmarkCard({super.key, required this.benchmark});

  @override
  Widget build(BuildContext context) {
    final themeExt = Theme.of(context).extension<AeroTheme>()!;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 18, color: themeExt.accentCyan),
                  const SizedBox(width: 6),
                  const Text(
                    'Edge AI Diagnostics',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: themeExt.primaryEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeExt.primaryEmerald.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '0% Cloud • Air-Gapped',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: themeExt.primaryEmerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2x2 Grid Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'INFERENCE LATENCY',
                  value: '${benchmark.inferenceTimeMs.toStringAsFixed(2)} ms',
                  sub: 'Sub-Millisecond Edge',
                  valColor: themeExt.primaryEmerald,
                  themeExt: themeExt,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'RAM FOOTPRINT',
                  value: '${benchmark.memoryFootprintKb} KB',
                  sub: 'Qualcomm QRB2210',
                  valColor: themeExt.accentCyan,
                  themeExt: themeExt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'QUANTIZATION',
                  value: 'INT8 Fixed',
                  sub: 'Zero Float Overhead',
                  valColor: themeExt.accentAmber,
                  themeExt: themeExt,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'MCU POLLING',
                  value: '160 MHz DMA',
                  sub: 'STM32U585 Core',
                  valColor: Colors.white70,
                  themeExt: themeExt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Latency comparison progress bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeExt.glassSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeExt.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Latency vs. Cloud Roundtrip',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: themeExt.textSecondary),
                    ),
                    Text(
                      '99.6% Faster',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: themeExt.primaryEmerald),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 20,
                    color: Colors.white.withValues(alpha: 0.05),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          color: themeExt.primaryEmerald,
                          alignment: Alignment.center,
                          child: const Text('Edge: 0.8ms', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black)),
                        ),
                        Expanded(
                          child: Container(
                            color: themeExt.aqiPoor.withValues(alpha: 0.25),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 8),
                            child: Text('AWS Cloud: 240ms', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: themeExt.aqiPoor)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required String sub,
    required Color valColor,
    required AeroTheme themeExt,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: themeExt.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeExt.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: themeExt.textMuted,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: valColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontSize: 9,
              color: themeExt.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
