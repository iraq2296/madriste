import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../data/services/service_providers.dart';

class FaceVerificationScreen extends ConsumerStatefulWidget {
  const FaceVerificationScreen({super.key, required this.user});

  final AppUser user;

  @override
  ConsumerState<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends ConsumerState<FaceVerificationScreen> {
  bool _isProcessing = false;
  int _failedAttempts = 0;
  bool _isLocked = false;
  String? _statusMessage;
  bool _isSuccess = false;

  Future<void> _startFaceMatch() async {
    if (_isLocked) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'جارٍ فحص الحيوية ومطابقة الوجه بالكاميرا…';
    });

    final faceService = ref.read(faceServiceProvider);
    final result = await faceService.verify(userId: widget.user.id);

    if (!mounted) return;

    if (result.passed) {
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
        _statusMessage = 'تمت مطابقة الوجه بنجاح!';
      });

      // Update user verification
      final store = ref.read(dataStoreProvider);
      widget.user.verification = VerificationStatus.verified;
      store.commit();

      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      ref.read(sessionProvider.notifier).signIn(widget.user);
      _navigateToDashboard();
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 3) {
        setState(() {
          _isProcessing = false;
          _isLocked = true;
          _statusMessage = 'تم قفل المحاولات مؤقتاً بعد 3 محاولات غير متطابقة. تم تحويل طلبك للمراجعة اليدوية.';
        });
        widget.user.verification = VerificationStatus.manualReview;
        ref.read(dataStoreProvider).commit();
      } else {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'لم تتطابق الصورة مع الكاميرا (محاولة $_failedAttempts من 3). يرجى المحاولة في إضاءة جيدة.';
        });
      }
    }
  }

  void _navigateToDashboard() {
    switch (widget.user.role) {
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
        title: Text(context.tr('auth.faceVerificationTitle')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Security disclaimer box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.info, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr('auth.faceDisclaimer'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.navy,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Camera preview mockup
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 260,
                        height: 320,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          border: Border.all(
                            color: _isSuccess
                                ? AppColors.success
                                : (_isLocked
                                    ? AppColors.danger
                                    : AppColors.primary),
                            width: 3,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isSuccess
                                  ? Icons.check_circle_rounded
                                  : (_isLocked
                                      ? Icons.lock_clock_rounded
                                      : Icons.face_retouching_natural_rounded),
                              size: 100,
                              color: _isSuccess
                                  ? AppColors.success
                                  : (_isLocked
                                      ? AppColors.danger
                                      : AppColors.primary.withValues(alpha: 0.8)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isSuccess
                                  ? 'اكتملت المطابقة'
                                  : context.tr('auth.cameraInstruction'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (_isProcessing)
                        Container(
                          width: 260,
                          height: 320,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (_statusMessage != null) ...[
                Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isSuccess
                        ? AppColors.success
                        : (_isLocked ? AppColors.danger : theme.colorScheme.onSurface),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (!_isLocked && !_isSuccess)
                FilledButton.icon(
                  onPressed: _isProcessing ? null : _startFaceMatch,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(context.tr('auth.verifyNow')),
                ),

              if (_isLocked)
                FilledButton.tonal(
                  onPressed: () {
                    ref.read(sessionProvider.notifier).signIn(widget.user);
                    _navigateToDashboard();
                  },
                  child: const Text('المتابعة بحساب معلق للمراجعة اليدوية'),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

