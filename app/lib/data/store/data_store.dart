import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../models/platform_models.dart';

/// Single source of truth for application data on the client.
///
/// * In **production** the collections are hydrated from Supabase (PostgreSQL
///   + Row-Level Security) through the feature repositories and kept fresh via
///   Realtime subscriptions; mutations call RPCs / Edge Functions and the
///   server is authoritative for authorization.
/// * In **preview mode** (no backend credentials) it is seeded with sample
///   Iraqi school data by `seedPreviewData` so every screen is reviewable.
///
/// Feature-specific queries and mutations live in feature repositories,
/// implemented as extensions on [DataStore] (see `lib/features/*/data/`).
/// After a mutation, call [commit] to notify listeners.
class DataStore extends ChangeNotifier {
  // Identity & organisation
  final users = <AppUser>[];
  final schools = <School>[];
  final academicYears = <AcademicYear>[];
  final classGroups = <ClassGroup>[];
  final subjects = <Subject>[];
  final memberships = <Membership>[];
  final follows = <TeacherFollow>[];

  // Teaching
  final lessons = <Lesson>[];
  final exams = <ExamSchedule>[];
  final grades = <GradeEntry>[];
  final attendance = <AttendanceRecord>[];
  final schedule = <ScheduleEntry>[];
  final scheduleHistory = <ScheduleChange>[];
  final notes = <StudentNote>[];
  final announcements = <Announcement>[];

  // Communication
  final conversations = <Conversation>[];
  final messages = <ChatMessage>[];
  final notifications = <AppNotification>[];

  // Parents
  final linkRequests = <ParentLinkRequest>[];
  final leaveRequests = <LeaveRequest>[];
  final meetings = <Meeting>[];

  // Library
  final library = <LibraryResource>[];
  final ministerialExams = <MinisterialExam>[];

  /// userId → favourite resource / ministerial exam ids.
  final favorites = <String, Set<String>>{};

  // Billing
  final plans = <SubscriptionPlan>[];
  final subscriptions = <Subscription>[];
  final discounts = <Discount>[];
  final extensions = <ManualExtension>[];
  final payments = <Payment>[];

  // Verification & security
  final verifications = <VerificationRecord>[];
  final devices = <DeviceSession>[];
  final securityEvents = <SecurityEvent>[];
  final deletionRequests = <DeletionRequest>[];
  final recoveryRequests = <RecoveryRequest>[];

  // Support & feedback
  final tickets = <SupportTicket>[];
  final suggestions = <Suggestion>[];
  final surveys = <Survey>[];

  /// Salted hashes of users who voted per survey (never linked to options).
  final surveyVoters = <String, Set<String>>{};

  // Platform
  final auditLogs = <AuditLog>[];
  final supportSessions = <SupportAccessSession>[];
  final backups = <BackupRecord>[];
  final policies = <PolicyDocument>[];
  AppVersionPolicy versionPolicy = AppVersionPolicy(latestVersion: '1.0.0', minSupportedVersion: '1.0.0', notes: '');
  MaintenanceState maintenance = MaintenanceState();
  ServerHealth? health;

  /// Maximum simultaneous devices per account.
  static const maxDevices = 2;

  int _seq = 1000;

  /// Generates a unique client-side id (server uses UUID v4).
  String newId(String prefix) => '$prefix-${_seq++}';

  /// Notify listeners after one or more mutations.
  void commit() => notifyListeners();

  // ───────────── Basic lookups shared by all features ─────────────

  AppUser? userById(String? id) => id == null ? null : _firstOrNull(users, (u) => u.id == id);
  School? schoolById(String? id) => id == null ? null : _firstOrNull(schools, (s) => s.id == id);
  ClassGroup? classGroupById(String? id) => id == null ? null : _firstOrNull(classGroups, (c) => c.id == id);
  Subject? subjectById(String? id) => id == null ? null : _firstOrNull(subjects, (s) => s.id == id);
  AppUser? userByPhone(String phone) => _firstOrNull(users, (u) => u.phone == phone);

  AcademicYear? currentYear(String schoolId) =>
      _firstOrNull(academicYears, (y) => y.schoolId == schoolId && y.isCurrent);

  List<AcademicYear> yearsOf(String schoolId) =>
      academicYears.where((y) => y.schoolId == schoolId).toList()..sort((a, b) => b.startsOn.compareTo(a.startsOn));

  /// Approved memberships of a user.
  List<Membership> activeMembershipsOf(String userId) => memberships
      .where((m) => m.userId == userId && m.status == MembershipStatus.approved)
      .toList();

  /// Schools a user belongs to (approved).
  List<School> schoolsOf(String userId) => activeMembershipsOf(userId)
      .map((m) => schoolById(m.schoolId))
      .whereType<School>()
      .toList();

