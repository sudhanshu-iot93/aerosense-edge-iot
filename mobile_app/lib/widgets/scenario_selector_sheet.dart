// widgets/scenario_selector_sheet.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScenarioSelectorSheet extends StatelessWidget {
  final String activeScenario;
  final Function(String) onScenarioSelected;

  const ScenarioSelectorSheet({
    super.key,
    required this.activeScenario,
    required this.onScenarioSelected,
  });

  static void show(BuildContext context, String currentScenario, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).extension<AeroTheme>()!.bgDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ScenarioSelectorSheet(
        activeScenario: currentScenario,
        onScenarioSelected: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scenarios = [
      {
        'name': 'Clean Baseline',
        'icon': '🌿',
        'title': 'Clean Ambient Air',
        'subtitle': 'Normal background trace gases & safe particulate level.',
      },
      {
        'name': 'Traffic Jam',
        'icon': '🚗',
        'title': 'Heavy Traffic Jam',
        'subtitle': 'Dense diesel NOx spike, elevated CO, and fine PM2.5.',
      },
      {
        'name': 'Garbage Fire',
        'icon': '🔥',
        'title': 'Illegal Garbage Burning',
        'subtitle': 'Toxic VOC spike, high CO/CO2 smoldering ratio, thick smoke.',
      },
      {
        'name': 'Construction Dust',
        'icon': '🏗️',
        'title': 'Construction Excavation',
        'subtitle': 'High coarse PM10 spike (>250 µg/m³), normal gas baselines.',
      },
      {
        'name': 'Cooking Smoke',
        'icon': '🍳',
        'title': 'Kitchen & Cooking Smoke',
        'subtitle': 'Elevated VOCs, high CO2 (>1000 ppm), kitchen aerosols.',
      },
      {
        'name': 'Crop Residue',
        'icon': '🌾',
        'title': 'Crop Residue Burning',
        'subtitle': 'Dense agricultural biomass smoke plume with afternoon surge.',
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AeroTheme>()!.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).extension<AeroTheme>()!.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulate Environmental Event',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).extension<AeroTheme>()!.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Injects stoichiometric signatures into Edge AI core',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).extension<AeroTheme>()!.textMuted),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, color: Theme.of(context).extension<AeroTheme>()!.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: scenarios.length,
              separatorBuilder: (_, _) => SizedBox(height: 10),
              itemBuilder: (context, index) {
                final sc = scenarios[index];
                final isSelected = sc['name'] == activeScenario;

                return InkWell(
                  onTap: () {
                    onScenarioSelected(sc['name']!);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald.withValues(alpha: 0.15) : Theme.of(context).extension<AeroTheme>()!.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald : Theme.of(context).extension<AeroTheme>()!.cardBorder,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(sc['icon']!, style: TextStyle(fontSize: 26)),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sc['title']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Theme.of(context).extension<AeroTheme>()!.primaryEmerald : Theme.of(context).extension<AeroTheme>()!.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                sc['subtitle']!,
                                style: TextStyle(fontSize: 11, color: Theme.of(context).extension<AeroTheme>()!.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
