import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';

class RegisterFormScreen extends ConsumerStatefulWidget {
  const RegisterFormScreen({
    super.key,
    required this.role,
    required this.phoneE164,
  });

  final UserRole role;
  final String phoneE164;

  @override
  ConsumerState<RegisterFormScreen> createState() => _RegisterFormScreenState();
}

class _RegisterFormScreenState extends ConsumerState<RegisterFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameCtrl = TextEditingController();
  final _schoolNameCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();

  String _selectedGov = 'بغداد';
  String? _selectedSchoolId;
  SchoolStage _selectedStage = SchoolStage.preparatory;
  int _selectedGrade = 5;
  String _selectedSection = 'A';
  String? _selectedSubjectId;

  bool _hasPhoto = false;
  bool _hasManagerProofDoc = false;
  bool _hasNationalId = false;

  final _govs = const [
    'بغداد', 'البصرة', 'نينوى', 'أربيل', 'السليمانية', 'دهوك',
    'كركوك', 'النجف', 'كربلاء', 'بابل', 'ذي قار', 'ميسان',
    'واسط', 'ديالى', 'الأنبار', 'صلاح الدين', 'القادسية', 'المثنى', 'حلبجة',
  ];

  @override
  void initState() {
    super.initState();
    final store = ref.read(dataStoreProvider);
    if (store.schools.isNotEmpty) {
      _selectedSchoolId = store.schools.first.id;
    }
    if (store.subjects.isNotEmpty) {
      _selectedSubjectId = store.subjects.first.id;
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _schoolNameCtrl.dispose();
    _districtCtrl.dispose();
    _specializationCtrl.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (widget.role.requiresFaceVerification && !_hasPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى التقاط أو رفع صورتك الشخصية الحقيقية للمتابعة')),
      );
      return;
    }

    if (widget.role == UserRole.manager && !_hasManagerProofDoc) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إرفاق وثيقة إثبات إدارة المدرسة الرسمية')),
      );
      return;
    }

    if (widget.role == UserRole.parent && !_hasNationalId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إرفاق صورة البطاقة الوطنية الموحدة')),
      );
      return;
    }

    final store = ref.read(dataStoreProvider);
    final userId = store.newId('u');

    // Create user in DataStore
    final newUser = AppUser(
      id: userId,
      fullName: _fullNameCtrl.text.trim(),
      phone: widget.phoneE164,
      role: widget.role,
      governorate: _selectedGov,
      specialization: _specializationCtrl.text.trim().isNotEmpty ? _specializationCtrl.text.trim() : null,
      subjectIds: _selectedSubjectId != null ? [_selectedSubjectId!] : [],
      teacherCode: widget.role.isTeaching ? 'TCH-${store.newId('').substring(0, 4)}' : null,
      verification: widget.role.requiresFaceVerification ? VerificationStatus.pending : VerificationStatus.verified,
    );

    store.users.add(newUser);

    // If manager, create new school
    if (widget.role == UserRole.manager) {
      final newSchool = School(
        id: store.newId('sch'),
        name: _schoolNameCtrl.text.trim(),
        governorate: _selectedGov,
        district: _districtCtrl.text.trim().isNotEmpty ? _districtCtrl.text.trim() : 'المركز',
        stages: {SchoolStage.primary, SchoolStage.intermediate, SchoolStage.preparatory},
        managerId: userId,
        phone: widget.phoneE164,
        verified: false,
      );
      store.schools.add(newSchool);
      store.memberships.add(
        Membership(
          id: store.newId('ms'),
          userId: userId,
          schoolId: newSchool.id,
          role: UserRole.manager,
          status: MembershipStatus.approved,
        ),
      );
    } else if (widget.role == UserRole.student && _selectedSchoolId != null) {
      // Student enrolled in chosen school
      final classGroup = store.classGroups.firstWhere(
        (c) => c.schoolId == _selectedSchoolId && c.grade == _selectedGrade,
        orElse: () => store.classGroups.first,
      );
      store.memberships.add(
        Membership(
          id: store.newId('ms'),
          userId: userId,
          schoolId: _selectedSchoolId!,
          role: UserRole.student,
          status: MembershipStatus.pending, // Pending manager approval
          classGroupIds: [classGroup.id],
        ),
      );
    } else if (widget.role.isTeaching && _selectedSchoolId != null) {
      store.memberships.add(
        Membership(
          id: store.newId('ms'),
          userId: userId,
          schoolId: _selectedSchoolId!,
          role: widget.role,
          status: MembershipStatus.pending, // Requires manager approval
          subjectIds: _selectedSubjectId != null ? [_selectedSubjectId!] : [],
        ),
      );
    }

    store.commit();

    // If role requires live camera face verification, push face verification
    if (widget.role.requiresFaceVerification) {
      context.pushReplacement('/register/face-verify', extra: newUser);
    } else {
      ref.read(sessionProvider.notifier).signIn(newUser);
      context.go('/parent');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = ref.watch(dataStoreProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${context.tr('auth.registerTitle')} — ${context.tr(widget.role.l10nKey)}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full name
                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('auth.fullName'),
                    hintText: 'مثال: أحمد علي عبد الله',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: Validators.fullName,
                ),
                const SizedBox(height: 16),

                // Phone read-only indicator
                TextFormField(
                  initialValue: widget.phoneE164,
                  enabled: false,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: context.tr('auth.phoneNumber'),
                    prefixIcon: const Icon(Icons.phone_android_rounded),
                  ),
                ),
                const SizedBox(height: 16),

                // Governorate
                DropdownButtonFormField<String>(
                  value: _selectedGov,
                  decoration: InputDecoration(
                    labelText: context.tr('auth.governorate'),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  items: _govs.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _selectedGov = v ?? _selectedGov),
                ),
                const SizedBox(height: 16),

                // Role-specific fields
                if (widget.role == UserRole.manager) ...[
                  TextFormField(
                    controller: _schoolNameCtrl,
                    decoration: InputDecoration(
                      labelText: context.tr('auth.schoolName'),
                      hintText: 'مثال: ثانوية الأمل للبنين',
                      prefixIcon: const Icon(Icons.account_balance_outlined),
                    ),
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _districtCtrl,
                    decoration: InputDecoration(
                      labelText: context.tr('auth.district'),
                      hintText: 'مثال: الكرخ – المنصور',
                      prefixIcon: const Icon(Icons.map_outlined),
                    ),
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 16),
                  _buildUploadTile(
                    title: context.tr('auth.managerProof'),
                    subtitle: 'وثيقة رسمية أو أمر إداري يثبت منصبك كمدير للمدرسة',
                    icon: Icons.verified_user_outlined,
                    isUploaded: _hasManagerProofDoc,
                    onTap: () => setState(() => _hasManagerProofDoc = !_hasManagerProofDoc),
                  ),
                  const SizedBox(height: 16),
                ],

                if (widget.role.isTeaching) ...[
                  TextFormField(
                    controller: _specializationCtrl,
                    decoration: InputDecoration(
                      labelText: context.tr('auth.specialization'),
                      hintText: 'مثال: بكالوريوس رياضيات',
                      prefixIcon: const Icon(Icons.psychology_outlined),
                    ),
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    decoration: InputDecoration(
                      labelText: context.tr('auth.subjectTaught'),
                      prefixIcon: const Icon(Icons.book_outlined),
                    ),
                    items: store.subjects
                        .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name.of(context.language))))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSubjectId = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSchoolId,
                    decoration: const InputDecoration(
                      labelText: 'المدرسة التي تطلب الانضمام إليها',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    items: store.schools
                        .map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.governorate})')))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSchoolId = v),
                  ),
                  const SizedBox(height: 16),
                ],

                if (widget.role == UserRole.student) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedSchoolId,
                    decoration: InputDecoration(
                      labelText: context.tr('school.label'),
                      prefixIcon: const Icon(Icons.school_outlined),
                    ),
                    items: store.schools
                        .map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.governorate})')))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSchoolId = v),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<SchoolStage>(
                          value: _selectedStage,
                          decoration: const InputDecoration(labelText: 'المرحلة'),
                          items: SchoolStage.values
                              .map((st) => DropdownMenuItem(value: st, child: Text(context.tr(st.l10nKey))))
                              .toList(),
                          onChanged: (v) => setState(() {
                            _selectedStage = v ?? _selectedStage;
                            _selectedGrade = _selectedStage.firstGrade;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedGrade,
                          decoration: InputDecoration(labelText: context.tr('grade.label')),
                          items: _selectedStage.grades
                              .map((g) => DropdownMenuItem(value: g, child: Text('الصف $g')))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedGrade = v ?? _selectedGrade),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSection,
                          decoration: InputDecoration(labelText: context.tr('section.label')),
                          items: ['A', 'B', 'C']
                              .map((s) => DropdownMenuItem(value: s, child: Text('شعبة $s')))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedSection = v ?? _selectedSection),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                if (widget.role == UserRole.parent) ...[
                  _buildUploadTile(
                    title: context.tr('auth.nationalIdUpload'),
                    subtitle: 'صورة البطاقة الوطنية الموحدة لتأكيد صلة القرابة برمجياً',
                    icon: Icons.badge_outlined,
                    isUploaded: _hasNationalId,
                    onTap: () => setState(() => _hasNationalId = !_hasNationalId),
                  ),
                  const SizedBox(height: 16),
                ],

                // Personal photo for required roles
                if (widget.role.requiresFaceVerification) ...[
                  _buildUploadTile(
                    title: context.tr('auth.photoRequired'),
                    subtitle: 'صورة واضحة للوجه بخلفية محايدة للمطابقة بالكاميرا',
                    icon: Icons.camera_alt_outlined,
                    isUploaded: _hasPhoto,
                    onTap: () => setState(() => _hasPhoto = !_hasPhoto),
                  ),
                  const SizedBox(height: 24),
                ],

                FilledButton(
                  onPressed: _handleSubmit,
                  child: Text(
                    widget.role.requiresFaceVerification
                        ? context.tr('auth.verifyNow')
                        : context.tr('common.continue'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUploaded ? AppColors.success.withValues(alpha: 0.1) : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isUploaded ? AppColors.success : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isUploaded ? Icons.check_circle_rounded : icon,
              color: isUploaded ? AppColors.success : AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Text(
              isUploaded ? 'تم الإرفاق' : 'إرفاق',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isUploaded ? AppColors.success : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
