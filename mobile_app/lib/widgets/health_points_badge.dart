import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';

class HealthPointsBadge extends StatelessWidget {
  const HealthPointsBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).extension<AeroTheme>()!.primaryEmerald.withValues(alpha: 0.2),
            Theme.of(context).extension<AeroTheme>()!.accentCyan.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald, size: 14),
          SizedBox(width: 4),
          Text(
            '${currentUserProfile.healthPoints} HP',
            style: TextStyle(
              color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
