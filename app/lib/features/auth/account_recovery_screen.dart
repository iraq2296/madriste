import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/models/platform_models.dart';
import '../../data/providers/providers.dart';
import '../../data/services/integrations.dart';
import '../../data/services/service_providers.dart';

class AccountRecoveryScreen extends ConsumerStatefulWidget {
  const AccountRecoveryScreen({super.key});

  @override
  ConsumerState<AccountRecoveryScreen> createState() => _AccountRecoveryScreenState();
}

class _AccountRecoveryScreenState extends ConsumerState<AccountRecoveryScreen> {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _hasDocument = false;
  bool _isScanning = false;
  OcrResult? _ocrResult;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleScanAndRecover() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasDocument) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى التقاط صورة واضحة للبطاقة الوطنية الموحدة')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _statusMessage = 'جارٍ قراءة بيانات البطاقة الوطنية بالذكاء الاصطناعي (OCR)…';
    });

    final ocrService = ref.read(ocrServiceProvider);
    final result = await ocrService.readNationalId('doc.jpg');

    if (!mounted) return;

    setState(() {
      _isScanning = false;
      _ocrResult = result;
    });

    final store = ref.read(dataStoreProvider);
    final phoneE164 = Validators.toE164(_phoneCtrl.text);
    final user = store.userByPhone(phoneE164);

    if (user != null && result.confidence >= 0.75) {
      setState(() {
        _isSuccess = true;
        _statusMessage = 'تم التحقق من تطابق الاسم المكتوب في البطاقة الوطنية مع الحساب بنجاح.';
      });
      store.recoveryRequests.add(
        RecoveryRequest(
          id: store.newId('rec'),
          phone: phoneE164,
          userId: user.id,
          documentName: 'unified_id.jpg',
          ocrName: result.fullName,
          matchScore: result.confidence,
          status: RecoveryStatus.approved,
        ),
      );
      store.commit();

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      ref.read(sessionProvider.notifier).signIn(user);
      context.go('/login');
    } else {
      setState(() {
        _statusMessage = 'لم يتم التأكد التلقائي من التطابق بنسبة كافية. تم إرسال طلبك للمراجعة اليدوية من قبل الدعم.';
      });
      store.recoveryRequests.add(
        RecoveryRequest(
          id: store.newId('rec'),
          phone: phoneE164,
          userId: user?.id,
          documentName: 'unified_id.jpg',
          ocrName: result.fullName,
          matchScore: result.confidence,
          status: RecoveryStatus.manualReview,
        ),
      );
      store.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings.accountRecovery')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Disclaimer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'تنبيه: قراءة مستند الهوية بالتعرف الضوئي (OCR) تهدف لمطابقة البيانات مع الحساب، ولا تعني التحقق الحكومي الرسمي لعدم الاتصال بقاعدة بيانات رسمية. في حال الشك يتم تحويل الطلب للمراجعة اليدوية.',
                    style: TextStyle(fontSize: 12, color: AppColors.navy, height: 1.4),
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: context.tr('auth.phoneNumber'),
                    hintText: '770 123 4567',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Text('+964', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
                    ),
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 20),

                // Upload National ID
                InkWell(
                  onTap: () => setState(() => _hasDocument = !_hasDocument),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _hasDocument ? AppColors.success.withValues(alpha: 0.1) : theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: _hasDocument ? AppColors.success : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _hasDocument ? Icons.check_circle_rounded : Icons.credit_card_rounded,
                          size: 48,
                          color: _hasDocument ? AppColors.success : AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _hasDocument ? 'تم إرفاق صورة البطاقة الوطنية' : 'التقاط صورة البطاقة الوطنية الموحدة',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تأكد من وضوح الاسم الرباعي ورقم الهوية',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (_ocrResult != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('البيانات المقروءة من المستند (OCR):', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('الاسم: ${_ocrResult!.fullName}'),
                        Text('رقم البطاقة: ${_ocrResult!.documentNumberMasked ?? '••••'}'),
                        Text('دقة القراءة: ${(_ocrResult!.confidence * 100).toInt()}%'),
                      ],
                    ),
                  ),

                if (_statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isSuccess ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),

                FilledButton(
                  onPressed: _isScanning ? null : _handleScanAndRecover,
                  child: _isScanning
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('التحقق واسترداد الحساب'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
