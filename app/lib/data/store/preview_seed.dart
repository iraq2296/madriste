import '../models/models.dart';
import '../models/platform_models.dart';
import 'data_store.dart';

/// Seeds [store] with realistic sample data for **preview mode only**.
///
/// Never called when the backend is configured. All names/phones are fictional.
void seedPreviewData(DataStore store) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime d(int days) => today.add(Duration(days: days));

  // ───────────── Subjects ─────────────
  store.subjects.addAll(const [
    Subject(id: 'math', name: LocalizedText('الرياضيات', 'Mathematics', 'بیرکاری'), iconKey: 'math', colorIndex: 0),
    Subject(id: 'physics', name: LocalizedText('الفيزياء', 'Physics', 'فیزیا'), iconKey: 'physics', colorIndex: 3),
    Subject(id: 'chemistry', name: LocalizedText('الكيمياء', 'Chemistry', 'کیمیا'), iconKey: 'chemistry', colorIndex: 1),
    Subject(id: 'biology', name: LocalizedText('الأحياء', 'Biology', 'زیندەزانی'), iconKey: 'biology', colorIndex: 5),
    Subject(id: 'arabic', name: LocalizedText('اللغة العربية', 'Arabic', 'عەرەبی'), iconKey: 'arabic', colorIndex: 2),
    Subject(id: 'english', name: LocalizedText('اللغة الإنكليزية', 'English', 'ئینگلیزی'), iconKey: 'english', colorIndex: 6),
    Subject(id: 'islamic', name: LocalizedText('التربية الإسلامية', 'Islamic Education', 'پەروەردەی ئیسلامی'), iconKey: 'islamic', colorIndex: 1),
    Subject(id: 'computer', name: LocalizedText('الحاسوب', 'Computer', 'کۆمپیوتەر'), iconKey: 'computer', colorIndex: 7),
    Subject(id: 'kurdish', name: LocalizedText('اللغة الكردية', 'Kurdish', 'کوردی'), iconKey: 'kurdish', colorIndex: 4),
    Subject(id: 'history', name: LocalizedText('التاريخ', 'History', 'مێژوو'), iconKey: 'history', colorIndex: 6),
    Subject(id: 'geography', name: LocalizedText('الجغرافية', 'Geography', 'جوگرافیا'), iconKey: 'geography', colorIndex: 5),
    Subject(id: 'science', name: LocalizedText('العلوم', 'Science', 'زانست'), iconKey: 'science', colorIndex: 1),
  ]);

  // ───────────── Users ─────────────
  AppUser u(String id, String name, String phone, UserRole role,
          {bool badge = false,
          String? spec,
          List<String> subjects = const [],
          String? code,
          String? gov,
          VerificationStatus v = VerificationStatus.verified,
          int ageDays = 200}) =>
      AppUser(
        id: id,
        fullName: name,
        phone: phone,
        role: role,
        badgeVerified: badge,
        specialization: spec,
        subjectIds: subjects,
        teacherCode: code,
        governorate: gov,
        verification: v,
        createdAt: now.subtract(Duration(days: ageDays)),
      );

  store.users.addAll([
    u('owner', 'مالك منصة مدرستي', '+9647700000001', UserRole.superAdmin, ageDays: 400),
    u('mgr1', 'د. سعد كاظم الربيعي', '+9647701111111', UserRole.manager, badge: true, gov: 'بغداد', ageDays: 380),
    u('mgr2', 'أ. هدى جاسم البصري', '+9647801111112', UserRole.manager, badge: true, gov: 'البصرة', ageDays: 300),
    u('mgr3', 'أ. ياسر محمود الموصلي', '+9647501111113', UserRole.manager,
        gov: 'نينوى', v: VerificationStatus.manualReview, ageDays: 3),
    u('t1', 'أ. علي حسين العبيدي', '+9647702222221', UserRole.teacher,
        badge: true, spec: 'رياضيات', subjects: ['math'], code: 'MATH-7314', ageDays: 360),
    u('t2', 'أ. زينب محمد الخفاجي', '+9647702222222', UserRole.teacher,
        badge: true, spec: 'فيزياء', subjects: ['physics'], code: 'PHYS-2290', ageDays: 340),
    u('i1', 'م. حيدر عباس الساعدي', '+9647702222223', UserRole.instructor,
        spec: 'لغة إنكليزية', subjects: ['english'], code: 'ENG-5521', ageDays: 300),
    u('t3', 'أ. رنا صباح الجبوري', '+9647702222224', UserRole.teacher,
        spec: 'لغة عربية', subjects: ['arabic'], code: 'ARB-8812', v: VerificationStatus.pending, ageDays: 2),
    u('i2', 'م. فاطمة كريم الأسدي', '+9647802222225', UserRole.instructor,
        badge: true, spec: 'علوم', subjects: ['science', 'arabic'], code: 'SCI-4410', ageDays: 250),
    u('s1', 'أحمد علي عبد الله', '+9647703333331', UserRole.student, ageDays: 330),
    u('s2', 'مريم حسن كريم', '+9647703333332', UserRole.student, ageDays: 320),
    u('s3', 'يوسف قاسم جواد', '+9647703333333', UserRole.student, ageDays: 320),
    u('s4', 'نور الهدى سالم', '+9647703333334', UserRole.student, ageDays: 310),
    u('s5', 'حسين جبار ناصر', '+9647703333335', UserRole.student, ageDays: 300),
    u('s6', 'سارة عادل فاضل', '+9647703333336', UserRole.student, ageDays: 290),
    u('s7', 'زهراء علي عبد الله', '+9647803333337', UserRole.student, ageDays: 200),
    u('s8', 'كرار ماجد حميد', '+9647703333338', UserRole.student, v: VerificationStatus.pending, ageDays: 1),
    u('p1', 'علي عبد الله محمود', '+9647704444441', UserRole.parent, ageDays: 210),
    u('p2', 'حسن كريم مهدي', '+9647704444442', UserRole.parent, ageDays: 20),
  ]);

  // ───────────── Schools ─────────────
  store.schools.addAll([
    School(id: 'sch1', name: 'ثانوية بغداد النموذجية', governorate: 'بغداد', district: 'الكرخ – المنصور',
        stages: {SchoolStage.intermediate, SchoolStage.preparatory}, managerId: 'mgr1', verified: true,
        lat: 33.312, lng: 44.361, phone: '+9647701111100', createdAt: now.subtract(const Duration(days: 380))),
    School(id: 'sch2', name: 'مدرسة النور الابتدائية', governorate: 'البصرة', district: 'العشار',
        stages: {SchoolStage.primary}, managerId: 'mgr2', verified: true,
        lat: 30.508, lng: 47.783, createdAt: now.subtract(const Duration(days: 300))),
    School(id: 'sch3', name: 'إعدادية الرافدين للبنين', governorate: 'نينوى', district: 'الموصل – الجانب الأيسر',
        stages: {SchoolStage.preparatory}, managerId: 'mgr3',
        lat: 36.345, lng: 43.157, createdAt: now.subtract(const Duration(days: 3))),
  ]);

  // ───────────── Academic years ─────────────
  store.academicYears.addAll([
    AcademicYear(id: 'y1', schoolId: 'sch1', label: '2025–2026', startsOn: DateTime(2025, 9, 21), endsOn: DateTime(2026, 6, 30), archived: true),
    AcademicYear(id: 'y2', schoolId: 'sch1', label: '2026–2027', startsOn: DateTime(2026, 9, 20), endsOn: DateTime(2027, 6, 30), isCurrent: true),
    AcademicYear(id: 'y3', schoolId: 'sch2', label: '2026–2027', startsOn: DateTime(2026, 9, 20), endsOn: DateTime(2027, 6, 30), isCurrent: true),
    AcademicYear(id: 'y4', schoolId: 'sch3', label: '2026–2027', startsOn: DateTime(2026, 9, 20), endsOn: DateTime(2027, 6, 30), isCurrent: true),
  ]);

  // ───────────── Class groups ─────────────
  store.classGroups.addAll([
    ClassGroup(id: 'cg1', schoolId: 'sch1', stage: SchoolStage.preparatory, grade: 5, track: Track.scientific, section: 'A'),
    ClassGroup(id: 'cg2', schoolId: 'sch1', stage: SchoolStage.preparatory, grade: 5, track: Track.scientific, section: 'B'),
    ClassGroup(id: 'cg3', schoolId: 'sch1', stage: SchoolStage.preparatory, grade: 6, track: Track.scientific, section: 'A'),
    ClassGroup(id: 'cg4', schoolId: 'sch1', stage: SchoolStage.intermediate, grade: 3, section: 'A'),
    ClassGroup(id: 'cg5', schoolId: 'sch1', stage: SchoolStage.preparatory, grade: 4, track: Track.literary, section: 'A'),
    ClassGroup(id: 'cg6', schoolId: 'sch2', stage: SchoolStage.primary, grade: 4, section: 'A'),
    ClassGroup(id: 'cg7', schoolId: 'sch3', stage: SchoolStage.preparatory, grade: 6, track: Track.scientific, section: 'A'),
  ]);

  // ───────────── Memberships ─────────────
  Membership m(String id, String user, String school, UserRole role,
          {MembershipStatus st = MembershipStatus.approved,
          List<String> cgs = const [],
          List<String> subs = const [],
          bool invite = false,
          int ageDays = 100}) =>
      Membership(
        id: id,
        userId: user,
        schoolId: school,
        role: role,
        status: st,
        classGroupIds: cgs,
        subjectIds: subs,
        viaInvite: invite,
        createdAt: now.subtract(Duration(days: ageDays)),
      );

  store.memberships.addAll([
    m('ms1', 'mgr1', 'sch1', UserRole.manager),
    m('ms2', 'mgr2', 'sch2', UserRole.manager),
    m('ms3', 'mgr3', 'sch3', UserRole.manager),
    m('ms4', 't1', 'sch1', UserRole.teacher, cgs: ['cg1', 'cg2', 'cg3'], subs: ['math']),
    m('ms5', 't1', 'sch3', UserRole.teacher, cgs: ['cg7'], subs: ['math'], invite: true),
    m('ms6', 't2', 'sch1', UserRole.teacher, cgs: ['cg1', 'cg2', 'cg3'], subs: ['physics']),
    m('ms7', 'i1', 'sch1', UserRole.instructor, cgs: ['cg1', 'cg2', 'cg4'], subs: ['english']),
    m('ms8', 't3', 'sch1', UserRole.teacher, st: MembershipStatus.pending, cgs: ['cg4', 'cg5'], subs: ['arabic'], ageDays: 1),
    m('ms9', 'i2', 'sch2', UserRole.instructor, cgs: ['cg6'], subs: ['science', 'arabic']),
    m('ms10', 's1', 'sch1', UserRole.student, cgs: ['cg1']),
    m('ms11', 's2', 'sch1', UserRole.student, cgs: ['cg1']),
    m('ms12', 's3', 'sch1', UserRole.student, cgs: ['cg1']),
    m('ms13', 's4', 'sch1', UserRole.student, cgs: ['cg1']),
    m('ms14', 's5', 'sch1', UserRole.student, cgs: ['cg1']),
    m('ms15', 's6', 'sch1', UserRole.student, cgs: ['cg2']),
    m('ms16', 's7', 'sch2', UserRole.student, cgs: ['cg6']),
    m('ms17', 's8', 'sch1', UserRole.student, st: MembershipStatus.pending, cgs: ['cg1'], ageDays: 0),
  ]);

  store.follows.addAll([
    TeacherFollow(studentId: 's1', teacherId: 't1', schoolId: 'sch1'),
    TeacherFollow(studentId: 's1', teacherId: 't2', schoolId: 'sch1'),
    TeacherFollow(studentId: 's1', teacherId: 'i1', schoolId: 'sch1'),
    TeacherFollow(studentId: 's2', teacherId: 't1', schoolId: 'sch1'),
  ]);

  // ───────────── Weekly schedule (Iraqi week: Sunday–Thursday) ─────────────
  var se = 0;
  void sch(String cg, String subj, String teacher, int weekday, String start, String end) => store.schedule.add(
        ScheduleEntry(id: 'se${se++}', schoolId: 'sch1', classGroupId: cg, subjectId: subj, teacherId: teacher,
            weekday: weekday, start: start, end: end),
      );
  for (final day in [DateTime.sunday, DateTime.tuesday, DateTime.thursday]) {
    sch('cg1', 'math', 't1', day, '08:00', '08:45');
    sch('cg2', 'math', 't1', day, '08:50', '09:35');
    sch('cg1', 'physics', 't2', day, '09:45', '10:30');
  }
  for (final day in [DateTime.monday, DateTime.wednesday]) {
    sch('cg1', 'english', 'i1', day, '08:00', '08:45');
    sch('cg1', 'math', 't1', day, '08:50', '09:35');
    sch('cg3', 'math', 't1', day, '09:45', '10:30');
    sch('cg2', 'physics', 't2', day, '10:40', '11:25');
  }
  store.scheduleHistory.add(ScheduleChange(
      entryId: 'se0', before: 'الأحد 07:45 – 08:30', after: 'الأحد 08:00 – 08:45', changedAt: now.subtract(const Duration(days: 12))));

  // ───────────── Attendance (per class session, last ~5 weeks) ─────────────
  final cg1Students = ['s1', 's2', 's3', 's4', 's5'];
  var att = 0;
  for (var back = 35; back >= 1; back--) {
    final day = d(-back);
    if (day.weekday == DateTime.friday || day.weekday == DateTime.saturday) continue;
    final entries = store.schedule.where((e) => e.classGroupId == 'cg1' && e.weekday == day.weekday);
    for (final e in entries) {
      for (var i = 0; i < cg1Students.length; i++) {
        final h = (back * 7 + i * 13 + e.start.hashCode) % 23;
        final status = h == 0 || h == 11
            ? AttendanceStatus.absent
            : h == 5 || h == 17
                ? AttendanceStatus.late
                : AttendanceStatus.present;
        store.attendance.add(AttendanceRecord(
          id: 'att${att++}', studentId: cg1Students[i], schoolId: 'sch1', classGroupId: 'cg1',
          subjectId: e.subjectId, teacherId: e.teacherId, date: day, sessionStart: e.start, sessionEnd: e.end,
          status: status, recordedAt: day.add(const Duration(hours: 9)),
        ));
      }
    }
  }
  // Child at the second school
  for (var back = 20; back >= 1; back--) {
    final day = d(-back);
    if (day.weekday == DateTime.friday || day.weekday == DateTime.saturday) continue;
    store.attendance.add(AttendanceRecord(
      id: 'att${att++}', studentId: 's7', schoolId: 'sch2', classGroupId: 'cg6', subjectId: 'science',
      teacherId: 'i2', date: day, sessionStart: '08:00', sessionEnd: '08:40',
      status: back % 9 == 0 ? AttendanceStatus.absent : (back % 7 == 0 ? AttendanceStatus.late : AttendanceStatus.present),
    ));
  }

  // ───────────── Exams ─────────────
  store.exams.addAll([
    ExamSchedule(id: 'ex1', schoolId: 'sch1', classGroupId: 'cg1', subjectId: 'math', teacherId: 't1', yearId: 'y2',
        type: ExamType.monthly, date: d(5), startTime: '08:00', maxGrade: 100, notes: 'الفصل الثاني والثالث'),
    ExamSchedule(id: 'ex2', schoolId: 'sch1', classGroupId: 'cg1', subjectId: 'physics', teacherId: 't2', yearId: 'y2',
        type: ExamType.daily, date: d(2), startTime: '09:45', maxGrade: 10),
    ExamSchedule(id: 'ex3', schoolId: 'sch1', classGroupId: 'cg1', subjectId: 'english', teacherId: 'i1', yearId: 'y2',
        type: ExamType.monthly, date: d(9), startTime: '08:00', maxGrade: 50),
    ExamSchedule(id: 'ex4', schoolId: 'sch1', classGroupId: 'cg1', subjectId: 'math', teacherId: 't1', yearId: 'y2',
        type: ExamType.daily, date: d(-6), startTime: '08:00', maxGrade: 20, resultsPublished: true),
    ExamSchedule(id: 'ex5', schoolId: 'sch2', classGroupId: 'cg6', subjectId: 'science', teacherId: 'i2', yearId: 'y3',
        type: ExamType.monthly, date: d(4), startTime: '08:30', maxGrade: 100),
  ]);

  // ───────────── Grades ─────────────
  var g = 0;
  void grade(String st, String subj, String teacher, String year, ExamType type, String title, double score, double max,
          int daysAgo, {String school = 'sch1'}) =>
      store.grades.add(GradeEntry(
        id: 'gr${g++}', studentId: st, schoolId: school, subjectId: subj, teacherId: teacher, yearId: year,
        examType: type, title: title, score: score, maxScore: max, publishedAt: now.subtract(Duration(days: daysAgo)),
      ));
  final scores = {'s1': 17.0, 's2': 19.0, 's3': 12.0, 's4': 15.0, 's5': 9.0};
  scores.forEach((st, sc) {
    grade(st, 'math', 't1', 'y2', ExamType.daily, 'امتحان يومي – الفصل الأول', sc, 20, 5);
    grade(st, 'physics', 't2', 'y2', ExamType.daily, 'امتحان يومي – الحركة', (sc / 2).roundToDouble(), 10, 8);
    grade(st, 'english', 'i1', 'y2', ExamType.monthly, 'امتحان شهر تشرين الأول', sc * 4.5, 100, 15);
    grade(st, 'math', 't1', 'y2', ExamType.monthly, 'امتحان شهر تشرين الأول', sc * 4.6, 100, 18);
  });
  // Previous academic year results (archived year y1)
  for (final e in {'math': 88.0, 'physics': 79.0, 'english': 91.0, 'chemistry': 74.0, 'arabic': 82.0}.entries) {
    grade('s1', e.key, 't1', 'y1', ExamType.midyear, 'نتيجة نصف السنة', e.value - 4, 100, 300);
    grade('s1', e.key, 't1', 'y1', ExamType.finalYear, 'النتيجة النهائية', e.value, 100, 150);
  }
  grade('s7', 'science', 'i2', 'y3', ExamType.daily, 'امتحان يومي – النباتات', 9, 10, 4, school: 'sch2');
  grade('s7', 'arabic', 'i2', 'y3', ExamType.monthly, 'امتحان شهر تشرين الأول', 46, 50, 12, school: 'sch2');

  // ───────────── Lessons ─────────────
  store.lessons.addAll([
    Lesson(id: 'ls1', schoolId: 'sch1', classGroupId: 'cg1', subjectId: 'math', teacherId: 't1', yearId: 'y2',
        title: 'الغايات والاستمرارية – المحاضرة 3', body: 'شرح مفهوم الغاية من اليمين واليسار مع أمثلة محلولة وتمارين.',
        type: LessonType.pdf, attachmentName: 'limits_lecture3.pdf', publishedAt: now.subtract(const Duration(hours: 5))),
    Lesson(id: 'ls2', schoolId: 'sch1', classGroupId: 'cg1', subjectId: 'physics', teacherId: 't2', yearId: 'y2',
        title: 'صورة السبورة: قوانين نيوتن', body: 'ملخص ما تم شرحه اليوم على السبورة.',
        type: LessonType.board, attachmentName: 'board_newton.jpg', publishedAt: now.subtract(const Duration(days: 1))),
    Lesson(id: 'ls3', schoolId: 'sch1', classGroupId: 'cg1', subjectId: 'english', teacherId: 'i1', yearId: 'y2',
        title: 'Unit 4 – Reading Skills', body: 'Watch the video and read pages 42–45 before next class.',
        type: LessonType.video, attachmentName: 'unit4_reading.mp4', publishedAt: now.subtract(const Duration(days: 2))),
    Lesson(id: 'ls4', schoolId: 'sch1', classGroupId: 'cg1', subjectId: 'math', teacherId: 't1', yearId: 'y2',
        title: 'ملزمة الفصل الأول', body: 'ملزمة شاملة للفصل الأول مع أسئلة وزارية سابقة.',
        type: LessonType.booklet, attachmentName: 'math_ch1_booklet.pdf', publishedAt: now.subtract(const Duration(days: 4))),
    Lesson(id: 'ls5', schoolId: 'sch1', classGroupId: 'cg1', subjectId: 'physics', teacherId: 't2', yearId: 'y2',
        title: 'ملاحظات حول الامتحان اليومي', body: 'يشمل الامتحان اليومي القادم موضوع الحركة الخطية فقط.',
        type: LessonType.text, publishedAt: now.subtract(const Duration(days: 6))),
    Lesson(id: 'ls6', schoolId: 'sch2', classGroupId: 'cg6', subjectId: 'science', teacherId: 'i2', yearId: 'y3',
        title: 'أجزاء النبات', body: 'درس مصوّر عن أجزاء النبات ووظائفها.',
        type: LessonType.image, attachmentName: 'plant_parts.png', publishedAt: now.subtract(const Duration(days: 1))),
  ]);

  // ───────────── Announcements & notes ─────────────
  store.announcements.addAll([
    Announcement(id: 'an1', schoolId: 'sch1', authorId: 'mgr1', title: 'اجتماع أولياء الأمور',
        body: 'يُعقد اجتماع أولياء الأمور يوم الخميس القادم الساعة العاشرة صباحاً في قاعة المدرسة.',
        createdAt: now.subtract(const Duration(hours: 20))),
    Announcement(id: 'an2', schoolId: 'sch1', authorId: 'mgr1', title: 'عطلة رسمية',
        body: 'تعطل الدراسة يوم الأحد القادم بمناسبة العطلة الرسمية.', createdAt: now.subtract(const Duration(days: 3))),
    Announcement(id: 'an3', schoolId: 'sch2', authorId: 'mgr2', title: 'بدء التسجيل في النشاط الرياضي',
        body: 'يمكن للطلبة التسجيل في الفرق الرياضية حتى نهاية الأسبوع.', createdAt: now.subtract(const Duration(days: 2))),
    Announcement(id: 'an4', authorId: 'owner', title: 'مرحباً بكم في مدرستي',
        body: 'تم إطلاق الإصدار الجديد من التطبيق مع تحسينات في الأداء.', createdAt: now.subtract(const Duration(days: 7))),
  ]);
  store.notes.addAll([
    StudentNote(id: 'nt1', studentId: 's1', authorId: 't1', schoolId: 'sch1', kind: NoteKind.educational,
        text: 'أحمد متميز في حل المسائل، يُنصح بالتركيز على مراجعة القوانين قبل الامتحان الشهري.',
        createdAt: now.subtract(const Duration(days: 2))),
    StudentNote(id: 'nt2', studentId: 's1', authorId: 'mgr1', schoolId: 'sch1', kind: NoteKind.behavioral,
        text: 'التزام ممتاز بالانضباط المدرسي خلال هذا الشهر.', createdAt: now.subtract(const Duration(days: 9))),
  ]);

  // ───────────── Parents ─────────────
  store.linkRequests.addAll([
    ParentLinkRequest(id: 'lr1', parentId: 'p1', studentId: 's1', schoolId: 'sch1', approverId: 'mgr1',
        approverRole: UserRole.manager, idDocumentName: 'national_id_front.jpg', ocrExtractedName: 'علي عبد الله محمود',
        ocrMatch: true, status: LinkStatus.approved, createdAt: now.subtract(const Duration(days: 200))),
    ParentLinkRequest(id: 'lr2', parentId: 'p1', studentId: 's7', schoolId: 'sch2', approverId: 'i2',
        approverRole: UserRole.instructor, idDocumentName: 'national_id_front.jpg', ocrExtractedName: 'علي عبد الله محمود',
        ocrMatch: true, status: LinkStatus.approved, createdAt: now.subtract(const Duration(days: 190))),
    ParentLinkRequest(id: 'lr3', parentId: 'p2', studentId: 's2', schoolId: 'sch1', approverId: 't1',
        approverRole: UserRole.teacher, idDocumentName: 'unified_id.jpg', ocrExtractedName: 'حسن كريم مهدي',
        ocrMatch: true, createdAt: now.subtract(const Duration(hours: 6))),
  ]);
  store.leaveRequests.addAll([
    LeaveRequest(id: 'lv1', parentId: 'p1', studentId: 's1', schoolId: 'sch1', date: d(-10), reason: 'مراجعة طبية',
        recipientIds: ['mgr1', 't1', 'i1'], status: LeaveStatus.approved, approvedBy: 'mgr1',
        createdAt: now.subtract(const Duration(days: 11))),
    LeaveRequest(id: 'lv2', parentId: 'p1', studentId: 's1', schoolId: 'sch1', date: d(3), reason: 'ظرف عائلي',
        recipientIds: ['mgr1', 't1', 'i1'], createdAt: now.subtract(const Duration(hours: 3))),
  ]);
  store.meetings.addAll([
    Meeting(id: 'mt1', parentId: 'p1', staffId: 't1', studentId: 's1', schoolId: 'sch1', type: MeetingType.video,
        scheduledAt: d(2).add(const Duration(hours: 13)), topic: 'مناقشة مستوى أحمد في الرياضيات'),
    Meeting(id: 'mt2', parentId: 'p1', staffId: 'mgr1', studentId: 's1', schoolId: 'sch1', type: MeetingType.inPerson,
        scheduledAt: d(6).add(const Duration(hours: 10)), topic: 'اجتماع دوري', status: MeetingStatus.accepted),
  ]);

  // ───────────── Messaging ─────────────
  store.conversations.addAll([
    Conversation(id: 'cv1', schoolId: 'sch1', participantIds: ['s1', 't1'], updatedAt: now.subtract(const Duration(minutes: 40))),
    Conversation(id: 'cv2', schoolId: 'sch1', participantIds: ['p1', 't1'], studentContextId: 's1',
        updatedAt: now.subtract(const Duration(hours: 3))),
    Conversation(id: 'cv3', schoolId: 'sch1', participantIds: ['mgr1', 't2'], updatedAt: now.subtract(const Duration(days: 1))),
    Conversation(id: 'cv4', schoolId: 'sch1', participantIds: ['p1', 'mgr1'], studentContextId: 's1',
        updatedAt: now.subtract(const Duration(days: 2))),
  ]);
  var msg = 0;
  void chat(String cv, String from, String text, int minutesAgo, {MessageType type = MessageType.text, String? file}) =>
      store.messages.add(ChatMessage(id: 'msg${msg++}', conversationId: cv, senderId: from, type: type, text: text,
          fileName: file, sentAt: now.subtract(Duration(minutes: minutesAgo)), readBy: {from}));
  chat('cv1', 's1', 'أستاذ، هل يشمل الامتحان الشهري موضوع الغايات؟', 70);
  chat('cv1', 't1', 'نعم يا أحمد، الفصل الثاني كاملاً مع الغايات.', 55);
  chat('cv1', 't1', '', 41, type: MessageType.file, file: 'review_questions.pdf');
  chat('cv1', 's1', 'شكراً جزيلاً أستاذ 🌷', 40);
  chat('cv2', 'p1', 'السلام عليكم أستاذ علي، كيف مستوى أحمد هذا الشهر؟', 200);
  chat('cv2', 't1', 'وعليكم السلام، مستواه جيد جداً وتحسّن في الامتحان اليومي.', 180);
  chat('cv3', 'mgr1', 'يرجى رفع درجات الامتحان اليومي للصف الخامس قبل نهاية الأسبوع.', 1500);
  chat('cv3', 't2', 'تم إن شاء الله.', 1440);
  chat('cv4', 'mgr1', 'نرحب بحضوركم اجتماع أولياء الأمور يوم الخميس.', 2900);

  // ───────────── Notifications ─────────────
  void n(String user, String cat, String title, String body, int minutesAgo, {bool read = false, String? route}) =>
      store.notifications.add(AppNotification(id: store.newId('ntf'), userId: user, category: cat, title: title,
          body: body, read: read, route: route, createdAt: now.subtract(Duration(minutes: minutesAgo))));
  n('s1', 'grades', 'درجة جديدة', 'تم نشر درجتك في امتحان الرياضيات اليومي: 17 / 20', 300);
  n('s1', 'lessons', 'درس جديد', 'نشر أ. علي حسين درساً جديداً: الغايات والاستمرارية', 310);
  n('s1', 'exams', 'امتحان قادم', 'امتحان فيزياء يومي بعد يومين', 600, read: true);
  n('s1', 'announcements', 'إعلان مدرسي', 'اجتماع أولياء الأمور يوم الخميس', 1200, read: true);
  n('p1', 'attendance', 'تأخر عن الحصة', 'تأخر أحمد عن حصة الرياضيات اليوم 08:00', 90);
  n('p1', 'grades', 'درجة جديدة', 'حصل أحمد على 17 / 20 (85%) في الرياضيات', 300);
  n('p1', 'meetings', 'طلب اجتماع', 'طلب الاجتماع مع أ. علي حسين بانتظار الرد', 400, read: true);
  n('p1', 'leaves', 'طلب إجازة', 'تمت الموافقة على طلب إجازة أحمد', 15000, read: true);
  n('t1', 'requests', 'طلب ربط وليّ أمر', 'طلب حسن كريم مهدي ربط حسابه بالطالبة مريم حسن', 360);
  n('t1', 'leaves', 'طلب إجازة', 'طلب إجازة جديد للطالب أحمد علي', 180);
  n('t1', 'announcements', 'إعلان إداري', 'اجتماع الهيئة التدريسية الأربعاء', 2000, read: true);
  n('mgr1', 'requests', 'طلب انضمام مدرّس', 'طلبت أ. رنا صباح الانضمام للمدرسة', 120);
  n('mgr1', 'requests', 'طلب انضمام طالب', 'طلب كرار ماجد الانضمام إلى الخامس العلمي (أ)', 30);
  n('mgr1', 'leaves', 'طلب إجازة', 'طلب إجازة جديد للطالب أحمد علي', 180, read: true);
  n('owner', 'requests', 'طلب توثيق مدرسة', 'إعدادية الرافدين للبنين تنتظر مراجعة الوثائق', 200);
  n('owner', 'security', 'تنبيه نسخ احتياطي', 'فشل النسخ الاحتياطي التلقائي ليوم أمس — تمت إعادة المحاولة بنجاح', 900);

  // ───────────── Library ─────────────
  var lib = 0;
  void res(String title, ResourceType type, SchoolStage stage, int grade, String subj, String uploader, String file,
          {Track track = Track.none, String text = '', int pages = 60}) =>
      store.library.add(LibraryResource(
        id: 'lib${lib++}', title: title, type: type, stage: stage, grade: grade, track: track, subjectId: subj,
        yearLabel: '2026–2027', uploaderId: uploader, fileName: file, pages: pages, extractedText: text,
        description: 'مصدر تعليمي معتمد على المنهج العراقي', createdAt: now.subtract(Duration(days: lib * 3)),
      ));
  res('كتاب الرياضيات – الخامس العلمي', ResourceType.textbook, SchoolStage.preparatory, 5, 'math', 't1',
      'math_5sci_textbook.pdf', track: Track.scientific, text: 'الأعداد المركبة الغايات المشتقات التكامل', pages: 240);
  res('ملزمة الغايات والاستمرارية', ResourceType.booklet, SchoolStage.preparatory, 5, 'math', 't1', 'limits_booklet.pdf',
      track: Track.scientific, text: 'الغاية من اليمين الغاية من اليسار الاستمرارية');
  res('ملخص قوانين نيوتن', ResourceType.summary, SchoolStage.preparatory, 5, 'physics', 't2', 'newton_summary.pdf',
      track: Track.scientific, text: 'القانون الأول القصور الذاتي القانون الثاني القوة الكتلة التعجيل', pages: 12);
  res('English Grammar Essentials', ResourceType.studyMaterial, SchoolStage.preparatory, 5, 'english', 'i1',
      'grammar_essentials.pdf', track: Track.scientific, text: 'present perfect passive voice conditionals', pages: 34);
  res('أسئلة امتحانات الفيزياء – السادس', ResourceType.examResource, SchoolStage.preparatory, 6, 'physics', 't2',
      'physics_6_exam_bank.pdf', track: Track.scientific, text: 'المتسعات الحث الكهرومغناطيسي', pages: 80);
  res('كتاب العلوم – الرابع الابتدائي', ResourceType.textbook, SchoolStage.primary, 4, 'science', 'i2',
      'science_4_primary.pdf', text: 'النبات الحيوان الماء', pages: 150);
  res('ملخص قواعد اللغة العربية – الثالث المتوسط', ResourceType.summary, SchoolStage.intermediate, 3, 'arabic', 'i2',
      'arabic_grammar_3int.pdf', text: 'المبتدأ والخبر كان وأخواتها', pages: 20);

  var me = 0;
  for (final y in [2026, 2025, 2024]) {
    for (final subj in ['math', 'physics', 'chemistry', 'english']) {
      for (final round in [1, 2]) {
        store.ministerialExams.add(MinisterialExam(
          id: 'mex${me++}', stage: SchoolStage.preparatory, grade: 6, track: Track.scientific, subjectId: subj,
          year: y, round: round, fileName: '${subj}_6sci_${y}_r$round.pdf',
        ));
      }
    }
    store.ministerialExams.add(MinisterialExam(
      id: 'mex${me++}', stage: SchoolStage.intermediate, grade: 3, subjectId: 'arabic', year: y, round: 1,
      fileName: 'arabic_3int_${y}_r1.jpg', isImage: true,
    ));
  }
  store.ministerialExams.add(MinisterialExam(
    id: 'mex${me++}', stage: SchoolStage.preparatory, grade: 6, track: Track.scientific, subjectId: 'math',
    year: 2025, round: 3, fileName: 'math_6sci_2025_r3.pdf',
  ));
  store.favorites['s1'] = {'lib1', 'mex0'};

  // ───────────── Billing ─────────────
  store.plans.addAll([
    SubscriptionPlan(id: 'plan-mgr', role: UserRole.manager, priceIqd: 25000, durationDays: 30, trialDays: 7,
        effectiveFrom: DateTime(2026, 1, 1)),
    SubscriptionPlan(id: 'plan-teacher', role: UserRole.teacher, priceIqd: 15000, durationDays: 30, trialDays: 7,
        effectiveFrom: DateTime(2026, 1, 1)),
    SubscriptionPlan(id: 'plan-instructor', role: UserRole.instructor, priceIqd: 15000, durationDays: 30, trialDays: 7,
        effectiveFrom: DateTime(2026, 1, 1)),
  ]);
  Subscription sub(String id, String user, String plan, SubscriptionStatus st, int startAgo, int endsIn, int price,
          {bool auto = false}) =>
      Subscription(id: id, userId: user, planId: plan, status: st, startedAt: d(-startAgo), endsAt: d(endsIn),
          lockedPriceIqd: price, autoRenew: auto);
  store.subscriptions.addAll([
    sub('sub1', 'mgr1', 'plan-mgr', SubscriptionStatus.active, 12, 18, 25000, auto: true),
    sub('sub2', 'mgr2', 'plan-mgr', SubscriptionStatus.active, 3, 27, 25000),
    sub('sub3', 'mgr3', 'plan-mgr', SubscriptionStatus.trial, 3, 4, 0),
    sub('sub4', 't1', 'plan-teacher', SubscriptionStatus.active, 20, 10, 15000, auto: true),
    sub('sub5', 't2', 'plan-teacher', SubscriptionStatus.expired, 35, -5, 15000),
    sub('sub6', 'i1', 'plan-instructor', SubscriptionStatus.trial, 3, 4, 0),
    sub('sub7', 't3', 'plan-teacher', SubscriptionStatus.trial, 2, 5, 0),
    sub('sub8', 'i2', 'plan-instructor', SubscriptionStatus.grantedFree, 10, 80, 0),
  ]);
  store.discounts.add(Discount(id: 'dc1', code: 'SCHOOL2026', percent: 20, startsAt: d(10), endsAt: d(40)));
  store.extensions.add(ManualExtension(id: 'ext1', userId: 'i2', days: 90, reason: 'منحة لمدرسة شريكة في مرحلة الإطلاق',
      grantedBy: 'owner', isFreeGrant: true, at: now.subtract(const Duration(days: 10))));
  var pay = 0;
  final payUsers = ['mgr1', 't1', 'mgr2', 't2', 'mgr1', 't1'];
  for (var i = 0; i < 40; i++) {
    final user = payUsers[i % payUsers.length];
    final amount = user.startsWith('mgr') ? 25000 : 15000;
    store.payments.add(Payment(
      id: 'pay${pay++}', userId: user, amountIqd: amount,
      status: i % 11 == 3 ? PaymentStatus.failed : (i == 17 ? PaymentStatus.refunded : PaymentStatus.succeeded),
      cardLast4: '${4000 + i * 37}'.substring(0, 4), providerRef: 'TXN-${880000 + i * 113}',
      createdAt: now.subtract(Duration(days: i * 4, hours: i)),
    ));
  }

  // ───────────── Verification ─────────────
  store.verifications.addAll([
    VerificationRecord(id: 'vr1', kind: VerificationKind.school, status: VerificationStatus.manualReview, schoolId: 'sch3',
        userId: 'mgr3', documents: ['school_license.pdf', 'directorate_letter.pdf'],
        submittedAt: now.subtract(const Duration(days: 3))),
    VerificationRecord(id: 'vr2', kind: VerificationKind.managerPosition, status: VerificationStatus.manualReview,
        userId: 'mgr3', schoolId: 'sch3', documents: ['appointment_order.pdf'], faceMatchScore: 0.93, livenessPassed: true,
        submittedAt: now.subtract(const Duration(days: 3))),
    VerificationRecord(id: 'vr3', kind: VerificationKind.professional, status: VerificationStatus.pending, userId: 't3',
        documents: ['teaching_certificate.pdf'], faceMatchScore: 0.88, livenessPassed: true,
        submittedAt: now.subtract(const Duration(days: 2))),
    VerificationRecord(id: 'vr4', kind: VerificationKind.identity, status: VerificationStatus.verified, userId: 't1',
        faceMatchScore: 0.97, livenessPassed: true, reviewerId: 'owner', submittedAt: now.subtract(const Duration(days: 360))),
    VerificationRecord(id: 'vr5', kind: VerificationKind.identity, status: VerificationStatus.pending, userId: 's8',
        faceMatchScore: 0.91, livenessPassed: true, submittedAt: now.subtract(const Duration(hours: 20))),
  ]);

  // ───────────── Security ─────────────
  for (final user in store.users) {
    store.devices.add(DeviceSession(id: 'dev-${user.id}-1', userId: user.id, deviceName: 'Samsung Galaxy S24',
        platform: 'Android 15', lastActive: now, isCurrent: true, city: 'بغداد'));
  }
  store.devices.add(DeviceSession(id: 'dev-s1-2', userId: 's1', deviceName: 'iPad (10th gen)', platform: 'iPadOS 19',
      lastActive: now.subtract(const Duration(days: 2)), city: 'بغداد'));
  store.devices.add(DeviceSession(id: 'dev-p1-2', userId: 'p1', deviceName: 'iPhone 15', platform: 'iOS 19',
      lastActive: now.subtract(const Duration(hours: 7)), city: 'البصرة'));
  for (final user in ['s1', 'p1', 't1', 'mgr1', 'owner']) {
    store.securityEvents.addAll([
      SecurityEvent(id: store.newId('sec'), userId: user, type: SecurityEventType.login, description: 'تسجيل دخول ناجح',
          device: 'Samsung Galaxy S24', at: now.subtract(const Duration(hours: 1))),
      SecurityEvent(id: store.newId('sec'), userId: user, type: SecurityEventType.newDevice,
          description: 'تسجيل دخول من جهاز جديد', device: 'iPhone 15', at: now.subtract(const Duration(days: 4))),
      SecurityEvent(id: store.newId('sec'), userId: user, type: SecurityEventType.remoteLogout,
          description: 'تسجيل خروج عن بُعد لجهاز قديم', device: 'Xiaomi Redmi Note 12', at: now.subtract(const Duration(days: 20))),
    ]);
  }
  store.deletionRequests.add(DeletionRequest(id: 'del1', userId: 'p2', requestedAt: now.subtract(const Duration(days: 1))));
  store.recoveryRequests.add(RecoveryRequest(id: 'rec1', phone: '+9647709999999', userId: 's3',
      documentName: 'unified_id.jpg', ocrName: 'يوسف قاسم جواد', matchScore: 0.71, status: RecoveryStatus.manualReview));

  // ───────────── Support & feedback ─────────────
  store.tickets.addAll([
    SupportTicket(id: 'tk1', userId: 't1', category: TicketCategory.technical, subject: 'تعذر رفع ملف فيديو',
        body: 'عند رفع فيديو بحجم 200MB يظهر خطأ في الاتصال.', status: TicketStatus.inProgress,
        replies: [TicketReply(authorId: 'owner', text: 'نعمل على رفع الحد الأقصى، يرجى ضغط الفيديو مؤقتاً.')],
        createdAt: now.subtract(const Duration(days: 2))),
    SupportTicket(id: 'tk2', userId: 'p1', schoolId: 'sch1', category: TicketCategory.school,
        subject: 'تأخر نشر الدرجات', body: 'لم تُنشر درجات امتحان الكيمياء حتى الآن.',
        createdAt: now.subtract(const Duration(hours: 10))),
    SupportTicket(id: 'tk3', userId: 'mgr2', category: TicketCategory.subscription, subject: 'خصم مرتين من البطاقة',
        body: 'تم خصم مبلغ الاشتراك مرتين هذا الشهر.', createdAt: now.subtract(const Duration(days: 1))),
  ]);
  store.suggestions.addAll([
    Suggestion(id: 'sg1', userId: 's1', title: 'إضافة وضع القراءة الليلي للملفات',
        description: 'سيكون مفيداً عند الدراسة ليلاً.', status: SuggestionStatus.underReview,
        createdAt: now.subtract(const Duration(days: 5))),
    Suggestion(id: 'sg2', userId: 't2', title: 'تكرار جدول الحصص أسبوعياً تلقائياً',
        description: 'لتسهيل إنشاء الجدول.', createdAt: now.subtract(const Duration(days: 1))),
  ]);
  store.surveys.add(Survey(id: 'sv1', question: 'ما مدى رضاك عن سهولة استخدام التطبيق؟',
      options: ['راضٍ جداً', 'راضٍ', 'محايد', 'غير راضٍ'],
      targetRoles: {UserRole.student, UserRole.parent, UserRole.teacher, UserRole.instructor, UserRole.manager},
      startsAt: d(-3), endsAt: d(11), counts: [412, 230, 61, 18]));
  store.surveyVoters['sv1'] = {};

  // ───────────── Platform ─────────────
  for (var i = 0; i < 9; i++) {
    store.backups.add(BackupRecord(id: 'bk$i', isAutomatic: i != 2, status: i == 1 ? BackupStatus.failed : BackupStatus.success,
        sizeMb: 820 + i * 6.5, createdAt: today.subtract(Duration(days: i)).add(const Duration(hours: 3))));
  }
  store.auditLogs.addAll([
    AuditLog(id: 'aud1', actorId: 'owner', action: 'verification.approve', target: 'user:t1', at: now.subtract(const Duration(days: 300))),
    AuditLog(id: 'aud2', actorId: 'owner', action: 'subscription.grant_free', target: 'user:i2', reason: 'منحة لمدرسة شريكة',
        at: now.subtract(const Duration(days: 10))),
  ]);
  store.supportSessions.add(SupportAccessSession(id: 'sa1', ownerId: 'owner', targetUserId: 't1',
      reason: 'فحص مشكلة رفع الفيديو (تذكرة tk1)', startedAt: now.subtract(const Duration(days: 1, hours: 2)),
      endedAt: now.subtract(const Duration(days: 1, hours: 1, minutes: 40)), actions: ['فتح شاشة نشر الدروس', 'عرض سجل الرفع']));
  store.policies.addAll([
    PolicyDocument(slug: 'terms', title: const LocalizedText('شروط الاستخدام', 'Terms of Service', 'مەرجەکانی بەکارهێنان'),
        body: const LocalizedText('باستخدامك لتطبيق مدرستي فإنك توافق على استخدامه للأغراض التعليمية فقط واحترام خصوصية الآخرين…',
            'By using MADRASI you agree to use it for educational purposes only and respect others\' privacy…',
            'بە بەکارهێنانی مەدرەسەتی ڕەزامەندی دەدەیت کە تەنها بۆ مەبەستی پەروەردەیی بەکاری بهێنیت…'),
        version: 3, history: ['v1 – الإطلاق', 'v2 – تحديث بند الاشتراكات', 'v3 – بند الحذف']),
    PolicyDocument(slug: 'privacy', title: const LocalizedText('سياسة الخصوصية', 'Privacy Policy', 'سیاسەتی تایبەتمەندی'),
        body: const LocalizedText('نجمع الحد الأدنى من البيانات اللازمة لتشغيل الخدمة. تُحذف صور التحقق والملفات المؤقتة شهرياً…',
            'We collect the minimum data required to run the service. Verification images are purged monthly…',
            'کەمترین داتای پێویست کۆدەکەینەوە. وێنەکانی پشتڕاستکردنەوە مانگانە دەسڕدرێنەوە…'),
        version: 2),
    PolicyDocument(slug: 'subscription', title: const LocalizedText('سياسة الاشتراك', 'Subscription Policy', 'سیاسەتی بەشداریکردن'),
        body: const LocalizedText('حسابات الطلاب وأولياء الأمور مجانية دائماً. للمدير والمدرّس والمعلّم فترة تجريبية 7 أيام ثم اشتراك شهري…',
            'Student and parent accounts are free forever. Managers, teachers and instructors get a 7-day trial, then a monthly plan…',
            'هەژماری قوتابی و دایک و باوک هەمیشە بێبەرامبەرن…')),
    PolicyDocument(slug: 'payment', title: const LocalizedText('تعليمات الدفع', 'Payment Instructions', 'ڕێنمایی پارەدان'),
        body: const LocalizedText('يتم الدفع ببطاقة ماستركارد فقط عبر بوابة دفع آمنة. لا نحتفظ ببيانات البطاقة.',
            'Payments are accepted by Mastercard only via a secure gateway. We never store card data.',
            'پارەدان تەنها بە ماستەرکارد دەکرێت.')),
    PolicyDocument(slug: 'registration', title: const LocalizedText('تعليمات التسجيل', 'Registration Guide', 'ڕێنمایی تۆمارکردن'),
        body: const LocalizedText('سجّل برقم هاتفك العراقي واختر نوع الحساب ثم أكمل التحقق.', 'Register with your Iraqi phone number…', 'بە ژمارەی مۆبایلی عێراقی تۆمار بکە…')),
    PolicyDocument(slug: 'verification', title: const LocalizedText('تعليمات التحقق', 'Verification Guide', 'ڕێنمایی پشتڕاستکردنەوە'),
        body: const LocalizedText('مطابقة الوجه تؤكد أنك صاحب الصورة فقط ولا تُعد تحققاً حكومياً أو مهنياً. تتم مراجعة الوثائق يدوياً عند الحاجة.',
            'Face matching only confirms you are the person in the photo; it is not government or professional verification.',
            'یەکخستنی ڕووخسار تەنها دەیسەلمێنێت کە تۆ خاوەنی وێنەکەیت.')),
    PolicyDocument(slug: 'rules', title: const LocalizedText('قواعد الاستخدام', 'Usage Rules', 'یاساکانی بەکارهێنان'),
        body: const LocalizedText('يُمنع نشر محتوى غير تعليمي أو مسيء.', 'Non-educational or abusive content is prohibited.', 'بڵاوکردنەوەی ناوەڕۆکی نا پەروەردەیی قەدەغەیە.')),
    PolicyDocument(slug: 'faq', title: const LocalizedText('الأسئلة الشائعة', 'FAQ', 'پرسیارە باوەکان'),
        body: const LocalizedText('س: هل التطبيق مجاني للطلاب؟\nج: نعم، مجاني دائماً.\n\nس: كم جهازاً يمكنني استخدامه؟\nج: جهازان كحد أقصى في الوقت نفسه.',
            'Q: Is the app free for students?\nA: Yes, forever.\n\nQ: How many devices?\nA: Up to two at the same time.',
            'پ: ئەپەکە بۆ قوتابیان بێبەرامبەرە؟\nو: بەڵێ، هەمیشە.')),
  ]);
  store.versionPolicy = AppVersionPolicy(latestVersion: '1.0.0', minSupportedVersion: '1.0.0',
      notes: 'الإصدار الأول من مدرستي', adoption: {'1.0.0': 1834});
  store.health = ServerHealth(apiUp: true, responseMs: 142, cpu: 0.37, ram: 0.58, storage: 0.41, dbUp: true,
      connectedUsers: 1288, pushUp: true, rtcUp: true,
      incidents: ['انقطاع خدمة الإشعارات 6 دقائق (قبل 9 أيام)', 'بطء في قاعدة البيانات 12 دقيقة (قبل 21 يوماً)']);
}

