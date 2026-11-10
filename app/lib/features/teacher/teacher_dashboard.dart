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
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final rawUser = ref.watch(currentUserProvider);
    final session = ref.watch(sessionProvider);
    final store = ref.watch(dataStoreProvider);
    final isReadOnly = ref.watch(readOnlyProvider);

    final user = (rawUser.role.isTeaching) ? rawUser : (store.userById('t1') ?? rawUser);

    final schools = store.schoolsOf(user.id);
    final currentSchool = store.schoolById(session.activeSchoolId) ?? schools.firstOrNull;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ReadOnlyBanner(),
            Expanded(
              child: IndexedStack(
                index: _currentNavIndex,
                children: [
                  _buildOverviewTab(context, user, currentSchool, schools, store, isReadOnly),
                  _buildAttendanceTab(context, user, currentSchool, store, isReadOnly),
                  _buildPublishingTab(context, user, currentSchool, store, isReadOnly),
                  _buildScheduleTab(context, user, currentSchool, store, isReadOnly),
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
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: context.tr('nav.home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist_rtl_rounded),
            selectedIcon: const Icon(Icons.checklist_rounded),
            label: 'تسجيل الحضور',
          ),
          NavigationDestination(
            icon: const Icon(Icons.post_add_outlined),
            selectedIcon: const Icon(Icons.post_add_rounded),
            label: 'الدروس والدرجات',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label: 'الجدول والامتحانات',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    AppUser user,
    School? currentSchool,
    List<School> schools,
    dynamic store,
    bool isReadOnly,
  ) {
    final classGroups = currentSchool == null ? <ClassGroup>[] : store.classGroupsOfTeacher(user.id, currentSchool.id);
    final totalStudents = classGroups.fold<int>(0, (sum, cg) => sum + store.studentsInClass(cg.id).length);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Teacher header card with Multi-School selector
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppAvatar(user: user, size: 56, showBadge: true),
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
                          const SizedBox(height: 2),
                          Text(
                            user.specialization ?? context.tr(user.role.l10nKey),
                            style: const TextStyle(
                              color: Color(0xFFD6EAFB),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/notifications'),
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => context.push('/settings'),
                      icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Multi-School Switcher Dropdown (Supports working in multiple schools)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: AppColors.navy,
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
                      value: currentSchool?.id,
                      items: schools.map((s) {
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            'المدرسة الحالية: ${s.name} (${s.governorate})',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      onChanged: (newSchoolId) {
                        if (newSchoolId != null) {
                          ref.read(sessionProvider.notifier).switchSchool(newSchoolId);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Teacher join code box
          if (user.teacherCode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('teacher.myCode'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(
                          user.teacherCode!,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.navy),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ رمز المدرّس لمشاركته مع الطلبة')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('نسخ'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),

          // Statistics
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'الشعب المسندة',
                  value: '${classGroups.length}',
                  subtitle: 'في هذه المدرسة',
                  icon: Icons.class_outlined,
                  color: AppColors.primary,
                  onTap: () => setState(() => _currentNavIndex = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'إجمالي الطلبة',
                  value: '$totalStudents',
                  subtitle: 'في شعبك',
                  icon: Icons.people_outline_rounded,
                  color: AppColors.success,
                  onTap: () => setState(() => _currentNavIndex = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isReadOnly
                      ? () => _showReadOnlyNotice(context)
                      : () => setState(() => _currentNavIndex = 1),
                  icon: const Icon(Icons.fact_check_rounded, size: 18),
                  label: const Text('تسجيل حضور الحصة'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/messages'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: Text(context.tr('nav.messages')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Assigned classes overview
          Text(
            'الشعب والصفوف الدراسية',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (classGroups.isEmpty)
            const EmptyState(title: 'لم يتم إسناد شعب لك في هذه المدرسة حتى الآن')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: classGroups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final cg = classGroups[i];
                final students = store.studentsInClass(cg.id);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        cg.section,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    title: Text(context.classGroupLabel(cg, withStage: true), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${students.length} طالباً مسجلاً'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () => _showStudentsBottomSheet(context, cg, students),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ───────────── ATTENDANCE RECORDING (CLASS SESSION WORKFLOW) ─────────────
  Widget _buildAttendanceTab(
    BuildContext context,
    AppUser user,
    School? currentSchool,
    dynamic store,
    bool isReadOnly,
  ) {
    if (currentSchool == null) return const EmptyState(title: 'اختر مدرسة أولاً');

    final classGroups = store.classGroupsOfTeacher(user.id, currentSchool.id);
    final subjects = store.subjectsOfTeacher(user.id, currentSchool.id);

    return _AttendanceRecorderView(
      teacher: user,
      school: currentSchool,
      classGroups: classGroups,
      subjects: subjects,
      store: store,
      isReadOnly: isReadOnly,
    );
  }

  // ───────────── LESSONS & GRADES PUBLISHING ─────────────
  Widget _buildPublishingTab(
    BuildContext context,
    AppUser user,
    School? currentSchool,
    dynamic store,
    bool isReadOnly,
  ) {
    if (currentSchool == null) return const EmptyState(title: 'اختر مدرسة أولاً');

    final myLessons = store.lessons.where((l) => l.teacherId == user.id && l.schoolId == currentSchool.id).toList();
    final myGrades = store.grades.where((g) => g.teacherId == user.id && g.schoolId == currentSchool.id).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الدروس والدرجات'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الدروس المنشورة'),
              Tab(text: 'درجات الامتحانات'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'إضافة جديد',
              onPressed: isReadOnly
                  ? () => _showReadOnlyNotice(context)
                  : () => _showCreateSheet(context, user, currentSchool, store),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Lessons
            myLessons.isEmpty
                ? EmptyState(
                    title: 'لم تقم بنشر دروس بعد',
                    actionLabel: isReadOnly ? null : 'نشر درس جديد',
                    onAction: () => _showCreateLessonDialog(context, user, currentSchool, store),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: myLessons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final l = myLessons[i];
                      final sub = store.subjectById(l.subjectId);
                      final cg = store.classGroupById(l.classGroupId);
                      return Card(
                        child: ListTile(
                          title: Text(l.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${sub?.name.of(context.language) ?? ""} • ${cg != null ? context.classGroupLabel(cg) : ""} • ${context.relativeTime(l.publishedAt)}',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l.type.name.toUpperCase(),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            // Grades
            myGrades.isEmpty
                ? EmptyState(
                    title: 'لم تقم برصد درجات بعد',
                    actionLabel: isReadOnly ? null : 'رصد درجات امتحان',
                    onAction: () => _showCreateGradeDialog(context, user, currentSchool, store),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: myGrades.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final g = myGrades[i];
                      final st = store.userById(g.studentId);
                      final sub = store.subjectById(g.subjectId);
                      return Card(
                        child: ListTile(
                          title: Text('${st?.fullName ?? "طالب"} — ${g.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${sub?.name.of(context.language) ?? ""} • ${context.tr(g.examType.l10nKey)}'),
                          trailing: Text(
                            '${g.score.toStringAsFixed(0)} / ${g.maxScore.toStringAsFixed(0)} (${g.percentage.toStringAsFixed(0)}%)',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
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

  // ───────────── SCHEDULE & EXAMS ─────────────
  Widget _buildScheduleTab(
    BuildContext context,
    AppUser user,
    School? currentSchool,
    dynamic store,
    bool isReadOnly,
  ) {
    if (currentSchool == null) return const EmptyState(title: 'اختر مدرسة أولاً');

    final mySchedule = store.schedule.where((e) => e.teacherId == user.id && e.schoolId == currentSchool.id).toList();
    final myExams = store.exams.where((ex) => ex.teacherId == user.id && ex.schoolId == currentSchool.id).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جدول الحصص والامتحانات'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'حصصي الأسبوعية'),
              Tab(text: 'مواعيد الامتحانات الورقية'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'إضافة حصة أو امتحان',
              onPressed: isReadOnly
                  ? () => _showReadOnlyNotice(context)
                  : () => _showCreateExamDialog(context, user, currentSchool, store),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Schedule
            mySchedule.isEmpty
                ? const EmptyState(title: 'لم تقم بإضافة حصص لجدولك بعد')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: mySchedule.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final se = mySchedule[i];
                      final cg = store.classGroupById(se.classGroupId);
                      final sub = store.subjectById(se.subjectId);
                      return Card(
                        child: ListTile(
                          title: Text(
                            '${context.weekdayName(se.weekday)}: ${sub?.name.of(context.language) ?? ""}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(cg != null ? context.classGroupLabel(cg) : ''),
                          trailing: Text(
                            '${se.start} – ${se.end}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
                          ),
                        ),
                      );
                    },
                  ),
            // Exams
            myExams.isEmpty
                ? const EmptyState(title: 'لا توجد امتحانات ورقية مجدولة')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: myExams.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final ex = myExams[i];
                      final cg = store.classGroupById(ex.classGroupId);
                      final sub = store.subjectById(ex.subjectId);
                      return Card(
                        child: ListTile(
                          title: Text(
                            '${context.tr(ex.type.l10nKey)}: ${sub?.name.of(context.language) ?? ""}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${cg != null ? context.classGroupLabel(cg) : ""} • ${context.formatDate(ex.date)} الساعة ${ex.startTime}',
                          ),
                          trailing: Text(
                            'من ${ex.maxGrade.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
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

  void _showStudentsBottomSheet(BuildContext context, ClassGroup cg, List<AppUser> students) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'طلبة ${context.classGroupLabel(cg, withStage: true)} (${students.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                itemCount: students.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final st = students[i];
                  return ListTile(
                    leading: AppAvatar(user: st, size: 40, showBadge: false),
                    title: Text(st.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(st.phone, textDirection: TextDirection.ltr),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReadOnlyNotice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('banner.readOnlyBlocked')),
        backgroundColor: AppColors.danger,
        action: SnackBarAction(
          label: context.tr('banner.renew'),
          textColor: Colors.white,
          onPressed: () => context.push('/subscription'),
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, AppUser user, School school, dynamic store) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.note_add_rounded, color: AppColors.primary),
              title: const Text('نشر درس جديد', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _showCreateLessonDialog(context, user, school, store);
              },
            ),
            ListTile(
              leading: const Icon(Icons.grade_rounded, color: AppColors.warning),
              title: const Text('رصد درجات امتحان', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _showCreateGradeDialog(context, user, school, store);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateLessonDialog(BuildContext context, AppUser user, School school, dynamic store) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    LessonType selectedType = LessonType.text;

    final classGroups = store.classGroupsOfTeacher(user.id, school.id);
    final subjects = store.subjectsOfTeacher(user.id, school.id);
    if (classGroups.isEmpty || subjects.isEmpty) return;

    String selectedCg = classGroups.first.id;
    String selectedSubj = subjects.first.id;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('نشر درس جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'عنوان الدرس'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'محتوى الدرس أو الملاحظات'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<LessonType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'نوع المحتوى'),
                  items: LessonType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v ?? selectedType),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                store.lessons.insert(
                  0,
                  Lesson(
                    id: store.newId('ls'),
                    schoolId: school.id,
                    classGroupId: selectedCg,
                    subjectId: selectedSubj,
                    teacherId: user.id,
                    yearId: 'y2',
                    title: titleCtrl.text.trim(),
                    body: bodyCtrl.text.trim(),
                    type: selectedType,
                  ),
                );
                store.commit();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('common.saved'))),
                );
              },
              child: Text(context.tr('common.publish')),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGradeDialog(BuildContext context, AppUser user, School school, dynamic store) {
    final titleCtrl = TextEditingController(text: 'امتحان يومي');
    final maxCtrl = TextEditingController(text: '20');
    ExamType selectedExam = ExamType.daily;

    final classGroups = store.classGroupsOfTeacher(user.id, school.id);
    final subjects = store.subjectsOfTeacher(user.id, school.id);
    if (classGroups.isEmpty || subjects.isEmpty) return;

    String selectedCg = classGroups.first.id;
    String selectedSubj = subjects.first.id;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('رصد درجات امتحان'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'اسم الامتحان (مثال: امتحان يومي 1)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الدرجة القصوى (مثال: 10, 20, 50, 100)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ExamType>(
                  value: selectedExam,
                  decoration: const InputDecoration(labelText: 'نوع الامتحان'),
                  items: ExamType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(context.tr(t.l10nKey))))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedExam = v ?? selectedExam),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('teacher.autoPercentNotice'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
            FilledButton(
              onPressed: () {
                final maxScore = double.tryParse(maxCtrl.text.trim()) ?? 20;
                final students = store.studentsInClass(selectedCg);
                for (final st in students) {
                  store.grades.add(
                    GradeEntry(
                      id: store.newId('gr'),
                      studentId: st.id,
                      schoolId: school.id,
                      subjectId: selectedSubj,
                      teacherId: user.id,
                      yearId: 'y2',
                      examType: selectedExam,
                      title: titleCtrl.text.trim(),
                      score: (maxScore * 0.85).roundToDouble(), // Sample initial score
                      maxScore: maxScore,
                    ),
                  );
                }
                store.commit();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم رصد الدرجات لـ ${students.length} طالباً بنجاح')),
                );
              },
              child: Text(context.tr('common.save')),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateExamDialog(BuildContext context, AppUser user, School school, dynamic store) {
    final maxCtrl = TextEditingController(text: '100');
    final classGroups = store.classGroupsOfTeacher(user.id, school.id);
    final subjects = store.subjectsOfTeacher(user.id, school.id);
    if (classGroups.isEmpty || subjects.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('جدولة امتحان ورقي داخل المدرسة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: maxCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الدرجة القصوى'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              store.exams.add(
                ExamSchedule(
                  id: store.newId('ex'),
                  schoolId: school.id,
                  classGroupId: classGroups.first.id,
                  subjectId: subjects.first.id,
                  teacherId: user.id,
                  yearId: 'y2',
                  type: ExamType.monthly,
                  date: DateTime.now().add(const Duration(days: 7)),
                  startTime: '08:30',
                  maxGrade: double.tryParse(maxCtrl.text.trim()) ?? 100,
                ),
              );
              store.commit();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تمت جدولة الامتحان الورقي وإشعار الطلبة')),
              );
            },
            child: Text(context.tr('common.save')),
          ),
        ],
      ),
    );
  }
}

/// Dedicated attendance recording widget fulfilling the exact per-class-session workflow.
class _AttendanceRecorderView extends StatefulWidget {
  const _AttendanceRecorderView({
    required this.teacher,
    required this.school,
    required this.classGroups,
    required this.subjects,
    required this.store,
    required this.isReadOnly,
  });

  final AppUser teacher;
  final School school;
  final List<ClassGroup> classGroups;
  final List<Subject> subjects;
  final dynamic store;
  final bool isReadOnly;

  @override
  State<_AttendanceRecorderView> createState() => _AttendanceRecorderViewState();
}

class _AttendanceRecorderViewState extends State<_AttendanceRecorderView> {
  ClassGroup? _selectedCg;
  Subject? _selectedSubj;
  String _sessionTime = '08:00 – 08:45';

  final Map<String, AttendanceStatus> _statusMap = {};

  @override
  void initState() {
    super.initState();
    if (widget.classGroups.isNotEmpty) _selectedCg = widget.classGroups.first;
    if (widget.subjects.isNotEmpty) _selectedSubj = widget.subjects.first;
    _initStudents();
  }

  void _initStudents() {
    if (_selectedCg == null) return;
    final students = widget.store.studentsInClass(_selectedCg!.id);
    _statusMap.clear();
    for (final st in students) {
      _statusMap[st.id] = AttendanceStatus.present;
    }
  }

  void _saveAttendance() {
    if (widget.isReadOnly) return;
    if (_selectedCg == null || _selectedSubj == null) return;

    final today = DateTime.now();
    _statusMap.forEach((studentId, status) {
      widget.store.attendance.add(
        AttendanceRecord(
          id: widget.store.newId('att'),
          studentId: studentId,
          schoolId: widget.school.id,
          classGroupId: _selectedCg!.id,
          subjectId: _selectedSubj!.id,
          teacherId: widget.teacher.id,
          date: today,
          sessionStart: _sessionTime.split('–').first.trim(),
          sessionEnd: _sessionTime.split('–').last.trim(),
          status: status,
        ),
      );

      // Notify parent if absent or late per spec:
      if (status == AttendanceStatus.absent || status == AttendanceStatus.late) {
        final parents = widget.store.parentsOf(studentId);
        final student = widget.store.userById(studentId);
        final statusText = status == AttendanceStatus.absent ? 'غائب' : 'متأخر';
        for (final p in parents) {
          widget.store.notify(
            p.id,
            'attendance',
            'إشعار حضور: ${student?.fullName ?? "ابنك"}',
            'تم تسجيل حالة ($statusText) في حصة ${_selectedSubj!.name.of(context.language)} اليوم $_sessionTime',
          );
        }
      }
    });

    widget.store.commit();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حفظ حضور ${_statusMap.length} طالباً وإشعار أولياء الأمور')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.classGroups.isEmpty) {
      return const EmptyState(title: 'لا توجد شعب مسندة لك في هذه المدرسة');
    }

    final students = _selectedCg == null ? <AppUser>[] : widget.store.studentsInClass(_selectedCg!.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل حضور الحصة الدراسية'),
      ),
      body: Column(
        children: [
          // Selectors header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardTheme.color,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ClassGroup>(
                        value: _selectedCg,
                        decoration: InputDecoration(labelText: context.tr('teacher.selectClass')),
                        items: widget.classGroups
                            .map((cg) => DropdownMenuItem(value: cg, child: Text(context.classGroupLabel(cg))))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedCg = v;
                          _initStudents();
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<Subject>(
                        value: _selectedSubj,
                        decoration: InputDecoration(labelText: context.tr('teacher.selectSubject')),
                        items: widget.subjects
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.name.of(context.language))))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedSubj = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'توقيت الحصة: $_sessionTime',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('${students.length} طالباً في القائمة', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Students list with photographs and attendance status toggles
          Expanded(
            child: students.isEmpty
                ? const EmptyState(title: 'لا يوجد طلبة مسجلين في هذه الشعبة')
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: students.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final st = students[i];
                      final currentStatus = _statusMap[st.id] ?? AttendanceStatus.present;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              AppAvatar(user: st, size: 44, showBadge: false),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  st.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              // Status selector buttons
                              _buildStatusSegment(st.id, AttendanceStatus.present, 'حاضر', AppColors.success, currentStatus),
                              const SizedBox(width: 4),
                              _buildStatusSegment(st.id, AttendanceStatus.late, 'متأخر', AppColors.late, currentStatus),
                              const SizedBox(width: 4),
                              _buildStatusSegment(st.id, AttendanceStatus.absent, 'غائب', AppColors.danger, currentStatus),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Save button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: FilledButton.icon(
              onPressed: widget.isReadOnly ? null : _saveAttendance,
              icon: const Icon(Icons.save_rounded),
              label: Text(context.tr('common.save')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSegment(String studentId, AttendanceStatus status, String label, Color color, AttendanceStatus current) {
    final isSelected = current == status;
    return InkWell(
      onTap: () => setState(() => _statusMap[studentId] = status),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

