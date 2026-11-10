import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/service_providers.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phoneE164});

  final String phoneE164;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _codeController = TextEditingController(text: Env.isPreview ? '123456' : '');
  bool _isLoading = false;
  String? _errorMessage;
  bool _deviceLimitReached = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();
    final otpError = Validators.otp(code);
    if (otpError != null) {
      setState(() => _errorMessage = context.tr(otpError));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _deviceLimitReached = false;
    });

    final auth = ref.read(authServiceProvider);
    try {
      final res = await auth.verifyOtp(widget.phoneE164, code);
      if (!mounted) return;

      if (res.deviceLimitReached) {
        setState(() {
          _deviceLimitReached = true;
          _errorMessage = context.tr('auth.deviceLimitDesc');
        });
        return;
      }

      if (res.user == null) {
        // Phone not yet registered -> go to register role selection
        context.pushReplacement('/register/role', extra: widget.phoneE164);
        return;
      }

      // Successful sign in
      ref.read(sessionProvider.notifier).signIn(res.user!);
      _navigateToRole(res.user!.role);
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'otp_invalid' => 'رمز التحقق غير صحيح. تأكد من الرمز وحاول ثانية.',
          'account_disabled' => 'تم تعطيل هذا الحساب مؤقتاً من قبل الإدارة.',
          'account_blocked' => 'تم حظر هذا الحساب بشكل دائم لمخالفة التعليمات.',
          _ => context.tr('common.error'),
        };
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToRole(UserRole role) {
    switch (role) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('auth.otpTitle')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('auth.otpSubtitle', {'phone': widget.phoneE164}),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              if (Env.isPreview)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr('auth.previewCodeHint'),
                          style: const TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

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

              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 14,
                  color: AppColors.navy,
                ),
                decoration: const InputDecoration(
                  hintText: '••••••',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: _isLoading ? null : _handleVerify,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                      )
                    : Text(context.tr('auth.verify')),
              ),

              if (_deviceLimitReached) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push('/settings/devices', extra: widget.phoneE164),
                  icon: const Icon(Icons.devices_rounded),
                  label: Text(context.tr('settings.devices')),
                ),
              ],

              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    ref.read(authServiceProvider).requestOtp(widget.phoneE164);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('common.sent'))),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(context.tr('auth.resendCode')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
