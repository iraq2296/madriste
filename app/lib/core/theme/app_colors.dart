import 'package:flutter/material.dart';

/// MADRASI brand palette and semantic colors.
///
/// Brand colors are fixed by the identity guide:
/// Primary Blue #1769AA, Dark Navy #0D3B66, Light Blue #EAF4FC, White #FFFFFF.
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF1769AA);
  static const navy = Color(0xFF0D3B66);
  static const lightBlue = Color(0xFFEAF4FC);
  static const white = Color(0xFFFFFFFF);

  // Semantic
  static const success = Color(0xFF22A06B);
  static const warning = Color(0xFFF29F05);
  static const danger = Color(0xFFE5484D);
  static const info = Color(0xFF2D9CDB);
  static const late = Color(0xFFF2994A);
  static const verified = Color(0xFF1D9BF0);

  // Neutrals (light)
  static const textPrimary = Color(0xFF0F1E2E);
  static const textSecondary = Color(0xFF5B6B7C);
  static const border = Color(0xFFDCE6F0);
  static const background = Color(0xFFF5F9FD);

  // Neutrals (dark)
  static const darkBackground = Color(0xFF081624);
  static const darkSurface = Color(0xFF0F2438);
  static const darkCard = Color(0xFF14304A);
  static const darkBorder = Color(0xFF214566);
  static const darkTextSecondary = Color(0xFF9DB2C7);

  /// Accent colors used for subject tiles, charts and category icons.
  static const accents = <Color>[
    Color(0xFF1769AA),
    Color(0xFF22A06B),
    Color(0xFFF29F05),
    Color(0xFF8E5CF6),
    Color(0xFFE5484D),
    Color(0xFF0FA5B5),
    Color(0xFFEC6A3C),
    Color(0xFF3F51B5),
  ];

  static Color accent(int index) => accents[index.abs() % accents.length];

  static const headerGradient = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [navy, primary],
  );
}

