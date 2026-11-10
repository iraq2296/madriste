// Domain models for MADRASI.
//
// These mirror the PostgreSQL schema in `supabase/migrations`. Field names map
// 1:1 to snake_case columns (e.g. `schoolId` ↔ `school_id`).
//
// A few workflow fields (`status`, `read`, …) are mutable so state transitions
// can be applied by the repository layer and broadcast to listeners.

import '../../core/l10n/l10n.dart';

/// Text stored in the three supported languages.
class LocalizedText {
  const LocalizedText(this.ar, this.en, this.ku);
  final String ar;
  final String en;
  final String ku;

  String of(AppLanguage lang) => switch (lang) {
        AppLanguage.ar => ar,
        AppLanguage.en => en,
        AppLanguage.ku => ku,
      };
}

// ───────────────────────────── Users & roles ─────────────────────────────

enum UserRole {
  manager,
  teacher,
  instructor,
  student,
  parent,
  superAdmin;

  String get l10nKey => 'role.$name';

  /// Roles that pay a monthly subscription after the free trial.
  bool get isPaid => this == manager || this == teacher || this == instructor;

  /// Roles eligible for the blue verification badge.
  bool get canHaveBadge => this == manager || this == teacher || this == instructor;

  /// Roles that must complete camera-based identity verification.
  bool get requiresFaceVerification =>
      this == manager || this == teacher || this == instructor || this == student;

  bool get isTeaching => this == teacher || this == instructor;
  bool get isStaff => this == manager || isTeaching;
}

enum VerificationStatus { notStarted, pending, manualReview, verified, rejected, locked }

enum AccountStatus { active, disabled, blocked }

class AppUser {
  AppUser({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    this.photoUrl,
    this.verification = VerificationStatus.verified,
    this.badgeVerified = false,
    this.status = AccountStatus.active,
    this.governorate,
    this.specialization,
    this.subjectIds = const [],
    this.teacherCode,
    DateTime? createdAt,
    this.statusReason,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String fullName;
  String phone; // E.164, e.g. +9647701234567
  final UserRole role;
  String? photoUrl;
  VerificationStatus verification;

  /// Blue badge (only schools, managers, teachers, instructors).
  bool badgeVerified;
  AccountStatus status;
  String? statusReason;
  String? governorate;
  String? specialization;
  List<String> subjectIds;

  /// Short code students use to follow a teacher (teachers/instructors only).
  final String? teacherCode;
  final DateTime createdAt;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.length == 1 ? parts.first.characters1 : '${parts[0].characters1}${parts[1].characters1}';
  }

  String get firstName => fullName.split(' ').first;
}

extension on String {
  String get characters1 => isEmpty ? '' : substring(0, 1);
}

// ───────────────────────────── Schools ─────────────────────────────

enum SchoolStage {
  primary(6, 1),
  intermediate(3, 1),
  preparatory(6, 4);

  const SchoolStage(this.lastGrade, this.firstGrade);
  final int firstGrade;
  final int lastGrade;

  List<int> get grades => [for (var g = firstGrade; g <= lastGrade; g++) g];
  String get l10nKey => 'stage.$name';
}

enum Track {
  none,
  scientific,
  literary;

