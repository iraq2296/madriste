import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../theme/app_colors.dart';
import 'verified_badge.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.user,
    this.size = 46,
    this.showBadge = true,
  });

  final AppUser user;
  final double size;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          user.initials,
          style: TextStyle(
            color: AppColors.navy,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    // Verified badge is ONLY for managers, teachers, instructors (and schools)
    final hasBadge = showBadge && user.badgeVerified && user.role.canHaveBadge;

    if (!hasBadge) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          bottom: -2,
          right: -2,
          child: VerifiedBadge(size: size * 0.38),
        ),
      ],
    );
  }
}

