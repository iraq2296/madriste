// Billing, verification, security, support and platform-administration models.

import 'models.dart';

// ───────────────────────────── Subscriptions & payments ─────────────────────────────

enum SubscriptionStatus { trial, active, expired, cancelled, grantedFree }

class SubscriptionPlan {
  SubscriptionPlan({
    required this.id,
    required this.role,
    required this.priceIqd,
    required this.durationDays,
    required this.trialDays,
    required this.effectiveFrom,
    this.active = true,
  });
  final String id;

  /// Plans are defined per paid role (manager / teacher / instructor).
  final UserRole role;
  int priceIqd;
  int durationDays;
  int trialDays;

  /// New prices apply to new purchases/renewals only from this date —
  /// active subscriptions keep their locked price until they renew.
  DateTime effectiveFrom;
  bool active;
}

class Subscription {
  Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.startedAt,
    required this.endsAt,
    required this.lockedPriceIqd,
    this.autoRenew = false,
  });
  final String id;
  final String userId;
  final String planId;
  SubscriptionStatus status;
  DateTime startedAt;
  DateTime endsAt;
  final int lockedPriceIqd;
  bool autoRenew;

  bool get isUsable =>
      (status == SubscriptionStatus.trial ||
          status == SubscriptionStatus.active ||
          status == SubscriptionStatus.grantedFree) &&
      endsAt.isAfter(DateTime.now());

  int get daysLeft => endsAt.difference(DateTime.now()).inDays.clamp(0, 100000);
}

class Discount {
  Discount({
    required this.id,
    required this.code,
    required this.percent,
    required this.startsAt,
    required this.endsAt,
    this.roles = const {UserRole.manager, UserRole.teacher, UserRole.instructor},
    this.active = true,
  });
  final String id;
  final String code;
  final int percent;
  final DateTime startsAt; // scheduled promotions start in the future
  final DateTime endsAt;
  final Set<UserRole> roles;
  bool active;
}

/// Manual extension / free grant performed by the owner (always audited).
class ManualExtension {
  ManualExtension({
    required this.id,
    required this.userId,
    required this.days,
    required this.reason,
    required this.grantedBy,
    this.isFreeGrant = false,
    DateTime? at,
  }) : at = at ?? DateTime.now();
  final String id;
  final String userId;
  final int days;
  final String reason;
  final String grantedBy;
  final bool isFreeGrant;
  final DateTime at;
}

enum PaymentStatus { pending, succeeded, failed, refunded }

class Payment {
  Payment({
    required this.id,
    required this.userId,
    required this.amountIqd,
    required this.status,
    required this.cardLast4,
    required this.providerRef,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  final String id;
  final String userId;
  final int amountIqd;
  PaymentStatus status;

  /// Only Mastercard is accepted. Card data never touches our servers —
  /// only the gateway token reference and last 4 digits are stored.
  final String cardLast4;
  final String providerRef;
  final DateTime createdAt;
}

// ───────────────────────────── Verification ─────────────────────────────

enum VerificationKind { identity, managerPosition, professional, school }

class VerificationRecord {
  VerificationRecord({
    required this.id,
    required this.kind,
    required this.status,
    this.userId,
    this.schoolId,
    this.documents = const [],
    this.faceMatchScore,
    this.livenessPassed,
    this.failedAttempts = 0,
    this.lockedUntil,
    this.reviewerId,
    this.reviewNote,
    DateTime? submittedAt,
  }) : submittedAt = submittedAt ?? DateTime.now();
  final String id;
  final VerificationKind kind;
  VerificationStatus status;
  final String? userId;
  final String? schoolId;
  final List<String> documents;
  final double? faceMatchScore;
  final bool? livenessPassed;
  int failedAttempts;
  DateTime? lockedUntil;
  String? reviewerId;
  String? reviewNote;
  final DateTime submittedAt;

  /// Raw images/documents are purged monthly by the retention job; only the
  /// status + audit metadata are kept.
  DateTime get retentionPurgeAt => DateTime(submittedAt.year, submittedAt.month + 1, 1);
}

// ───────────────────────────── Security ─────────────────────────────

class DeviceSession {
  DeviceSession({
    required this.id,
    required this.userId,
    required this.deviceName,
    required this.platform,
    required this.lastActive,
    this.isCurrent = false,
    this.city,
  });
  final String id;
  final String userId;
  final String deviceName;
  final String platform;
  DateTime lastActive;
  final bool isCurrent;
  final String? city;
}

enum SecurityEventType {
  login,
  newDevice,
  remoteLogout,
  phoneChanged,
  recoveryAttempt,
  verificationFailed,
  appLockChanged,
  alert,
}

class SecurityEvent {
  SecurityEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    this.device,
    DateTime? at,
  }) : at = at ?? DateTime.now();
  final String id;
  final String userId;
  final SecurityEventType type;
  final String description;
  final String? device;
  final DateTime at;
}

enum DeletionStatus { pending, processing, completed }

class DeletionRequest {
  DeletionRequest({
    required this.id,
    required this.userId,
    this.status = DeletionStatus.pending,
    this.note,
    DateTime? requestedAt,
    this.completedAt,
  }) : requestedAt = requestedAt ?? DateTime.now();
  final String id;
  final String userId;
  DeletionStatus status;
  String? note;
  final DateTime requestedAt;
  DateTime? completedAt;
}

enum RecoveryStatus { submitted, manualReview, approved, rejected }

