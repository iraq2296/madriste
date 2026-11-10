import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/ui_helpers.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';

class ParentDashboard extends ConsumerStatefulWidget {
  const ParentDashboard({super.key});

  @override
  ConsumerState<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends ConsumerState<ParentDashboard> {
  int _currentNavIndex = 0;
  String? _selectedChildId;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final store = ref.watch(dataStoreProvider);
    final children = store.childrenOf(user.id);

    // Default to first child if not selected
    if (_selectedChildId == null && children.isNotEmpty) {
      _selectedChildId = children.first.id;
    }

    final activeChild = children.firstWhere(
      (c) => c.id == _selectedChildId,
      orElse: () => children.isNotEmpty ? children.first : user,
    );

    return Scaffold(
      body: SafeArea(
        child: children.isEmpty
            ? _buildNoChildrenView(context, user, store)
            : Column(
                children: [
                  // Child Switcher Carousel / Row
                  _buildChildSwitcherBar(context, children, activeChild, user, store),
                  Expanded(
                    child: IndexedStack(
                      index: _currentNavIndex,
                      children: [
                        _buildChildOverviewTab(context, activeChild, user, store),
                        _buildAcademicTab(context, activeChild, store),
                        _buildAttendanceTab(context, activeChild, store),
                        _buildCommunicationTab(context, activeChild, user, store),
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
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book_rounded),
            label: 'الدروس والدرجات',
          ),
          NavigationDestination(
            icon: const Icon(Icons.fact_check_outlined),
            selectedIcon: const Icon(Icons.fact_check_rounded),
            label: 'الحضور والغياب',
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups_rounded),
            label: 'التواصل والاجتماعات',
          ),
        ],
      ),
    );
  }

  Widget _buildChildSwitcherBar(
    BuildContext context,
    List<AppUser> children,
    AppUser activeChild,
    AppUser parent,
    dynamic store,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...children.map((child) {
                    final isSelected = child.id == activeChild.id;
                    final school = store.schoolsOf(child.id).firstOrNull;
                    return Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: ChoiceChip(
                        selected: isSelected,
                        avatar: AppAvatar(user: child, size: 28, showBadge: false),
                        label: Text(
                          '${child.firstName} (${school?.name.split(" ").first ?? ""})',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                          ),
                        ),
                        selectedColor: AppColors.primary,
                        onSelected: (_) => setState(() => _selectedChildId = child.id),
                      ),
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: Text(context.tr('parent.linkChild')),
                    onPressed: () => _showLinkChildBottomSheet(context, parent, store),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.tr('nav.settings'),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildChildOverviewTab(
    BuildContext context,
    AppUser child,
    AppUser parent,
    dynamic store,
  ) {
    final school = store.schoolsOf(child.id).firstOrNull;
    final classGroup = store.classOfStudent(child.id);

    final attList = store.attendance.where((a) => a.studentId == child.id).toList();
    final totalAtt = attList.length;
    final presentCount = attList.where((a) => a.status == AttendanceStatus.present).length;
    final lateCount = attList.where((a) => a.status == AttendanceStatus.late).length;
    final absentCount = attList.where((a) => a.status == AttendanceStatus.absent).length;
    final attPercent = totalAtt > 0 ? (presentCount / totalAtt) * 100 : 100.0;

    final notes = store.notes.where((n) => n.studentId == child.id).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Child Status Card
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
                AppAvatar(user: child, size: 62, showBadge: false),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        classGroup != null
                            ? '${context.classGroupLabel(classGroup, withStage: true)} • ${school?.name ?? ""}'
                            : school?.name ?? '',
                        style: const TextStyle(color: Color(0xFFD6EAFB), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Attendance Quick Indicators
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'نسبة الحضور',
                  value: '${attPercent.toStringAsFixed(0)}%',
                  subtitle: '$presentCount حاضر من $totalAtt',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  onTap: () => setState(() => _currentNavIndex = 2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  title: 'الغياب والتأخر',
                  value: '$absentCount غياب',
                  subtitle: '$lateCount تأخر',
                  icon: Icons.warning_amber_rounded,
                  color: absentCount > 0 ? AppColors.danger : AppColors.late,
                  onTap: () => setState(() => _currentNavIndex = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Quick Action: Request Leave & Book Meeting
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showLeaveRequestDialog(context, child, parent, school, store),
                  icon: const Icon(Icons.event_busy_rounded, size: 18),
                  label: Text(context.tr('parent.requestLeave')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showBookMeetingDialog(context, child, parent, school, store),
                  icon: const Icon(Icons.video_call_rounded, size: 18),
                  label: Text(context.tr('parent.bookMeeting')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Educational & Behavioral Notes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('parent.notes'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 8),
          if (notes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('لا توجد ملاحظات خاصة مسجلة حالياً', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...notes.map((n) {
              final author = store.userById(n.authorId);
              final isEdu = n.kind == NoteKind.educational;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isEdu ? Icons.school_rounded : Icons.psychology_rounded,
                            color: isEdu ? AppColors.primary : AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEdu ? 'ملاحظة تعليمية' : 'ملاحظة سلوكية',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isEdu ? AppColors.primary : AppColors.warning,
                            ),
                          ),
                          const Spacer(),
                          Text('من: ${author?.fullName ?? "المعلم"}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(n.text, style: const TextStyle(height: 1.4)),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ───────────── ACADEMIC TAB (LESSONS & GRADES) ─────────────
  Widget _buildAcademicTab(BuildContext context, AppUser child, dynamic store) {
    final classGroup = store.classOfStudent(child.id);
    final lessons = classGroup == null
        ? <Lesson>[]
        : store.lessons.where((l) => l.classGroupId == classGroup.id).toList();
    final grades = store.grades.where((g) => g.studentId == child.id).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('المستوى الدراسي لـ ${child.firstName}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الدرجات والنتائج'),
              Tab(text: 'الدروس والمقررات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Grades list
            grades.isEmpty
                ? const EmptyState(title: 'لا توجد درجات معلنة')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: grades.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final gr = grades[i];
                      final sub = store.subjectById(gr.subjectId);
                      final isPassing = gr.percentage >= 50;
                      return Card(
                        child: ListTile(
                          title: Text(gr.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${sub?.name.of(context.language) ?? ""} • ${context.tr(gr.examType.l10nKey)}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${gr.score.toStringAsFixed(0)} / ${gr.maxScore.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                '${gr.percentage.toStringAsFixed(0)}%',
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
                    },
                  ),
            // Lessons list
            lessons.isEmpty
                ? const EmptyState(title: 'لا توجد دروس منشورة')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: lessons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final l = lessons[i];
                      final sub = store.subjectById(l.subjectId);
                      return Card(
                        child: ListTile(
                          title: Text(l.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${sub?.name.of(context.language) ?? ""} • ${l.body}'),
                          trailing: Text(context.relativeTime(l.publishedAt), style: const TextStyle(fontSize: 11)),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // ───────────── ATTENDANCE TAB ─────────────
  Widget _buildAttendanceTab(BuildContext context, AppUser child, dynamic store) {
    final atts = store.attendance.where((a) => a.studentId == child.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('سجل حضور الحصص لـ ${child.firstName}'),
      ),
      body: atts.isEmpty
          ? const EmptyState(title: 'لا يوجد سجل حضور')
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
                      '${sub?.name.of(context.language) ?? ""} (${a.sessionStart} - ${a.sessionEnd})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(context.formatDate(a.date)),
                    trailing: Text(
                      context.tr(a.status.l10nKey),
                      style: TextStyle(
                        color: attendanceColor(a.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ───────────── COMMUNICATION & MEETINGS TAB ─────────────
  Widget _buildCommunicationTab(BuildContext context, AppUser child, AppUser parent, dynamic store) {
    final meetings = store.meetings.where((m) => m.parentId == parent.id).toList();
    final leaves = store.leaveRequests.where((l) => l.parentId == parent.id).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الاجتماعات والإجازات'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الاجتماعات المجدولة'),
              Tab(text: 'طلبات الإجازة'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Meetings
            meetings.isEmpty
                ? const EmptyState(title: 'لا توجد طلبات اجتماعات')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: meetings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final m = meetings[i];
                      final staff = store.userById(m.staffId);
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                            child: Icon(
                              m.type == MeetingType.video
                                  ? Icons.videocam_rounded
                                  : (m.type == MeetingType.audio ? Icons.call_rounded : Icons.place_rounded),
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(m.topic, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('مع: ${staff?.fullName ?? "المعلم"} • ${context.formatDateTime(m.scheduledAt)}'),
                          trailing: (m.type == MeetingType.video || m.type == MeetingType.audio)
                              ? IconButton(
                                  icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.success),
                                  tooltip: 'بدء الاتصال (مجاني وغير محدود)',
                                  onPressed: () => context.push('/meeting-call', extra: m),
                                )
                              : const Text('حضوري', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
            // Leaves
            leaves.isEmpty
                ? const EmptyState(title: 'لا توجد طلبات إجازة')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: leaves.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final l = leaves[i];
                      final isApproved = l.status == LeaveStatus.approved;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (isApproved ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                            child: Icon(
                              isApproved ? Icons.check_circle_rounded : Icons.pending_rounded,
                              color: isApproved ? AppColors.success : AppColors.warning,
                            ),
                          ),
                          title: Text(l.reason, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('بتاريخ: ${context.formatDate(l.date)}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isApproved ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isApproved ? 'مقبولة' : 'قيد المراجعة',
                              style: TextStyle(
                                color: isApproved ? AppColors.success : AppColors.warning,
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

  Widget _buildNoChildrenView(BuildContext context, AppUser parent, dynamic store) {
    return EmptyState(
      title: 'لم يتم ربط أي ابن بحسابك بعد',
      message: 'قم بربط حساب ابنك باستخدام البطاقة الوطنية الموحدة لتتمكن من متابعة درجاته وحضوره.',
      icon: Icons.family_restroom_rounded,
      actionLabel: context.tr('parent.linkChild'),
      onAction: () => _showLinkChildBottomSheet(context, parent, store),
    );
  }

  // ───────────── PARENT-CHILD LINKING MODAL ─────────────
  void _showLinkChildBottomSheet(BuildContext context, AppUser parent, dynamic store) {
    bool hasNationalId = false;
    AppUser? selectedStudent = store.users.where((u) => u.role == UserRole.student).firstOrNull;
    UserRole selectedApproverRole = UserRole.manager;
    AppUser? selectedApprover = store.users.where((u) => u.role == UserRole.manager).firstOrNull;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('parent.linkChild'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'خطوات الربط: 1. إرفاق البطاقة الوطنية • 2. اختيار الطالب • 3. تحديد المسؤول عن الموافقة',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),

                // Step 1: Upload National ID
                ListTile(
                  tileColor: hasNationalId ? AppColors.success.withValues(alpha: 0.1) : AppColors.lightBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  leading: Icon(
                    hasNationalId ? Icons.check_circle_rounded : Icons.badge_outlined,
                    color: hasNationalId ? AppColors.success : AppColors.primary,
                  ),
                  title: const Text('صورة البطاقة الوطنية الموحدة'),
                  subtitle: const Text('تُستخدم لمقارنة البيانات ولا تُعد إثباتاً حكومياً'),
                  trailing: TextButton(
                    onPressed: () => setModalState(() => hasNationalId = !hasNationalId),
                    child: Text(hasNationalId ? 'تم' : 'إرفاق'),
                  ),
                ),
                const SizedBox(height: 16),

                // Step 2: Select Student
                DropdownButtonFormField<AppUser>(
                  value: selectedStudent,
                  decoration: const InputDecoration(labelText: 'اختر الطالب من سجلات المدرسة'),
                  items: store.users
                      .where((u) => u.role == UserRole.student)
                      .map<DropdownMenuItem<AppUser>>((u) => DropdownMenuItem(value: u, child: Text(u.fullName)))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedStudent = v),
                ),
                const SizedBox(height: 16),

                // Step 3: Choose responsible person
                DropdownButtonFormField<UserRole>(
                  value: selectedApproverRole,
                  decoration: InputDecoration(labelText: context.tr('parent.selectApprover')),
                  items: const [
                    DropdownMenuItem(value: UserRole.manager, child: Text('مدير المدرسة')),
                    DropdownMenuItem(value: UserRole.teacher, child: Text('المدرّس المسؤول')),
                    DropdownMenuItem(value: UserRole.instructor, child: Text('المعلّم المسؤول')),
                  ],
                  onChanged: (v) => setModalState(() {
                    selectedApproverRole = v ?? UserRole.manager;
                    selectedApprover = store.users.where((u) => u.role == selectedApproverRole).firstOrNull;
                  }),
                ),
                const SizedBox(height: 16),

                // Step 4: Specific person
                DropdownButtonFormField<AppUser>(
                  value: selectedApprover,
                  decoration: const InputDecoration(labelText: 'تحديد الشخص بالاسم'),
                  items: store.users
                      .where((u) => u.role == selectedApproverRole)
                      .map<DropdownMenuItem<AppUser>>((u) => DropdownMenuItem(value: u, child: Text(u.fullName)))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedApprover = v),
                ),
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: () {
                    if (!hasNationalId || selectedStudent == null || selectedApprover == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى إكمال جميع الحقول وإرفاق البطاقة الوطنية')),
                      );
                      return;
                    }
                    store.linkRequests.add(
                      ParentLinkRequest(
                        id: store.newId('lr'),
                        parentId: parent.id,
                        studentId: selectedStudent!.id,
                        schoolId: 'sch1',
                        approverId: selectedApprover!.id,
                        approverRole: selectedApproverRole,
                        idDocumentName: 'national_id.jpg',
                        ocrExtractedName: parent.fullName,
                        ocrMatch: true,
                        status: LinkStatus.approved, // Sample auto-approved for quick trial
                      ),
                    );
                    store.commit();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال طلب الربط للمسؤول المحدد بنجاح')),
                    );
                  },
                  child: const Text('إرسال طلب الربط'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────── LEAVE REQUEST DIALOG ─────────────
  void _showLeaveRequestDialog(BuildContext context, AppUser child, AppUser parent, School? school, dynamic store) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('parent.requestLeave')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('parent.leaveNotice'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(labelText: context.tr('parent.leaveReason')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              store.leaveRequests.add(
                LeaveRequest(
                  id: store.newId('lv'),
                  parentId: parent.id,
                  studentId: child.id,
                  schoolId: school?.id ?? 'sch1',
                  date: DateTime.now().add(const Duration(days: 1)),
                  reason: reasonCtrl.text.trim(),
                  recipientIds: ['mgr1', 't1', 'i1'],
                  status: LeaveStatus.approved, // Immediately approved per rule
                  approvedBy: 'mgr1',
                ),
              );
              store.commit();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إرسال طلب الإجازة واعتماده فوراً')),
              );
            },
            child: Text(context.tr('common.send')),
          ),
        ],
      ),
    );
  }

  // ───────────── BOOK MEETING DIALOG ─────────────
  void _showBookMeetingDialog(BuildContext context, AppUser child, AppUser parent, School? school, dynamic store) {
    final topicCtrl = TextEditingController(text: 'مناقشة المستوى الدراسي');
    MeetingType selectedType = MeetingType.video;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr('parent.bookMeeting')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: topicCtrl,
                decoration: const InputDecoration(labelText: 'موضوع الاجتماع'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MeetingType>(
                value: selectedType,
                decoration: InputDecoration(labelText: context.tr('parent.meetingType')),
                items: [
                  DropdownMenuItem(value: MeetingType.inPerson, child: Text(context.tr('parent.inPerson'))),
                  DropdownMenuItem(value: MeetingType.audio, child: Text(context.tr('parent.audioCall'))),
                  DropdownMenuItem(value: MeetingType.video, child: Text(context.tr('parent.videoCall'))),
                ],
                onChanged: (v) => setDialogState(() => selectedType = v ?? selectedType),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('parent.freeCallsNotice'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.success),
              ),
            ],
          ),
          actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              store.meetings.add(
                Meeting(
                  id: store.newId('mt'),
                  parentId: parent.id,
                  staffId: 't1',
                  studentId: child.id,
                  schoolId: school?.id ?? 'sch1',
                  type: selectedType,
                  scheduledAt: DateTime.now().add(const Duration(days: 2)),
                  topic: topicCtrl.text.trim(),
                  status: MeetingStatus.accepted,
                ),
              );
              store.commit();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حجز موعد الاجتماع بنجاح')),
              );
            },
            child: Text(context.tr('common.confirm')),
          ),
        ],
      ),
    ),
  );
}
}