  /// The single approved enrolment of a student (students belong to one school).
  Membership? enrolmentOf(String studentId) => _firstOrNull(
        memberships,
        (m) => m.userId == studentId && m.role == UserRole.student && m.status == MembershipStatus.approved,
      );

  ClassGroup? classOfStudent(String studentId) {
    final e = enrolmentOf(studentId);
    return e == null || e.classGroupIds.isEmpty ? null : classGroupById(e.classGroupIds.first);
  }

  List<AppUser> studentsInClass(String classGroupId) => memberships
      .where((m) =>
          m.role == UserRole.student &&
          m.status == MembershipStatus.approved &&
          m.classGroupIds.contains(classGroupId))
      .map((m) => userById(m.userId))
      .whereType<AppUser>()
      .toList()
    ..sort((a, b) => a.fullName.compareTo(b.fullName));

  List<AppUser> membersOfSchool(String schoolId, Set<UserRole> roles,
          {MembershipStatus status = MembershipStatus.approved}) =>
      memberships
          .where((m) => m.schoolId == schoolId && roles.contains(m.role) && m.status == status)
          .map((m) => userById(m.userId))
          .whereType<AppUser>()
          .toList();

  Membership? membershipOf(String userId, String schoolId) => _firstOrNull(
        memberships,
        (m) => m.userId == userId && m.schoolId == schoolId && m.status == MembershipStatus.approved,
      );

  /// Class groups a teacher/instructor teaches in a given school.
  List<ClassGroup> classGroupsOfTeacher(String teacherId, String schoolId) {
    final m = membershipOf(teacherId, schoolId);
    if (m == null) return [];
    return m.classGroupIds.map(classGroupById).whereType<ClassGroup>().toList();
  }

  /// Subjects a teacher teaches in a given school.
  List<Subject> subjectsOfTeacher(String teacherId, String schoolId) {
    final m = membershipOf(teacherId, schoolId);
    if (m == null) return [];
    return m.subjectIds.map(subjectById).whereType<Subject>().toList();
  }

  /// Teachers & instructors teaching a student's class.
  List<AppUser> teachersOfStudent(String studentId) {
    final cg = classOfStudent(studentId);
    if (cg == null) return [];
    return memberships
        .where((m) =>
            m.schoolId == cg.schoolId &&
            m.role.isTeaching &&
            m.status == MembershipStatus.approved &&
            m.classGroupIds.contains(cg.id))
        .map((m) => userById(m.userId))
        .whereType<AppUser>()
        .toList();
  }

  /// Children whose link request has been approved for this parent.
  List<AppUser> childrenOf(String parentId) => linkRequests
      .where((r) => r.parentId == parentId && r.status == LinkStatus.approved)
      .map((r) => userById(r.studentId))
      .whereType<AppUser>()
      .toList();

  /// Approved parents of a student (used for absence/late notifications).
  List<AppUser> parentsOf(String studentId) => linkRequests
      .where((r) => r.studentId == studentId && r.status == LinkStatus.approved)
      .map((r) => userById(r.parentId))
      .whereType<AppUser>()
      .toList();

  Subscription? subscriptionOf(String userId) {
    final list = subscriptions.where((s) => s.userId == userId).toList()
      ..sort((a, b) => b.endsAt.compareTo(a.endsAt));
    return list.isEmpty ? null : list.first;
  }

  /// Read-only mode: paid role whose subscription is not usable.
  bool isReadOnly(AppUser user) {
    if (!user.role.isPaid) return false;
    final sub = subscriptionOf(user.id);
    return sub == null || !sub.isUsable;
  }

  /// Creates an in-app notification (push delivery is handled server-side by
  /// the `send-push` Edge Function through FCM/APNs, respecting preferences).
  void notify(String userId, String category, String title, String body, {String? route}) {
    notifications.insert(
      0,
      AppNotification(
        id: newId('ntf'),
        userId: userId,
        category: category,
        title: title,
        body: body,
        route: route,
      ),
    );
  }

  void audit(String actorId, String action, String target, {String? reason}) {
    auditLogs.insert(0, AuditLog(id: newId('aud'), actorId: actorId, action: action, target: target, reason: reason));
  }

  void securityEvent(String userId, SecurityEventType type, String description, {String? device}) {
    securityEvents.insert(
      0,
      SecurityEvent(id: newId('sec'), userId: userId, type: type, description: description, device: device),
    );
  }

  static T? _firstOrNull<T>(Iterable<T> items, bool Function(T) test) {
    for (final i in items) {
      if (test(i)) return i;
    }
    return null;
  }
}

