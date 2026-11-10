import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({
    super.key,
    required this.role,
    this.compact = false,
  });

  final UserRole role;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (role) {
      UserRole.manager => (AppColors.navy, Icons.admin_panel_settings_rounded),
      UserRole.teacher => (AppColors.primary, Icons.school_rounded),
      UserRole.instructor => (const Color(0xFF0FA5B5), Icons.co_present_rounded),
      UserRole.student => (AppColors.success, Icons.backpack_rounded),
      UserRole.parent => (AppColors.warning, Icons.family_restroom_rounded),
      UserRole.superAdmin => (const Color(0xFF8E5CF6), Icons.shield_rounded),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              context.tr(role.l10nKey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
