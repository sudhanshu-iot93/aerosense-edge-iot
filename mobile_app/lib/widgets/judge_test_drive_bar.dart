// widgets/judge_test_drive_bar.dart
// 1-Click Preset Scenario Toolbar for Hackathon Judges

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
    final themeExt = Theme.of(context).extension<AeroTheme>()!;

    final scenarios = [
      {'name': 'Clean Baseline', 'label': '🌿 Clean Air'},
      {'name': 'Garbage Fire', 'label': '🔥 Garbage Burning'},
      {'name': 'Traffic Jam', 'label': '🚗 Traffic Bottleneck'},
      {'name': 'Construction Dust', 'label': '🏗️ Dust Storm'},
      {'name': 'Crop Residue', 'label': '🌾 Crop Residue'},
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD60A).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD60A).withValues(alpha: 0.4)),
            ),
            child: const Text(
              '⚡ JUDGE TEST DRIVE:',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFFD60A),
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...scenarios.map((scen) {
            final isSelected = activeScenario == scen['name'];
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                selected: isSelected,
                label: Text(scen['label']!),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : themeExt.textSecondary,
                ),
                backgroundColor: themeExt.glassSurface,
                selectedColor: themeExt.accentCyan.withValues(alpha: 0.3),
                side: BorderSide(
                  color: isSelected ? themeExt.accentCyan : themeExt.glassBorder,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onSelected: (_) => onScenarioChange(scen['name']!),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              avatar: const Icon(Icons.description_outlined, size: 14, color: Colors.white),
              label: const Text('📄 Incident Report'),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              backgroundColor: themeExt.primaryEmerald.withValues(alpha: 0.25),
              side: BorderSide(color: themeExt.primaryEmerald.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: onOpenIncidentReport,
            ),
          ),
        ],
      ),
    );
  }
}