  String get l10nKey => 'track.$name';
}

enum SchoolStatus { active, suspended }

class School {
  School({
    required this.id,
    required this.name,
    required this.governorate,
    required this.district,
    required this.stages,
    required this.managerId,
    this.verified = false,
    this.status = SchoolStatus.active,
    this.suspensionReason,
    this.lat,
    this.lng,
    this.phone,
    this.passingPercent = 50,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  final String governorate;
  String district;
  Set<SchoolStage> stages;
  String managerId;
  bool verified;
  SchoolStatus status;
  String? suspensionReason;

  /// Approximate coordinates (district centroid) – exact address is private.
  final double? lat;
  final double? lng;
  String? phone;

  /// Configurable passing threshold according to the school's grading policy.
  double passingPercent;
  final DateTime createdAt;
}

class AcademicYear {
  AcademicYear({
    required this.id,
    required this.schoolId,
    required this.label,
    required this.startsOn,
    required this.endsOn,
    this.isCurrent = false,
    this.archived = false,
  });

  final String id;
  final String schoolId;
  final String label; // e.g. 2025–2026
  final DateTime startsOn;
  final DateTime endsOn;
  bool isCurrent;
  bool archived;
}

/// A grade + section inside a school stage (e.g. Preparatory 5 Scientific – A).
class ClassGroup {
  ClassGroup({
    required this.id,
    required this.schoolId,
    required this.stage,
    required this.grade,
    required this.section,
    this.track = Track.none,
  });

  final String id;
  final String schoolId;
  final SchoolStage stage;
  final int grade;
  final Track track;

  /// Latin letter (A, B, C…); displayed as أ، ب، ج in Arabic/Kurdish.
  final String section;
}

class Subject {
  const Subject({required this.id, required this.name, required this.iconKey, required this.colorIndex});
  final String id;
  final LocalizedText name;

  /// Resolved to an icon by `subjectIcon()` in `core/widgets/ui_helpers.dart`.
  final String iconKey;
  final int colorIndex;
}

enum MembershipStatus { pending, invited, approved, rejected, left }

/// Links a user (teacher/instructor/student/manager) to a school.
/// Teachers may hold several memberships (one per school); students one.
class Membership {
  Membership({
    required this.id,
    required this.userId,
    required this.schoolId,
    required this.role,
    required this.status,
    this.classGroupIds = const [],
    this.subjectIds = const [],
    this.viaInvite = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String userId;
  final String schoolId;
  final UserRole role;
  MembershipStatus status;
  List<String> classGroupIds;
  List<String> subjectIds;
  final bool viaInvite;
  final DateTime createdAt;
}

/// Student following a teacher (joined with a teacher code or phone invite).
class TeacherFollow {
  TeacherFollow({required this.studentId, required this.teacherId, required this.schoolId, this.approved = true});
  final String studentId;
  final String teacherId;
  final String schoolId;
  bool approved;
}

// ───────────────────────────── Teaching content ─────────────────────────────

enum LessonType { text, pdf, image, board, video, booklet, announcement }

class Lesson {
  Lesson({
    required this.id,
    required this.schoolId,
    required this.classGroupId,
    required this.subjectId,
    required this.teacherId,
    required this.yearId,
    required this.title,
    required this.body,
    required this.type,
    this.attachmentName,
    this.attachmentUrl,
    DateTime? publishedAt,
  }) : publishedAt = publishedAt ?? DateTime.now();

  final String id;
  final String schoolId;
  final String classGroupId;
  final String subjectId;
  final String teacherId;
  final String yearId;
  String title;
  String body;
  final LessonType type;
  final String? attachmentName;
  final String? attachmentUrl;
  final DateTime publishedAt;
}

enum ExamType {
  daily,
  monthly,
  midyear,
  finalYear;

  String get l10nKey => switch (this) {
        daily => 'exam.daily',
        monthly => 'exam.monthly',
        midyear => 'exam.midyear',
        finalYear => 'exam.final',
      };
}

class ExamSchedule {
  ExamSchedule({
    required this.id,
    required this.schoolId,
    required this.classGroupId,
    required this.subjectId,
    required this.teacherId,
    required this.yearId,
    required this.type,
    required this.date,
    required this.startTime,
    required this.maxGrade,
    this.notes,
    this.resultsPublished = false,
  });

  final String id;
  final String schoolId;
  final String classGroupId;
  final String subjectId;
  final String teacherId;
  final String yearId;
  final ExamType type;
  DateTime date;
  String startTime; // HH:mm
  double maxGrade;
  String? notes;
  bool resultsPublished;
}

class GradeEntry {
  GradeEntry({
    required this.id,
    required this.studentId,
    required this.schoolId,
    required this.subjectId,
    required this.teacherId,
    required this.yearId,
    required this.examType,
    required this.title,
    required this.score,
    required this.maxScore,
    this.examId,
    DateTime? publishedAt,
  }) : publishedAt = publishedAt ?? DateTime.now();

  final String id;
  final String studentId;
  final String schoolId;
  final String subjectId;
  final String teacherId;
  final String yearId;
  final ExamType examType;
  final String? examId;
  final String title;
  double score;
  final double maxScore;
  final DateTime publishedAt;

  /// Automatic percentage, e.g. 17 / 20 → 85.0
  double get percentage => maxScore <= 0 ? 0 : (score / maxScore) * 100;
}

enum AttendanceStatus {
  present,
  absent,
  late,
  excused;

  String get l10nKey => 'attendance.$name';
}

/// Attendance is recorded per class session (not once per day).
class AttendanceRecord {
  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.schoolId,
    required this.classGroupId,
    required this.subjectId,
    required this.teacherId,
    required this.date,
    required this.sessionStart,
    required this.sessionEnd,
    required this.status,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  final String id;
  final String studentId;
  final String schoolId;
  final String classGroupId;
  final String subjectId;
  final String teacherId;
  final DateTime date;
  final String sessionStart;
  final String sessionEnd;
  AttendanceStatus status;
  final DateTime recordedAt;
}

/// One weekly class period created by a teacher for a given school.
class ScheduleEntry {
  ScheduleEntry({
    required this.id,
    required this.schoolId,
    required this.classGroupId,
    required this.subjectId,
    required this.teacherId,
    required this.weekday,
    required this.start,
    required this.end,
  });

  final String id;
  final String schoolId;
  final String classGroupId;
  final String subjectId;
  final String teacherId;

  /// [DateTime.monday] … [DateTime.sunday].
  int weekday;
  String start;
  String end;
}

/// Edit history for schedule changes (previous version preserved).
class ScheduleChange {
  ScheduleChange({required this.entryId, required this.before, required this.after, DateTime? changedAt})
      : changedAt = changedAt ?? DateTime.now();
  final String entryId;
  final String before;
  final String after;
  final DateTime changedAt;
}

enum NoteKind { educational, behavioral }

/// Private educational/behavioral note visible to the student's parents.
class StudentNote {
  StudentNote({
    required this.id,
    required this.studentId,
    required this.authorId,
    required this.schoolId,
    required this.kind,
    required this.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  final String id;
  final String studentId;
  final String authorId;
  final String schoolId;
  final NoteKind kind;
  final String text;
  final DateTime createdAt;
}

class Announcement {
  Announcement({
    required this.id,
    required this.authorId,
    required this.title,
    required this.body,
    this.schoolId,
    this.audience = 'all',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  final String id;
  final String? schoolId; // null → system-wide (owner)
  final String authorId;
  final String title;
  final String body;

  /// all | teachers | students | parents | classGroup:<id>
  final String audience;
  final DateTime createdAt;
}

// ───────────────────────────── Communication ─────────────────────────────

enum MessageType { text, image, file }

class Conversation {
  Conversation({
    required this.id,
    required this.schoolId,
    required this.participantIds,
    this.studentContextId,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();
  final String id;
  final String schoolId; // every conversation is tied to one school
  final List<String> participantIds;
  final String? studentContextId; // parent ↔ staff conversations about a child
  DateTime updatedAt;
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    this.text = '',
    this.fileName,
    DateTime? sentAt,
    this.readBy = const {},
  }) : sentAt = sentAt ?? DateTime.now();
  final String id;
  final String conversationId;
  final String senderId;
  final MessageType type;
  final String text;
  final String? fileName;
  final DateTime sentAt;
  Set<String> readBy;
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.body,
    this.route,
    this.read = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  final String id;
  final String userId;

  /// One of `notificationCategories`.
  final String category;
  final String title;
  final String body;
  final String? route;
  bool read;
  final DateTime createdAt;
}

// ───────────────────────────── Parents ─────────────────────────────

enum LinkStatus { pending, approved, rejected, cancelled }

/// Parent → child link request, reviewed by a chosen authorized staff member.
class ParentLinkRequest {
  ParentLinkRequest({
    required this.id,
    required this.parentId,
    required this.studentId,
    required this.schoolId,
    required this.approverId,
    required this.approverRole,
    required this.idDocumentName,
    this.ocrExtractedName,
    this.ocrMatch,
    this.status = LinkStatus.pending,
    this.decisionNote,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  final String id;
  final String parentId;
  final String studentId;
  final String schoolId;
  final String approverId;
  final UserRole approverRole;
  final String idDocumentName;

  /// OCR output is an *aid* for the reviewer only — it never proves
  /// authenticity or legal family relationship.
  final String? ocrExtractedName;
  final bool? ocrMatch;
  LinkStatus status;
  String? decisionNote;
  final DateTime createdAt;
}

/// Leave requests go to manager + responsible teacher + instructor at once;
/// approval from any one of them approves the request.
enum LeaveStatus { pending, approved, cancelled }

class LeaveRequest {
  LeaveRequest({
    required this.id,
    required this.parentId,
    required this.studentId,
    required this.schoolId,
    required this.date,
    required this.reason,
    required this.recipientIds,
    this.endDate,
    this.attachmentName,
    this.status = LeaveStatus.pending,
    this.approvedBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  final String id;
  final String parentId;
  final String studentId;
  final String schoolId;
  final DateTime date;
  final DateTime? endDate;
  final String reason;
  final String? attachmentName;
  final List<String> recipientIds;
  LeaveStatus status;
  String? approvedBy;
  final DateTime createdAt;
}

enum MeetingType { inPerson, audio, video }

enum MeetingStatus { pending, accepted, rejected, rescheduleProposed, completed, cancelled }

class Meeting {
  Meeting({
    required this.id,
    required this.parentId,
    required this.staffId,
    required this.studentId,
    required this.schoolId,
    required this.type,
    required this.scheduledAt,
    required this.topic,
    this.status = MeetingStatus.pending,
    this.proposedAt,
  });
  final String id;
  final String parentId;
  final String staffId;
  final String studentId;
  final String schoolId;
  final MeetingType type;
  DateTime scheduledAt;
  DateTime? proposedAt;
  final String topic;
  MeetingStatus status;
}

// ───────────────────────────── Library ─────────────────────────────

enum ResourceType { textbook, booklet, summary, studyMaterial, examResource }

class LibraryResource {
  LibraryResource({
    required this.id,
    required this.title,
    required this.type,
    required this.stage,
    required this.grade,
    required this.subjectId,
    required this.yearLabel,
    required this.uploaderId,
    required this.fileName,
    this.track = Track.none,
    this.description = '',
    this.pages = 0,
    this.extractedText = '',
    this.removedByOwner = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  final String id;
  String title;
  String description;
  final ResourceType type;
  final SchoolStage stage;
  final int grade;
  final Track track;
  final String subjectId;
  final String yearLabel;
  final String uploaderId;
  final String fileName;
  final int pages;

  /// Text extracted from the PDF (or OCR) for in-document search.
  final String extractedText;
  bool removedByOwner;
  final DateTime createdAt;
}

/// Previous Iraqi ministerial exam paper (rounds 1–3).
class MinisterialExam {
  MinisterialExam({
    required this.id,
    required this.stage,
    required this.grade,
    required this.subjectId,
    required this.year,
    required this.round,
    required this.fileName,
    this.track = Track.none,
    this.isImage = false,
  });
  final String id;
  final SchoolStage stage;
  final int grade;
  final Track track;
  final String subjectId;
  final int year;
  final int round; // 1, 2, 3
  final String fileName;
  final bool isImage;
}