/// Aggregated per-governorate statistics used by the owner's Iraq map.
/// In production this comes from the `governorate_stats` SQL view.
class GovernorateStat {
  const GovernorateStat(this.name, this.lat, this.lng, this.schools, this.students, this.teachers);
  final String name;
  final double lat;
  final double lng;
  final int schools;
  final int students;
  final int teachers;
}

const previewGovernorateStats = <GovernorateStat>[
  GovernorateStat('بغداد', 33.31, 44.36, 142, 48210, 3120),
  GovernorateStat('البصرة', 30.51, 47.78, 64, 20340, 1290),
  GovernorateStat('نينوى', 36.34, 43.13, 51, 17120, 1010),
  GovernorateStat('أربيل', 36.19, 44.01, 47, 15400, 980),
  GovernorateStat('السليمانية', 35.56, 45.43, 39, 12010, 820),
  GovernorateStat('دهوك', 36.87, 42.99, 22, 6800, 430),
  GovernorateStat('كركوك', 35.47, 44.39, 28, 8900, 560),
  GovernorateStat('النجف', 32.00, 44.33, 33, 10320, 690),
  GovernorateStat('كربلاء', 32.62, 44.02, 27, 8650, 540),
  GovernorateStat('بابل', 32.47, 44.42, 31, 9840, 610),
  GovernorateStat('ذي قار', 31.05, 46.26, 29, 9200, 580),
  GovernorateStat('ميسان', 31.84, 47.14, 15, 4300, 280),
  GovernorateStat('واسط', 32.51, 45.83, 17, 5100, 330),
  GovernorateStat('ديالى', 33.75, 44.61, 21, 6400, 410),
  GovernorateStat('الأنبار', 33.42, 43.30, 24, 7300, 470),
  GovernorateStat('صلاح الدين', 34.60, 43.68, 19, 5800, 360),
  GovernorateStat('القادسية', 31.99, 44.92, 18, 5600, 350),
  GovernorateStat('المثنى', 31.31, 45.28, 11, 3100, 200),
  GovernorateStat('حلبجة', 35.18, 45.98, 5, 1300, 90),
];

