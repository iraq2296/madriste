import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/models/platform_models.dart';
import '../../data/providers/providers.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  final _discountCtrl = TextEditingController();
  bool _autoRenew = false;
  bool _isProcessing = false;
  int _discountPercent = 0;

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  void _applyDiscount(dynamic store) {
    final code = _discountCtrl.text.trim().toUpperCase();
    final discount = store.discounts.firstWhere(
      (d) => d.code == code && d.active,
      orElse: () => null,
    );
    if (discount != null) {
      setState(() => _discountPercent = discount.percent);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تطبيق خصم ${_discountPercent}% بنجاح!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كود الخصم غير صحيح أو منتهي')),
      );
    }
  }

  void _handleMastercardPayment(AppUser user, SubscriptionPlan plan, dynamic store) async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final finalPrice = (_discountPercent > 0)
        ? (plan.priceIqd * (1 - _discountPercent / 100)).toInt()
        : plan.priceIqd;

    // Renew / create subscription
    final newSub = Subscription(
      id: store.newId('sub'),
      userId: user.id,
      planId: plan.id,
      status: SubscriptionStatus.active,
      startedAt: DateTime.now(),
      endsAt: DateTime.now().add(Duration(days: plan.durationDays)),
      lockedPriceIqd: finalPrice,
      autoRenew: _autoRenew,
    );

    store.subscriptions.add(newSub);
    store.payments.add(
      Payment(
        id: store.newId('pay'),
        userId: user.id,
        amountIqd: finalPrice,
        status: PaymentStatus.succeeded,
        cardLast4: '5412',
        providerRef: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
    store.commit();

    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم الدفع بنجاح عبر ماستركارد وتفعيل الاشتراك لمدة 30 يوماً!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final store = ref.watch(dataStoreProvider);
    final sub = store.subscriptionOf(user.id);
    final plan = store.plans.firstWhere((p) => p.role == user.role, orElse: () => store.plans.first);

    final isPaid = user.role.isPaid;
    final isUsable = sub?.isUsable ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('sub.title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isUsable
                    ? const LinearGradient(colors: [AppColors.navy, AppColors.primary])
                    : const LinearGradient(colors: [Color(0xFF8B0000), Color(0xFFE5484D)]),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        !isPaid
                            ? 'حساب مجاني دائماً'
                            : (isUsable ? 'اشتراكك نشط' : 'الاشتراك منتهٍ (للقراءة فقط)'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Icon(
                        isUsable || !isPaid ? Icons.verified_rounded : Icons.lock_clock_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    !isPaid
                        ? 'حسابات الطلبة وأولياء الأمور مجانية مدى الحياة.'
                        : (sub != null
                            ? (sub.status == SubscriptionStatus.trial
                                ? 'أنت في الفترة التجريبية المجانية (${context.tr("sub.daysRemaining", {"n": sub.daysLeft})})'
                                : 'صالح حتى ${context.formatDate(sub.endsAt)} (${context.tr("sub.daysRemaining", {"n": sub.daysLeft})})')
                            : 'لا يوجد اشتراك نشط'),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (isPaid) ...[
              // Mastercard Badge & Information
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(radius: 6, backgroundColor: Colors.red),
                          CircleAvatar(radius: 6, backgroundColor: Colors.amber),
                          SizedBox(width: 6),
                          Text('Mastercard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'الدفع حصري ببطاقة ماستركارد عبر بوابة مرخصة بالعراق وفق أعلى معايير الأمان 3D Secure.',
                        style: TextStyle(fontSize: 12, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Plan details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'باقة ${context.tr(user.role.l10nKey)}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            context.formatIqd(
                              _discountPercent > 0
                                  ? (plan.priceIqd * (1 - _discountPercent / 100)).toInt()
                                  : plan.priceIqd,
                            ),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                          ),
                          const SizedBox(width: 8),
                          if (_discountPercent > 0)
                            Text(
                              context.formatIqd(plan.priceIqd),
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                          const Text(' / شهرياً'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('• صلاحيات كاملة للنشر والجدولة وتسجيل الحضور'),
                      const Text('• حفظ البيانات وسجلات الأعوام السابقة بأمان'),
                      const Text('• دعم فني وتقني مباشر'),
                      const SizedBox(height: 14),
                      const Divider(),
                      // Auto-renewal switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.tr('sub.autoRenew')),
                        subtitle: const Text('يمكنك إلغاؤه في أي وقت من الإعدادات'),
                        value: _autoRenew,
                        onChanged: (val) => setState(() => _autoRenew = val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Discount promo code
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _discountCtrl,
                      decoration: const InputDecoration(
                        hintText: 'كود الخصم الترويجي (مثال: SCHOOL2026)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.tonal(
                    onPressed: () => _applyDiscount(store),
                    child: const Text('تطبيق'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Payment Button
              FilledButton.icon(
                onPressed: _isProcessing ? null : () => _handleMastercardPayment(user, plan, store),
                icon: const Icon(Icons.payment_rounded),
                label: _isProcessing
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(context.tr('sub.payWithMastercard')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
