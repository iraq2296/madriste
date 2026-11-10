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
import '../../core/widgets/verified_badge.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';

class ManagerDashboard extends ConsumerStatefulWidget {
  const ManagerDashboard({super.key});

  @override
  ConsumerState<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends ConsumerState<ManagerDashboard> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final rawUser = ref.watch(currentUserProvider);
    final store = ref.watch(dataStoreProvider);
    final isReadOnly = ref.watch(readOnlyProvider);

    final user = (rawUser.role == UserRole.manager) ? rawUser : (store.userById('mgr1') ?? rawUser);

    // The school this manager manages
    final school = store.schools.firstWhere(
      (s) => s.managerId == user.id,
      orElse: () => store.schools.first,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ReadOnlyBanner(),
            Expanded(
              child: IndexedStack(
                index: _currentNavIndex,
                children: [
                  _buildOverviewTab(context, user, school, store, isReadOnly),
                  _buildTeachersTab(context, school, store, isReadOnly),
                  _buildStudentsTab(context, school, store, isReadOnly),
                  _buildAcademicYearsTab(context, school, store, isReadOnly),
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
            label: 'نظرة عامة',
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school_rounded),
            label: context.tr('manager.teachersTab'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline_rounded),
            selectedIcon: const Icon(Icons.people_rounded),
            label: context.tr('manager.studentsTab'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_edu_outlined),
            selectedIcon: const Icon(Icons.history_edu_rounded),
            label: 'العام الدراسي',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    AppUser user,
    School school,
    dynamic store,
    bool isReadOnly,
  ) {
    final teachers = store.membersOfSchool(school.id, {UserRole.teacher, UserRole.instructor});
    final students = store.membersOfSchool(school.id, {UserRole.student});
    final pendingRequests = store.memberships.where(
      (m) => m.schoolId == school.id && m.status == MembershipStatus.pending,
    ).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Manager School Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                AppAvatar(user: user, size: 58, showBadge: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              school.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (school.verified) ...[
                            const SizedBox(width: 6),
                            const VerifiedBadge(size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'المدير: ${user.fullName} • ${school.governorate}',
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
          ),
          const SizedBox(height: 18),

          // Pending Requests Alert
          if (pendingRequests > 0)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions_rounded, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'يوجد $pendingRequests طلب انضمام بانتظار موافقتك',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => setState(() => _currentNavIndex = 1),
                    child: const Text('مراجعة'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),

          // School Statistics Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'المدرسين والمعلمين',
                  value: '${teachers.length}',
                  subtitle: 'كادر تدريسي',
                  icon: Icons.school_rounded,
                  color: AppColors.primary,
                  onTap: () => setState(() => _currentNavIndex = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'إجمالي الطلبة',
                  value: '${students.length}',
                  subtitle: 'طالباً مسجلاً',
                  icon: Icons.people_alt_rounded,
                  color: AppColors.success,
                  onTap: () => setState(() => _currentNavIndex = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'الشعب الدراسية',
                  value: '${store.classGroups.where((c) => c.schoolId == school.id).length}',
                  subtitle: 'صفوف وشعب',
                  icon: Icons.view_comfy_alt_rounded,
                  color: const Color(0xFF0FA5B5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'الامتحانات المجدولة',
                  value: '${store.exams.where((e) => e.schoolId == school.id).length}',
                  subtitle: 'امتحانات ورقية',
                  icon: Icons.event_note_rounded,
                  color: const Color(0xFF8E5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isReadOnly
                      ? () => _showReadOnlyNotice(context)
                      : () => _showPublishAnnouncementDialog(context, user, school, store),
                  icon: const Icon(Icons.campaign_rounded, size: 18),
                  label: const Text('نشر إعلان مدرسي'),
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

          // Announcements
          Text(
            context.tr('manager.announcements'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...store.announcements.where((a) => a.schoolId == school.id).map((an) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.campaign_rounded, color: AppColors.primary),
                title: Text(an.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(an.body),
                trailing: Text(context.relativeTime(an.createdAt), style: const TextStyle(fontSize: 11)),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ───────────── TEACHERS & JOINING REQUESTS ─────────────
  Widget _buildTeachersTab(BuildContext context, School school, dynamic store, bool isReadOnly) {
    final activeTeachers = store.membersOfSchool(school.id, {UserRole.teacher, UserRole.instructor});
    final pendingTeacherReqs = store.memberships.where(
      (m) => m.schoolId == school.id && m.role.isTeaching && m.status == MembershipStatus.pending,
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('manager.teachersTab')),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: context.tr('manager.inviteTeacher'),
            onPressed: isReadOnly
                ? () => _showReadOnlyNotice(context)
                : () => _showInviteTeacherDialog(context, school, store),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pendingTeacherReqs.isNotEmpty) ...[
            Text(
              'طلبات انضمام المدرسين (${pendingTeacherReqs.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warning),
            ),
            const SizedBox(height: 8),
            ...pendingTeacherReqs.map((req) {
              final teacher = store.userById(req.userId);
              return Card(
                color: AppColors.warning.withValues(alpha: 0.08),
                child: ListTile(
                  leading: AppAvatar(user: teacher!, size: 44, showBadge: false),
                  title: Text(teacher.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('التخصص: ${teacher.specialization ?? "مدرس"}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                        onPressed: isReadOnly ? null : () => _respondToMembership(req, true, store),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_rounded, color: AppColors.danger),
                        onPressed: isReadOnly ? null : () => _respondToMembership(req, false, store),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
          Text(
            'الكادر التدريسي المعتمد (${activeTeachers.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (activeTeachers.isEmpty)
            const EmptyState(title: 'لا يوجد مدرسين مسجلين في المدرسة بعد')
          else
            ...activeTeachers.map((t) {
              final groups = store.classGroupsOfTeacher(t.id, school.id);
              final subs = store.subjectsOfTeacher(t.id, school.id);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: AppAvatar(user: t, size: 44, showBadge: true),
                  title: Text(t.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${subs.map((s) => s.name.of(context.language)).join(", ")} • ${groups.length} شعب',
                  ),
                  trailing: Text(t.phone, textDirection: TextDirection.ltr),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ───────────── STUDENTS & JOINING REQUESTS ─────────────
  Widget _buildStudentsTab(BuildContext context, School school, dynamic store, bool isReadOnly) {
    final activeStudents = store.membersOfSchool(school.id, {UserRole.student});
    final pendingStudentReqs = store.memberships.where(
      (m) => m.schoolId == school.id && m.role == UserRole.student && m.status == MembershipStatus.pending,
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('manager.studentsTab')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pendingStudentReqs.isNotEmpty) ...[
            Text(
              'طلبات انضمام الطلبة (${pendingStudentReqs.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warning),
            ),
            const SizedBox(height: 8),
            ...pendingStudentReqs.map((req) {
              final student = store.userById(req.userId);
              return Card(
                color: AppColors.warning.withValues(alpha: 0.08),
                child: ListTile(
                  leading: AppAvatar(user: student!, size: 44, showBadge: false),
                  title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(student.phone, textDirection: TextDirection.ltr),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                        onPressed: isReadOnly ? null : () => _respondToMembership(req, true, store),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_rounded, color: AppColors.danger),
                        onPressed: isReadOnly ? null : () => _respondToMembership(req, false, store),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
          Text(
            'قائمة الطلبة المسجلين (${activeStudents.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (activeStudents.isEmpty)
            const EmptyState(title: 'لا يوجد طلبة مسجلين بعد')
          else
            ...activeStudents.map((st) {
              final cg = store.classOfStudent(st.id);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: AppAvatar(user: st, size: 44, showBadge: false),
                  title: Text(st.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(cg != null ? context.classGroupLabel(cg, withStage: true) : 'غير مسند لشعبة'),
                  trailing: Text(st.phone, textDirection: TextDirection.ltr),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ───────────── ACADEMIC YEARS MANAGEMENT ─────────────
  Widget _buildAcademicYearsTab(BuildContext context, School school, dynamic store, bool isReadOnly) {
    final years = store.yearsOf(school.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('manager.academicYears')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: context.tr('manager.newAcademicYear'),
            onPressed: isReadOnly
                ? () => _showReadOnlyNotice(context)
                : () => _showNewYearDialog(context, school, store),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: years.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final y = years[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        y.isCurrent ? Icons.star_rounded : Icons.history_rounded,
                        color: y.isCurrent ? AppColors.success : AppColors.textSecondary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              y.label,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                            ),
                            Text(
                              'من ${context.formatShortDate(y.startsOn)} إلى ${context.formatShortDate(y.endsOn)}',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (y.isCurrent ? AppColors.success : Colors.grey).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          y.isCurrent ? 'العام الحالي' : 'مؤرشف',
                          style: TextStyle(
                            color: y.isCurrent ? AppColors.success : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (y.isCurrent && !isReadOnly) ...[
                    const SizedBox(height: 14),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _archiveYearAndAdvance(context, y, school, store),
                          icon: const Icon(Icons.archive_outlined, size: 18),
                          label: Text(context.tr('manager.archiveYear')),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _respondToMembership(Membership req, bool approve, dynamic store) {
    req.status = approve ? MembershipStatus.approved : MembershipStatus.rejected;
    store.commit();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(approve ? 'تم قبول طلب الانضمام بنجاح' : 'تم رفض طلب الانضمام')),
    );
  }

  void _showPublishAnnouncementDialog(BuildContext context, AppUser user, School school, dynamic store) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('manager.createAnnouncement')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان الإعلان')),
            const SizedBox(height: 12),
            TextField(controller: bodyCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'نص الإعلان')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              store.announcements.insert(
                0,
                Announcement(
                  id: store.newId('an'),
                  schoolId: school.id,
                  authorId: user.id,
                  title: titleCtrl.text.trim(),
                  body: bodyCtrl.text.trim(),
                ),
              );
              store.commit();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نشر الإعلان المدرسي وإشعار الجميع')),
              );
            },
            child: Text(context.tr('common.publish')),
          ),
        ],
      ),
    );
  }

  void _showInviteTeacherDialog(BuildContext context, School school, dynamic store) {
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('manager.inviteTeacher')),
        content: TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'رقم هاتف المدرّس (7701234567)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إرسال دعوة الانضمام للمدرّس بنجاح')),
              );
            },
            child: Text(context.tr('common.send')),
          ),
        ],
      ),
    );
  }

  void _showNewYearDialog(BuildContext context, School school, dynamic store) {
    final labelCtrl = TextEditingController(text: '2027–2028');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('manager.newAcademicYear')),
        content: TextField(
          controller: labelCtrl,
          decoration: const InputDecoration(labelText: 'تسمية العام الدراسي (مثال: 2027–2028)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              store.academicYears.add(
                AcademicYear(
                  id: store.newId('y'),
                  schoolId: school.id,
                  label: labelCtrl.text.trim(),
                  startsOn: DateTime(2027, 9, 20),
                  endsOn: DateTime(2028, 6, 30),
                  isCurrent: false,
                ),
              );
              store.commit();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تمت إضافة العام الدراسي الجديد')),
              );
            },
            child: Text(context.tr('common.save')),
          ),
        ],
      ),
    );
  }

  void _archiveYearAndAdvance(BuildContext context, AcademicYear year, School school, dynamic store) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('أرشفة العام وترفيع الطلبة'),
        content: const Text(
          'سيتم تجميد درجات وحضور هذا العام وحفظها في الأرشيف ونقل الطلبة الناجحين للصف الأعلى. هل أنت متأكد؟',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              year.archived = true;
              year.isCurrent = false;
              store.commit();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم أرشفة العام وترفيع الطلبة مع حفظ السجلات التاريخية')),
              );
            },
            child: Text(context.tr('common.confirm')),
          ),
        ],
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
}

