import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madrasi/core/settings/app_settings.dart';
import 'package:madrasi/core/utils/validators.dart';
import 'package:madrasi/data/models/models.dart';
import 'package:madrasi/data/providers/providers.dart';
import 'package:madrasi/data/store/data_store.dart';
import 'package:madrasi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MADRASI Core Rules & Architecture Tests', () {
    test('Iraqi phone number validation and normalization', () {
      expect(Validators.isIraqiE164('+9647701234567'), isTrue);
      expect(Validators.isIraqiE164('+9647809998877'), isTrue);
      expect(Validators.isIraqiE164('+9647501112233'), isTrue);
      expect(Validators.isIraqiE164('+9647201234567'), isTrue);
      // Non-Iraqi or invalid length
      expect(Validators.isIraqiE164('+964770123456'), isFalse);
      expect(Validators.isIraqiE164('+9646601234567'), isFalse);
      expect(Validators.isIraqiE164('+12025550199'), isFalse);

      expect(Validators.toE164('07701234567'), equals('+9647701234567'));
      expect(Validators.toE164('770 123 4567'), equals('+9647701234567'));
      expect(Validators.toE164('+9647701234567'), equals('+9647701234567'));
    });

    test('Verification Blue Badges permission rule', () {
      // PER SPEC: Blue verification badges are available ONLY to:
      // 1. Schools, 2. School Managers, 3. Teachers, 4. Instructors.
      // MUST NOT be given to students or parents.
      expect(UserRole.manager.canHaveBadge, isTrue);
      expect(UserRole.teacher.canHaveBadge, isTrue);
      expect(UserRole.instructor.canHaveBadge, isTrue);
      expect(UserRole.student.canHaveBadge, isFalse);
      expect(UserRole.parent.canHaveBadge, isFalse);
    });

    test('Paid subscription roles rule', () {
      // Students and parents are permanently free.
      expect(UserRole.student.isPaid, isFalse);
      expect(UserRole.parent.isPaid, isFalse);
      expect(UserRole.teacher.isPaid, isTrue);
      expect(UserRole.instructor.isPaid, isTrue);
      expect(UserRole.manager.isPaid, isTrue);
    });

    test('Grade percentage automatic calculation', () {
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
      // 17 / 20 = 85.0%
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

    test('Leave request approval rule', () {
      // PER SPEC: Approval from ANY ONE authorized recipient immediately approves
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

      // Approved by manager
      leave.status = LeaveStatus.approved;
      leave.approvedBy = 'mgr1';
      expect(leave.status, equals(LeaveStatus.approved));
    });

    test('Max 2 simultaneous devices limit', () {
      expect(DataStore.maxDevices, equals(2));
    });
  });

  testWidgets('MadrasiApp boots up and renders Splash screen', (tester) async {
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

    // Verify app title and logo text render
    expect(find.text('مَدرَستي'), findsOneWidget);
    expect(find.text('مدرستك أقرب، ومستقبلك أكبر'), findsOneWidget);

    // Advance timer past splash transition
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
