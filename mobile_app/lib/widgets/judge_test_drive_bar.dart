// widgets/judge_test_drive_bar.dart
// Executive Mission Control Scenario Toolbar

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class JudgeTestDriveBar extends StatelessWidget {
  final String activeScenario;
  final Function(String) onScenarioChange;
  final VoidCallback onOpenIncidentReport;

  const JudgeTestDriveBar({
    super.key,
    required this.activeScenario,
    required this.onScenarioChange,
    required this.onOpenIncidentReport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AeroTheme>()!;

    final scenarios = [
      {'name': 'Clean Baseline', 'label': '🌿 Clean Air'},
      {'name': 'Garbage Fire', 'label': '🔥 Garbage Burning'},
      {'name': 'Traffic Jam', 'label': '🚗 Traffic Bottleneck'},
      {'name': 'Construction Dust', 'label': '🏗️ Dust Storm'},
      {'name': 'Crop Residue', 'label': '🌾 Crop Residue'},
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          // Simulation badge
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: theme.accentCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.accentCyan.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.accentCyan,
                    boxShadow: [
                      BoxShadow(
                        color: theme.accentCyan,
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'SIMULATION',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: theme.accentCyan,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          ...scenarios.map((scen) {
            final isSelected = activeScenario == scen['name'];
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InkWell(
                onTap: () => onScenarioChange(scen['name']!),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.accentCyan.withValues(alpha: 0.18)
                        : theme.bgSurface.withValues(alpha: 0.60),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? theme.accentCyan.withValues(alpha: 0.65)
                          : Colors.white.withValues(alpha: 0.12),
                      width: 1.1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.accentCyan.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      scen['label']!,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected ? Colors.white : theme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          // Incident report export action
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: onOpenIncidentReport,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryEmerald.withValues(alpha: 0.22),
                      theme.primaryEmerald.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.primaryEmerald.withValues(alpha: 0.45),
                    width: 1.1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 14,
                      color: theme.primaryEmerald,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Report',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryEmerald,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
