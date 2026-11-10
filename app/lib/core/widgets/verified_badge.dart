import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Blue verification badge (توثيق بالعلامة الزرقاء).
///
/// PER SPEC:
/// Blue verification badges are available ONLY to:
/// 1. Schools
/// 2. School Managers
/// 3. Teachers
/// 4. Instructors
///
/// MUST NOT be displayed for students or parents.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({
    super.key,
    this.size = 18,
    this.showTooltip = true,
  });

  final double size;
  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.verified,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.check,
          color: Colors.white,
          size: size * 0.65,
        ),
      ),
    );

    if (!showTooltip) return badge;

    return Tooltip(
      message: 'حساب موثّق رسمياً',
      child: badge,
    );
  }
}

