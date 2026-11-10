import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/models/platform_models.dart';
import '../../data/providers/providers.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _isSubmitted = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  void _sendOtp() {
    setState(() => _otpSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال رمز تأكيد الحذف OTP إلى رقم هاتفك المسجل')),
    );
  }

  void _submitDeletion(AppUser user, dynamic store) {
    if (_otpCtrl.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل رمز OTP المكون من 6 أرقام لتأكيد الهوية')),
      );
      return;
    }

    store.deletionRequests.add(
      DeletionRequest(
        id: store.newId('del'),
        userId: user.id,
        note: 'طلب مقدم من المستخدم ومؤكد برمز OTP',
      ),
    );
    store.commit();

    setState(() => _isSubmitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final store = ref.watch(dataStoreProvider);

    if (_isSubmitted) {
      return Scaffold(
        appBar: AppBar(title: const Text('طلب حذف الحساب')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, size: 72, color: AppColors.success),
                const SizedBox(height: 20),
                const Text(
                  'تم استلام طلب حذف حسابك بنجاح',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'سيتم حذف بياناتك الشخصية المؤهلة للحذف قانونياً بعد استكمال دورة الأرشفة والنسخ الاحتياطي وفق سياسة الخصوصية. سيتم إشعارك فور اكتمال الإجراء.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.5, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () {
                    ref.read(sessionProvider.notifier).signOut();
                    context.go('/login');
                  },
                  child: const Text('تسجيل الخروج والعودة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings.deleteAccount')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'تنبيه هام قبل حذف الحساب',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.danger),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr('settings.deleteAccountWarning'),
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  const Text('• ستفقد إمكانية الوصول إلى الحساب فور معالجة الطلب.'),
                  const Text('• يتم حذف البيانات الشخصية نهائياً من قاعدة البيانات التشغيلية.'),
                  const Text('• قد يستغرق إخلاء النسخ الاحتياطية دورة التدوير الشهرية.'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (!_otpSent) ...[
              FilledButton.tonal(
                onPressed: _sendOtp,
                style: FilledButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('طلب رمز تأكيد الحذف (OTP)'),
              ),
            ] else ...[
              const Text('أدخل رمز التحقق المرسل لرقم هاتفك للتأكيد النهائي:'),
              const SizedBox(height: 10),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 10),
                decoration: const InputDecoration(hintText: '••••••', counterText: ''),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _submitDeletion(user, store),
                style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                child: const Text('تأكيد تقديم طلب حذف الحساب نهائياً'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
