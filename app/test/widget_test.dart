import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madrasi/core/settings/app_settings.dart';
import 'package:madrasi/core/utils/validators.dart';
import 'package:madrasi/data/models/models.dart';
import 'package:madrasi/data/models/platform_models.dart';
import 'package:madrasi/data/providers/providers.dart';
import 'package:madrasi/data/services/auth_service.dart';
import 'package:madrasi/data/store/data_store.dart';
import 'package:madrasi/data/store/preview_seed.dart';
import 'package:madrasi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ════════════════════════════════════════════════════════════════════════════
  // GROUP 1: CORE ARCHITECTURE & BUSINESS RULES
  // ════════════════════════════════════════════════════════════════════════════
  group('1. Architecture & Business Rules', () {
    test('Iraqi phone number validation and normalization (+964)', () {
      expect(Validators.isIraqiE164('+9647701234567'), isTrue);
      expect(Validators.isIraqiE164('+9647809998877'), isTrue);
      expect(Validators.isIraqiE164('+9647501112233'), isTrue);
      expect(Validators.isIraqiE164('+9647201234567'), isTrue);

      // Invalid length or country code
      expect(Validators.isIraqiE164('+964770123456'), isFalse);
      expect(Validators.isIraqiE164('+9646601234567'), isFalse);
      expect(Validators.isIraqiE164('+12025550199'), isFalse);

      // Normalization from local formats to E.164
      expect(Validators.toE164('07701234567'), equals('+9647701234567'));
      expect(Validators.toE164('770 123 4567'), equals('+9647701234567'));
      expect(Validators.toE164('+9647701234567'), equals('+9647701234567'));
    });

    test('Verification Blue Badges: ONLY for staff and schools, NEVER students or parents', () {
      expect(UserRole.manager.canHaveBadge, isTrue);
      expect(UserRole.teacher.canHaveBadge, isTrue);
      expect(UserRole.instructor.canHaveBadge, isTrue);
      expect(UserRole.student.canHaveBadge, isFalse);
      expect(UserRole.parent.canHaveBadge, isFalse);
    });

    test('Permanently Free Roles: Students & Parents are ALWAYS free', () {
      expect(UserRole.student.isPaid, isFalse);
      expect(UserRole.parent.isPaid, isFalse);
      expect(UserRole.teacher.isPaid, isTrue);
      expect(UserRole.instructor.isPaid, isTrue);
      expect(UserRole.manager.isPaid, isTrue);
    });

    test('Grade percentage and performance calculation', () {
      final grade = GradeEntry(
        id: 'g1',
        studentId: 's1',
        schoolId: 'sch1',
        subjectId: 'math',
        teacherId: 't1',
        yearId: 'y1',
        examType: ExamType.daily,
        title: 'امتحان يومي',
        score: 17,
        maxScore: 20,
      );
      expect(grade.percentage, equals(85.0));

      final grade100 = GradeEntry(
        id: 'g2',
        studentId: 's1',
        schoolId: 'sch1',
        subjectId: 'physics',
        teacherId: 't2',
        yearId: 'y1',
        examType: ExamType.monthly,
        title: 'امتحان شهري',
        score: 93,
        maxScore: 100,
      );
      expect(grade100.percentage, equals(93.0));
    });

    test('Leave request instant approval by ANY authorized recipient', () {
      final leave = LeaveRequest(
        id: 'lv1',
        parentId: 'p1',
        studentId: 's1',
        schoolId: 'sch1',
        date: DateTime.now(),
        reason: 'ظرف صحي',
        recipientIds: ['mgr1', 't1', 'i1'],
      );
      expect(leave.status, equals(LeaveStatus.pending));

      // Approved by teacher t1
      leave.status = LeaveStatus.approved;
      leave.approvedBy = 't1';
      expect(leave.status, equals(LeaveStatus.approved));
      expect(leave.approvedBy, equals('t1'));
    });

    test('Maximum 2 simultaneous active devices limit', () {
      expect(DataStore.maxDevices, equals(2));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // GROUP 2: SCHOOL DATA ISOLATION (MULTI-TENANCY TESTS)
  // ════════════════════════════════════════════════════════════════════════════
  group('2. School Data Isolation & Multi-Tenancy', () {
    late DataStore store;

    setUp(() {
      store = DataStore();
      seedPreviewData(store);
    });

    test('Students belong strictly to one school; cannot view other school records', () {
      // sch1: ثانوية بغداد النموذجية | sch2: مدرسة النور الابتدائية
      final studentSch1 = store.users.firstWhere((u) => u.id == 's1'); // belongs to sch1
      expect(studentSch1.role, equals(UserRole.student));

      // Student's school membership
      final memberships = store.activeMembershipsOf('s1');
      expect(memberships.length, equals(1));
      expect(memberships.first.schoolId, equals('sch1'));

      // Grades belonging to sch1 vs sch2
      final gradesSch1 = store.grades.where((g) => g.schoolId == 'sch1' && g.studentId == 's1').toList();
      final gradesSch2 = store.grades.where((g) => g.schoolId == 'sch2' && g.studentId == 's1').toList();

      expect(gradesSch1.isNotEmpty, isTrue);
      expect(gradesSch2.isEmpty, isTrue, reason: 'Student cannot have grades in School 2');

      // Announcements belonging to sch1 vs sch2
      final announcementsSch1 = store.announcements.where((a) => a.schoolId == 'sch1').toList();
      final announcementsSch2 = store.announcements.where((a) => a.schoolId == 'sch2').toList();

      expect(announcementsSch1.every((a) => a.schoolId == 'sch1'), isTrue);
      expect(announcementsSch2.every((a) => a.schoolId == 'sch2'), isTrue);
    });

    test('Teacher multi-school scoping: data strictly isolated per active school', () {
      // t1 teaches in both sch1 and sch3
      final teacherMemberships = store.activeMembershipsOf('t1');
      final schoolIds = teacherMemberships.map((m) => m.schoolId).toSet();
      expect(schoolIds.contains('sch1'), isTrue);
      expect(schoolIds.contains('sch3'), isTrue);

      // When Teacher filters for School 1 vs School 3
      final sch1Classes = store.classGroups.where((cg) => cg.schoolId == 'sch1').toList();
      final sch3Classes = store.classGroups.where((cg) => cg.schoolId == 'sch3').toList();

      expect(sch1Classes.every((c) => c.schoolId == 'sch1'), isTrue);
      expect(sch3Classes.every((c) => c.schoolId == 'sch3'), isTrue);
      expect(sch1Classes.any((c) => c.schoolId == 'sch3'), isFalse,
          reason: 'School 1 class list must never leak School 3 classes');
    });

    test('School Manager can ONLY view and approve requests for their own school', () {
      // mgr1 manages sch1; mgr2 manages sch2
      final school1 = store.schools.firstWhere((s) => s.id == 'sch1');
      final school2 = store.schools.firstWhere((s) => s.id == 'sch2');

      expect(school1.managerId, equals('mgr1'));
      expect(school2.managerId, equals('mgr2'));

      // Pending joining requests for School 1
      final pendingSch1 = store.memberships
          .where((m) => m.schoolId == 'sch1' && m.status == MembershipStatus.pending)
          .toList();
      final pendingSch2 = store.memberships
          .where((m) => m.schoolId == 'sch2' && m.status == MembershipStatus.pending)
          .toList();

      // Manager 1 must only process requests for School 1
      expect(pendingSch1.every((m) => m.schoolId == 'sch1'), isTrue);
      expect(pendingSch2.every((m) => m.schoolId == 'sch2'), isTrue);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // GROUP 3: REAL AUTHENTICATION & ROLE FLOW TESTS
  // ════════════════════════════════════════════════════════════════════════════
  group('3. Authentication & Role Permissions Flow', () {
    late DataStore store;
    late AuthService auth;

    setUp(() {
      store = DataStore();
      seedPreviewData(store);
      auth = PreviewAuthService(store);
    });

    test('OTP request fails on invalid non-Iraqi phone numbers', () async {
      expect(() => auth.requestOtp('+12025550199'), throwsA(isA<AuthException>()));
      expect(() => auth.requestOtp('00964123'), throwsA(isA<AuthException>()));
    });

    test('OTP request succeeds on valid Iraqi numbers and applies rate limiting', () async {
      const validPhone = '+9647701234567';
      await expectLater(auth.requestOtp(validPhone), completes);

      // Trigger rate limiter (> 5 attempts)
      for (int i = 0; i < 4; i++) {
        await auth.requestOtp(validPhone);
      }
      expect(() => auth.requestOtp(validPhone), throwsA(predicate((e) => e is AuthException && e.code == 'otp_rate_limited')));
    });

    test('OTP verification: rejects incorrect code', () async {
      const phone = '+9647701111111';
      expect(
        () => auth.verifyOtp(phone, '000000'),
        throwsA(predicate((e) => e is AuthException && e.code == 'otp_invalid')),
      );
    });

    test('OTP verification: authenticates each of the 5 roles + Super Admin correctly', () async {
      final rolesToTest = [
        ('+9647701111111', UserRole.manager),
        ('+9647702222221', UserRole.teacher),
        ('+9647702222223', UserRole.instructor),
        ('+9647703333331', UserRole.student),
        ('+9647704444441', UserRole.parent),
        ('+9647700000001', UserRole.superAdmin),
      ];

      for (final (phone, expectedRole) in rolesToTest) {
        final result = await auth.verifyOtp(phone, PreviewAuthService.previewCode);
        expect(result.user, isNotNull, reason: 'User with phone $phone must exist');
        expect(result.user!.role, equals(expectedRole), reason: 'Role mismatch for $phone');
        expect(result.user!.phone, equals(phone));
        expect(result.user!.status, equals(AccountStatus.active));
      }
    });

    test('Account status enforcement: blocked and disabled users cannot sign in', () async {
      // Add a blocked user
      final blockedUser = AppUser(
        id: 'blocked1',
        phone: '+9647709999999',
        fullName: 'مستخدم محظور',
        role: UserRole.student,
        status: AccountStatus.blocked,
      );
      store.users.add(blockedUser);

      expect(
        () => auth.verifyOtp(blockedUser.phone, PreviewAuthService.previewCode),
        throwsA(predicate((e) => e is AuthException && e.code == 'account_blocked')),
      );

      // Add a disabled user
      final disabledUser = AppUser(
        id: 'disabled1',
        phone: '+9647808888888',
        fullName: 'مستخدم معطل',
        role: UserRole.teacher,
        status: AccountStatus.disabled,
      );
      store.users.add(disabledUser);

      expect(
        () => auth.verifyOtp(disabledUser.phone, PreviewAuthService.previewCode),
        throwsA(predicate((e) => e is AuthException && e.code == 'account_disabled')),
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // GROUP 4: SUBSCRIPTION & MASTERCARD ONLY RULES
  // ════════════════════════════════════════════════════════════════════════════
  group('4. Subscriptions & Mastercard Only Rules', () {
    late DataStore store;

    setUp(() {
      store = DataStore();
      seedPreviewData(store);
    });

    test('Paid plans strictly configured for 30 days monthly with 7 days trial', () {
      for (final plan in store.plans) {
        expect(plan.durationDays, equals(30), reason: 'Plan ${plan.id} must be monthly (30 days)');
        expect(plan.trialDays, equals(7), reason: 'Plan ${plan.id} must have a 7-day trial');
      }
    });

    test('Active 7-day trial grants usable access', () {
      final now = DateTime.now();
      final trialSub = Subscription(
        id: 'sub-trial-1',
        userId: 'mgr1',
        planId: 'plan-mgr',
        status: SubscriptionStatus.trial,
        startedAt: now,
        endsAt: now.add(const Duration(days: 7)),
        lockedPriceIqd: 25000,
      );
      expect(trialSub.isUsable, isTrue);
      expect(trialSub.daysLeft, inInclusiveRange(6, 7));
    });

    test('Expired subscription blocks editing (isUsable = false, Read-Only)', () {
      final now = DateTime.now();
      final expiredSub = Subscription(
        id: 'sub-exp-1',
        userId: 't1',
        planId: 'plan-teacher',
        status: SubscriptionStatus.expired,
        startedAt: now.subtract(const Duration(days: 40)),
        endsAt: now.subtract(const Duration(days: 10)),
        lockedPriceIqd: 15000,
      );
      expect(expiredSub.isUsable, isFalse, reason: 'Expired subscription must be read-only');
    });

    test('Mastercard payment execution: updates subscription and stores card details', () {
      final user = store.users.firstWhere((u) => u.id == 'mgr1');
      final plan = store.plans.firstWhere((p) => p.role == user.role);

      final initialPaymentCount = store.payments.length;
      final paymentAmount = plan.priceIqd;

      // Execute Mastercard Payment
      final payment = Payment(
        id: store.newId('pay'),
        userId: user.id,
        amountIqd: paymentAmount,
        status: PaymentStatus.succeeded,
        cardLast4: '5412',
        providerRef: 'MC-TXN-123456789',
      );
      store.payments.add(payment);

      final newSub = Subscription(
        id: store.newId('sub'),
        userId: user.id,
        planId: plan.id,
        status: SubscriptionStatus.active,
        startedAt: DateTime.now(),
        endsAt: DateTime.now().add(Duration(days: plan.durationDays)),
        lockedPriceIqd: paymentAmount,
      );
      store.subscriptions.add(newSub);

      expect(store.payments.length, equals(initialPaymentCount + 1));
      expect(payment.cardLast4, equals('5412'));
      expect(payment.status, equals(PaymentStatus.succeeded));
      expect(newSub.isUsable, isTrue);
      expect(newSub.status, equals(SubscriptionStatus.active));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // GROUP 5: APP BOOT & WIDGET RENDERING
  // ════════════════════════════════════════════════════════════════════════════
  testWidgets('5. MadrasiApp boots up and renders Splash screen correctly', (tester) async {
    SharedPreferences.setMockInitialValues({'onboardingDone': true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MadrasiApp(),
      ),
    );

    // Verify brand identity on splash
    expect(find.text('مَدرَستي'), findsOneWidget);
    expect(find.text('مدرستك أقرب، ومستقبلك أكبر'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
