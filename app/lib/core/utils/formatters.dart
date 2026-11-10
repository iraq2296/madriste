import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/models.dart';
import '../l10n/l10n.dart';

/// Locale-aware formatting helpers.
extension FormatX on BuildContext {
  String get _intlLocale => language == AppLanguage.en ? 'en' : 'ar';

  String formatDate(DateTime d, {String pattern = 'd MMMM yyyy'}) =>
      DateFormat(pattern, _intlLocale).format(d);

  String formatShortDate(DateTime d) => DateFormat('d MMM', _intlLocale).format(d);

  String formatDateTime(DateTime d) => DateFormat('d MMM yyyy – HH:mm', _intlLocale).format(d);

  String formatTime(DateTime d) => DateFormat('HH:mm', _intlLocale).format(d);

  String weekdayName(int weekday) => DateFormat('EEEE', _intlLocale).format(DateTime(2024, 1, weekday));

  /// "منذ 5 دقائق" / "5 min ago".
  String relativeTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    final en = language == AppLanguage.en;
    if (diff.isNegative) return formatShortDate(d);
    if (diff.inMinutes < 1) return en ? 'now' : 'الآن';
    if (diff.inMinutes < 60) return en ? '${diff.inMinutes} min ago' : 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return en ? '${diff.inHours} h ago' : 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return en ? '${diff.inDays} d ago' : 'منذ ${diff.inDays} يوم';
    return formatShortDate(d);
  }

  String formatIqd(num amount) {
    final f = NumberFormat.decimalPattern(_intlLocale).format(amount);
    return language == AppLanguage.en ? '$f IQD' : '$f د.ع';
  }

  String percent(double value, {int digits = 0}) => '${value.toStringAsFixed(digits)}%';

  /// Section letter localized (A → أ).
  String sectionLabel(String section) {
    if (language == AppLanguage.en) return section;
    const map = {'A': 'أ', 'B': 'ب', 'C': 'ج', 'D': 'د', 'E': 'هـ', 'F': 'و'};
    return map[section] ?? section;
  }

  /// "الخامس العلمي (أ)" / "Grade 5 Scientific (A)".
  String classGroupLabel(ClassGroup cg, {bool withStage = false}) {
    final grade = gradeName(cg.stage, cg.grade);
    final track = cg.track == Track.none ? '' : ' ${tr(cg.track.l10nKey)}';
    final stage = withStage ? ' – ${tr(cg.stage.l10nKey)}' : '';
    return '$grade$track (${sectionLabel(cg.section)})$stage';
  }

  String gradeName(SchoolStage stage, int grade) {
    if (language == AppLanguage.en) return 'Grade $grade';
    const ar = ['', 'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس'];
    const ku = ['', 'یەکەم', 'دووەم', 'سێیەم', 'چوارەم', 'پێنجەم', 'شەشەم'];
    final names = language == AppLanguage.ku ? ku : ar;
    return grade >= 1 && grade <= 6 ? names[grade] : '$grade';
  }

  String subjectName(Subject? s) => s == null ? '—' : s.name.of(language);
}

