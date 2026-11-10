import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../theme/app_colors.dart';

IconData subjectIcon(String? iconKey) => switch (iconKey) {
      'math' => Icons.calculate_rounded,
      'physics' => Icons.bolt_rounded,
      'chemistry' => Icons.science_rounded,
      'biology' => Icons.biotech_rounded,
      'arabic' => Icons.menu_book_rounded,
      'english' => Icons.language_rounded,
      'islamic' => Icons.auto_stories_rounded,
      'computer' => Icons.laptop_mac_rounded,
      'kurdish' => Icons.translate_rounded,
      'history' => Icons.history_edu_rounded,
      'geography' => Icons.public_rounded,
      'science' => Icons.psychology_rounded,
      _ => Icons.book_rounded,
    };

Color attendanceColor(AttendanceStatus status) => switch (status) {
      AttendanceStatus.present => AppColors.success,
      AttendanceStatus.absent => AppColors.danger,
      AttendanceStatus.late => AppColors.late,
      AttendanceStatus.excused => AppColors.info,
    };

IconData attendanceIcon(AttendanceStatus status) => switch (status) {
      AttendanceStatus.present => Icons.check_circle_rounded,
      AttendanceStatus.absent => Icons.cancel_rounded,
      AttendanceStatus.late => Icons.access_time_filled_rounded,
      AttendanceStatus.excused => Icons.event_available_rounded,
    };