class RecoveryRequest {
  RecoveryRequest({
    required this.id,
    required this.phone,
    required this.documentName,
    this.userId,
    this.ocrName,
    this.matchScore,
    this.status = RecoveryStatus.submitted,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  final String id;
  final String phone;
  final String? userId;
  final String documentName;
  final String? ocrName;
  final double? matchScore;
  RecoveryStatus status;
  final DateTime createdAt;
}

// ───────────────────────────── Support & feedback ─────────────────────────────

enum TicketCategory { technical, account, subscription, school }

enum TicketStatus { open, inProgress, resolved, closed }

class TicketReply {
  TicketReply({required this.authorId, required this.text, DateTime? at}) : at = at ?? DateTime.now();
  final String authorId;
  final String text;
  final DateTime at;
}

class SupportTicket {
  SupportTicket({
    required this.id,
    required this.userId,
    required this.category,
    required this.subject,
    required this.body,
    this.schoolId,
    this.status = TicketStatus.open,
    List<TicketReply>? replies,
    DateTime? createdAt,
  })  : replies = replies ?? [],
        createdAt = createdAt ?? DateTime.now();
  final String id;
  final String userId;

  /// School complaints are routed to the school manager too (owner still sees them).
  final String? schoolId;
  final TicketCategory category;
  final String subject;
  final String body;
  TicketStatus status;
  final List<TicketReply> replies;
  final DateTime createdAt;
}

enum SuggestionStatus { submitted, underReview, accepted, rejected }

class Suggestion {
  Suggestion({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.imageName,
    this.status = SuggestionStatus.submitted,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  final String id;
  final String userId;
  final String title;
  final String description;
  final String? imageName;
  SuggestionStatus status;
  final DateTime createdAt;
}

/// Anonymous survey: only aggregate counts are stored alongside the poll.
/// Duplicate-vote prevention uses a salted one-way hash of the user id kept
/// in a separate table that is never joined with the chosen option.
class Survey {
  Survey({
    required this.id,
    required this.question,
    required this.options,
    required this.targetRoles,
    required this.startsAt,
    required this.endsAt,
    List<int>? counts,
  }) : counts = counts ?? List.filled(options.length, 0);
  final String id;
  final String question;
  final List<String> options;
  final Set<UserRole> targetRoles;
  final DateTime startsAt;
  final DateTime endsAt;
  final List<int> counts;

  int get totalVotes => counts.fold(0, (a, b) => a + b);
  bool get isOpen {
    final now = DateTime.now();
    return now.isAfter(startsAt) && now.isBefore(endsAt);
  }
}

// ───────────────────────────── Platform admin ─────────────────────────────

class AuditLog {
  AuditLog({
    required this.id,
    required this.actorId,
    required this.action,
    required this.target,
    this.reason,
    DateTime? at,
  }) : at = at ?? DateTime.now();
  final String id;
  final String actorId;
  final String action;
  final String target;
  final String? reason;
  final DateTime at;
}

class SupportAccessSession {
  SupportAccessSession({
    required this.id,
    required this.ownerId,
    required this.targetUserId,
    required this.reason,
    DateTime? startedAt,
    this.endedAt,
    List<String>? actions,
  })  : startedAt = startedAt ?? DateTime.now(),
        actions = actions ?? [];
  final String id;
  final String ownerId;
  final String targetUserId;
  final String reason;
  final DateTime startedAt;
  DateTime? endedAt;
  final List<String> actions;
}

enum BackupStatus { running, success, failed }

class BackupRecord {
  BackupRecord({
    required this.id,
    required this.isAutomatic,
    required this.status,
    required this.sizeMb,
    this.scope = 'full',
    this.storage = 'Separate encrypted bucket (AES-256)',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  final String id;
  final bool isAutomatic;
  BackupStatus status;
  final double sizeMb;
  final String scope; // full | school:<id>
  final String storage;
  final DateTime createdAt;
}

class PolicyDocument {
  PolicyDocument({
    required this.slug,
    required this.title,
    required this.body,
    this.version = 1,
    DateTime? updatedAt,
    List<String>? history,
  })  : updatedAt = updatedAt ?? DateTime.now(),
        history = history ?? [];

  /// terms | privacy | subscription | payment | registration | verification | rules | faq
  final String slug;
  LocalizedText title;
  LocalizedText body;
  int version;
  DateTime updatedAt;
  final List<String> history;
}

class AppVersionPolicy {
  AppVersionPolicy({
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.notes,
    this.mandatory = false,
    Map<String, int>? adoption,
  }) : adoption = adoption ?? {};
  String latestVersion;
  String minSupportedVersion;
  String notes;
  bool mandatory;
  final Map<String, int> adoption;
}

class MaintenanceState {
  MaintenanceState({this.enabled = false, this.message = '', this.eta});
  bool enabled;
  String message;
  DateTime? eta;
}

class ServerHealth {
  ServerHealth({
    required this.apiUp,
    required this.responseMs,
    required this.cpu,
    required this.ram,
    required this.storage,
    required this.dbUp,
    required this.connectedUsers,
    required this.pushUp,
    required this.rtcUp,
    required this.incidents,
  });
  final bool apiUp;
  final int responseMs;
  final double cpu;
  final double ram;
  final double storage;
  final bool dbUp;
  final int connectedUsers;
  final bool pushUp;
  final bool rtcUp;
  final List<String> incidents;
}

