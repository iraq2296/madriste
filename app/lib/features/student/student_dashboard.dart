import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/read_only_banner.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/ui_helpers.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final store = ref.watch(dataStoreProvider);
    final theme = Theme.of(context);

    final school = store.schoolsOf(user.id).firstOrNull;
    final classGroup = store.classOfStudent(user.id);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ReadOnlyBanner(),
            Expanded(
              child: IndexedStack(
                index: _currentNavIndex,
                children: [
                  _buildHomeTab(context, user, school, classGroup, store, theme),
                  _buildLessonsTab(context, user, classGroup, store, theme),
                  _buildGradesAndAttendanceTab(context, user, school, classGroup, store, theme),
                  _buildScheduleTab(context, user, classGroup, store, theme),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (i) => setState(() => _currentNavIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: context.tr('nav.home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book_rounded),
            label: 'الدروس',
          ),
          NavigationDestination(
            icon: const Icon(Icons.fact_check_outlined),
            selectedIcon: const Icon(Icons.fact_check_rounded),
            label: 'الدرجات والحضور',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label: 'الجدول',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(
    BuildContext context,
    AppUser user,
    School? school,
    ClassGroup? classGroup,
    dynamic store,
    ThemeData theme,
  ) {
    // Recent grades for this student
    final studentGrades = store.grades.where((g) => g.studentId == user.id).toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    // Attendance stats
    final studentAtt = store.attendance.where((a) => a.studentId == user.id).toList();
    final totalAtt = studentAtt.length;
    final presentCount = studentAtt.where((a) => a.status == AttendanceStatus.present).length;
    final attPercent = totalAtt > 0 ? (presentCount / totalAtt) * 100 : 100.0;

    // Recent lessons
    final classLessons = classGroup == null
        ? <Lesson>[]
        : (store.lessons.where((l) => l.classGroupId == classGroup.id).toList()
          ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt)));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card inspired by identity guide (Navy/Primary gradient)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                AppAvatar(user: user, size: 58, showBadge: false),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        classGroup != null
                            ? '${context.classGroupLabel(classGroup, withStage: true)} • ${school?.name ?? ''}'
                            : school?.name ?? 'طالب مدرستي',
                        style: const TextStyle(
                          color: Color(0xFFD6EAFB),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  tooltip: context.tr('nav.notifications'),
                ),
                IconButton(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  tooltip: context.tr('nav.settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick statistics cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'نسبة الحضور',
                  value: '${attPercent.toStringAsFixed(0)}%',
                  subtitle: '$presentCount من $totalAtt حصة',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  onTap: () => setState(() => _currentNavIndex = 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'المكتبة والوزاريات',
                  value: '${store.library.length}',
                  subtitle: 'كتاب وملزمة',
                  icon: Icons.local_library_outlined,
                  color: AppColors.primary,
                  onTap: () => context.push('/library'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showJoinTeacherDialog(context, store, user),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text(context.tr('student.joinTeacher')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/messages'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: Text(context.tr('nav.messages')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Subjects grid ("موادي")
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'موادي الدراسية',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              TextButton(
                onPressed: () => setState(() => _currentNavIndex = 1),
                child: Text(context.tr('common.viewAll')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: store.subjects.length > 6 ? 6 : store.subjects.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, i) {
              final sub = store.subjects[i];
              final color = AppColors.accent(sub.colorIndex);
              return InkWell(
                onTap: () => setState(() => _currentNavIndex = 1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(subjectIcon(sub.iconKey), color: color, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sub.name.of(context.language),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Recent lessons section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('student.recentLessons'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              TextButton(
                onPressed: () => setState(() => _currentNavIndex = 1),
                child: Text(context.tr('common.viewAll')),
              ),
            ],
          ),
          if (classLessons.isEmpty)
            const EmptyState(title: 'لا توجد دروس منشورة بعد')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: classLessons.length > 3 ? 3 : classLessons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final lesson = classLessons[i];
                final sub = store.subjectById(lesson.subjectId);
                return _buildLessonCard(context, lesson, sub, store);
              },
            ),

          const SizedBox(height: 24),

          // Recent grades
          Text(
            context.tr('student.recentGrades'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (studentGrades.isEmpty)
            const EmptyState(title: 'لا توجد درجات مرصودة حتى الآن')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: studentGrades.length > 4 ? 4 : studentGrades.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final gr = studentGrades[i];
                final sub = store.subjectById(gr.subjectId);
                return _buildGradeCard(context, gr, sub);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLessonsTab(
    BuildContext context,
    AppUser user,
    ClassGroup? classGroup,
    dynamic store,
    ThemeData theme,
  ) {
    if (classGroup == null) {
      return const EmptyState(title: 'أنت غير مسجل في أي شعبة دراسية حالياً');
    }
    final lessons = store.lessons.where((l) => l.classGroupId == classGroup.id).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الدروس والمحتوى التعليمي'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'دروس الصف والشعبة'),
              Tab(text: 'الإعلانات المدرسية'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            lessons.isEmpty
                ? const EmptyState(title: 'لا توجد دروس منشورة لشعبتك بعد')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: lessons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final l = lessons[i];
                      final s = store.subjectById(l.subjectId);
                      return _buildLessonCard(context, l, s, store);
                    },
                  ),
            _buildAnnouncementsTab(context, store),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsTab(BuildContext context, dynamic store) {
    final list = store.announcements;
    if (list.isEmpty) return const EmptyState(title: 'لا توجد إعلانات مدرسية');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final an = list[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        an.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(an.body, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 10),
                Text(
                  context.relativeTime(an.createdAt),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradesAndAttendanceTab(
    BuildContext context,
    AppUser user,
    School? school,
    ClassGroup? classGroup,
    dynamic store,
    ThemeData theme,
  ) {
    final grades = store.grades.where((g) => g.studentId == user.id).toList();
    final atts = store.attendance.where((a) => a.studentId == user.id).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الدرجات وسجل الحضور'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الدرجات والنتائج'),
              Tab(text: 'سجل حضور الحصص'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Grades
            grades.isEmpty
                ? const EmptyState(title: 'لا توجد درجات معلنة')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: grades.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final gr = grades[i];
                      final sub = store.subjectById(gr.subjectId);
                      return _buildGradeCard(context, gr, sub);
                    },
                  ),
            // Tab 2: Attendance per class session
            atts.isEmpty
                ? const EmptyState(title: 'لا يوجد سجل حضور بعد')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: atts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final a = atts[i];
                      final sub = store.subjectById(a.subjectId);
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: attendanceColor(a.status).withValues(alpha: 0.15),
                            child: Icon(attendanceIcon(a.status), color: attendanceColor(a.status), size: 22),
                          ),
                          title: Text(
                            '${sub?.name.of(context.language) ?? "مادة"} • ${a.sessionStart} - ${a.sessionEnd}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(context.formatDate(a.date)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: attendanceColor(a.status).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              context.tr(a.status.l10nKey),
                              style: TextStyle(
                                color: attendanceColor(a.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTab(
    BuildContext context,
    AppUser user,
    ClassGroup? classGroup,
    dynamic store,
    ThemeData theme,
  ) {
    if (classGroup == null) return const EmptyState(title: 'لا يوجد جدول للشعبة');
    final entries = store.schedule.where((e) => e.classGroupId == classGroup.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('جدول الحصص الأسبوعي'),
      ),
      body: entries.isEmpty
          ? const EmptyState(title: 'لم يقم المدرسون بإضافة جدول الحصص بعد')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 7, // Iraqi week (Sunday to Thursday + Fri/Sat)
              itemBuilder: (context, dayIndex) {
                final day = (dayIndex == 0) ? DateTime.sunday : dayIndex;
                final dayEntries = entries.where((e) => e.weekday == day).toList()
                  ..sort((a, b) => a.start.compareTo(b.start));

                if (dayEntries.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        context.weekdayName(day),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    ...dayEntries.map((e) {
                      final sub = store.subjectById(e.subjectId);
                      final teacher = store.userById(e.teacherId);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                            child: Icon(subjectIcon(sub?.iconKey), color: AppColors.primary),
                          ),
                          title: Text(
                            sub?.name.of(context.language) ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('المدرّس: ${teacher?.fullName ?? "—"}'),
                          trailing: Text(
                            '${e.start} – ${e.end}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildLessonCard(BuildContext context, Lesson lesson, Subject? sub, dynamic store) {
    final typeIcon = switch (lesson.type) {
      LessonType.pdf => Icons.picture_as_pdf_rounded,
      LessonType.booklet => Icons.book_rounded,
      LessonType.image => Icons.image_rounded,
      LessonType.board => Icons.border_color_rounded,
      LessonType.video => Icons.videocam_rounded,
      LessonType.announcement => Icons.campaign_rounded,
      LessonType.text => Icons.text_snippet_rounded,
    };

    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(typeIcon, color: AppColors.primary),
        ),
        title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${sub?.name.of(context.language) ?? ""} • ${context.relativeTime(lesson.publishedAt)}',
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {
          // View lesson content sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(typeIcon, color: AppColors.primary, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          lesson.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(lesson.body, style: const TextStyle(fontSize: 15, height: 1.5)),
                  if (lesson.attachmentName != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attachment_rounded, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lesson.attachmentName!,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
                            ),
                          ),
                          const Text('عرض داخل التطبيق', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradeCard(BuildContext context, GradeEntry gr, Subject? sub) {
    final pct = gr.percentage;
    final isPassing = pct >= 50;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isPassing ? AppColors.success : AppColors.danger).withValues(alpha: 0.15),
          child: Icon(
            isPassing ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isPassing ? AppColors.success : AppColors.danger,
          ),
        ),
        title: Text(gr.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${sub?.name.of(context.language) ?? ""} • ${context.tr(gr.examType.l10nKey)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${gr.score.toStringAsFixed(gr.score.truncateToDouble() == gr.score ? 0 : 1)} / ${gr.maxScore.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              '(${pct.toStringAsFixed(0)}%)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isPassing ? AppColors.success : AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinTeacherDialog(BuildContext context, dynamic store, AppUser user) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('student.joinTeacher')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أدخل رمز المدرّس الذي زوّدك به لمعاينة دروسه والتواصل معه:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: InputDecoration(
                hintText: context.tr('student.teacherCodeHint'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              final code = codeCtrl.text.trim().toUpperCase();
              final teacher = store.users.firstWhere(
                (u) => u.teacherCode == code,
                orElse: () => null,
              );
              if (teacher != null) {
                store.follows.add(TeacherFollow(studentId: user.id, teacherId: teacher.id, schoolId: 'sch1'));
                store.commit();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم الانضمام للأستاذ ${teacher.fullName} بنجاح')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('رمز المدرّس غير صحيح')),
                );
              }
            },
            child: Text(context.tr('common.confirm')),
          ),
        ],
      ),
    );
  }
}

