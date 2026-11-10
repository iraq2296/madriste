import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_logo.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/service_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController(text: '7703333331'); // Pre-filled student for quick test
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final phoneE164 = Validators.toE164(_phoneController.text);
    final authService = ref.read(authServiceProvider);

    try {
      await authService.requestOtp(phoneE164);
      if (!mounted) return;
      context.push('/otp', extra: phoneE164);
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.code == 'otp_rate_limited'
            ? 'تم تجاوز حد طلبات الرمز. يرجى المحاولة بعد قليل.'
            : 'رقم الهاتف غير صحيح';
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _quickLogin(AppUser user) {
    ref.read(sessionProvider.notifier).signIn(user);
    switch (user.role) {
      case UserRole.student:
        context.go('/student');
        break;
      case UserRole.teacher:
      case UserRole.instructor:
        context.go('/teacher');
        break;
      case UserRole.manager:
        context.go('/manager');
        break;
      case UserRole.parent:
        context.go('/parent');
        break;
      case UserRole.superAdmin:
        context.go('/owner');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = ref.watch(dataStoreProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Center(
                child: AppLogo(
                  size: 72,
                  withWordmark: true,
                  withTagline: true,
                ),
              ),
              const SizedBox(height: 36),

              Text(
                context.tr('auth.loginTitle'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('auth.loginSubtitle'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: context.tr('auth.phoneNumber'),
                        hintText: '770 123 4567',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: Text(
                            '+964',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      ),
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isLoading ? null : _handleSendOtp,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                            )
                          : Text(context.tr('auth.sendCode')),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ليس لديك حساب بعد؟',
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => context.push('/register/role'),
                    child: Text(
                      context.tr('auth.registerTitle'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Center(
                child: TextButton.icon(
                  onPressed: () => context.push('/recovery'),
                  icon: const Icon(Icons.lock_reset_rounded, size: 18),
                  label: Text(
                    context.tr('settings.accountRecovery'),
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),

              if (Env.isPreview) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'المعاينة السريعة لجميع الأدوار',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'انقر مباشرة على أي حساب لتجربة شاشاته فوراً:',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _quickRoleChip(store.userById('s1'), 'طالب (أحمد)'),
                          _quickRoleChip(store.userById('t1'), 'مدرّس رياضيات (أ. علي)'),
                          _quickRoleChip(store.userById('i1'), 'معلّم إنكليزي (م. حيدر)'),
                          _quickRoleChip(store.userById('mgr1'), 'مدير ثانوية بغداد'),
                          _quickRoleChip(store.userById('p1'), 'وليّ أمر (طالبين بمدرستين)'),
                          _quickRoleChip(store.userById('owner'), 'مالك التطبيق (Super Admin)'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickRoleChip(AppUser? user, String label) {
    if (user == null) return const SizedBox.shrink();
    final (color, icon) = switch (user.role) {
      UserRole.manager => (AppColors.navy, Icons.admin_panel_settings_rounded),
      UserRole.teacher => (AppColors.primary, Icons.school_rounded),
      UserRole.instructor => (const Color(0xFF0FA5B5), Icons.co_present_rounded),
      UserRole.student => (AppColors.success, Icons.backpack_rounded),
      UserRole.parent => (AppColors.warning, Icons.family_restroom_rounded),
      UserRole.superAdmin => (const Color(0xFF8E5CF6), Icons.shield_rounded),
    };

    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      onPressed: () => _quickLogin(user),
      backgroundColor: Colors.white,
    );
  }
}
