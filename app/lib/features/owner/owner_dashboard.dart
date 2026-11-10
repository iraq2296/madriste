import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/role_badge.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/verified_badge.dart';
import '../../data/models/models.dart';
import '../../data/models/platform_models.dart';
import '../../data/providers/providers.dart';
import '../../data/store/preview_seed.dart';

class OwnerDashboard extends ConsumerStatefulWidget {
  const OwnerDashboard({super.key});

  @override
  ConsumerState<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends ConsumerState<OwnerDashboard> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final store = ref.watch(dataStoreProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Super Admin Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: Color(0xFF8E5CF6), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('dash.ownerTitle'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'الإدارة المركزية لمنصة مدرستي • العراق',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    tooltip: 'إعدادات الحساب',
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _currentNavIndex,
                children: [
                  _buildFinancialTab(context, store),
                  _buildSchoolsTab(context, store),
                  _buildAccountsTab(context, store, user),
                  _buildMapTab(context, store),
                  _buildSystemOpsTab(context, store),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (i) => setState(() => _currentNavIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.monetization_on_outlined),
            selectedIcon: Icon(Icons.monetization_on_rounded),
            label: 'المالية',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance_rounded),
            label: 'المدارس',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts_rounded),
            label: 'المستخدمين',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'خريطة العراق',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_system_daydream_rounded),
            selectedIcon: Icon(Icons.settings_suggest_rounded),
            label: 'النظام والنسخ',
          ),
        ],
      ),
    );
  }

  // ───────────── FINANCIAL & SUBSCRIPTIONS DASHBOARD ─────────────
  Widget _buildFinancialTab(BuildContext context, dynamic store) {
    final activeSubs = store.subscriptions.where((s) => s.isUsable).length;
    final expiredSubs = store.subscriptions.where((s) => !s.isUsable).length;

    int dailyRev = 185000;
    int monthlyRev = 4920000;
    int annualRev = 54800000;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.credit_card_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('owner.mastercardOnly'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navy),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Revenue Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: context.tr('owner.dailyRev'),
                  value: context.formatIqd(dailyRev),
                  icon: Icons.today_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: context.tr('owner.monthlyRev'),
                  value: context.formatIqd(monthlyRev),
                  icon: Icons.calendar_month_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StatCard(
            title: context.tr('owner.annualRev'),
            value: context.formatIqd(annualRev),
            subtitle: 'إجمالي اشتراكات المدراء والمدرسين السنوية',
            icon: Icons.trending_up_rounded,
            color: const Color(0xFF8E5CF6),
          ),
          const SizedBox(height: 20),

          // Subscription statistics
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'الاشتراكات النشطة',
                  value: '$activeSubs',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'الاشتراكات المنتهية',
                  value: '$expiredSubs',
                  icon: Icons.history_toggle_off_rounded,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pricing Plans Manager
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إدارة باقات الاشتراك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                onPressed: () => _showAddDiscountDialog(context, store),
                icon: const Icon(Icons.discount_rounded, size: 16),
                label: const Text('كوبون خصم'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...store.plans.map((p) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: const Icon(Icons.price_check_rounded, color: AppColors.primary),
                ),
                title: Text(
                  'اشتراك ${context.tr(p.role.l10nKey)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('تجربة ${p.trialDays} أيام مجاناً ثم ${context.formatIqd(p.priceIqd)} / شهر'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'تعديل السعر',
                  onPressed: () => _showEditPlanPriceDialog(context, p, store),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ───────────── SCHOOLS MANAGEMENT ─────────────
  Widget _buildSchoolsTab(BuildContext context, dynamic store) {
    final schools = store.schools;

    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة المدارس (${schools.length})'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: schools.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final s = schools[i];
          final isSuspended = s.status == SchoolStatus.suspended;
          final teachersCount = store.membersOfSchool(s.id, {UserRole.teacher, UserRole.instructor}).length;
          final studentsCount = store.membersOfSchool(s.id, {UserRole.student}).length;

          return Card(
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: (isSuspended ? AppColors.danger : AppColors.primary).withValues(alpha: 0.12),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: isSuspended ? AppColors.danger : AppColors.primary,
                ),
              ),
              title: Row(
                children: [
                  Flexible(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                  if (s.verified) ...[
                    const SizedBox(width: 6),
                    const VerifiedBadge(size: 16),
                  ],
                ],
              ),
              subtitle: Text('${s.governorate} – ${s.district} • $teachersCount مدرس • $studentsCount طالب'),
              trailing: Chip(
                label: Text(
                  isSuspended ? 'معلقة' : 'نشطة',
                  style: TextStyle(
                    color: isSuspended ? AppColors.danger : AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                backgroundColor: (isSuspended ? AppColors.danger : AppColors.success).withValues(alpha: 0.1),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (s.suspensionReason != null) ...[
                        Text('سبب التعليق: ${s.suspensionReason}', style: const TextStyle(color: AppColors.danger)),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _toggleSchoolVerification(s, store),
                            icon: Icon(s.verified ? Icons.remove_circle_outline : Icons.verified_rounded, size: 16),
                            label: Text(s.verified ? 'سحب التوثيق' : 'منح التوثيق الأزرق'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: () => _toggleSchoolSuspension(context, s, store),
                            style: FilledButton.styleFrom(
                              foregroundColor: isSuspended ? AppColors.success : AppColors.danger,
                            ),
                            child: Text(isSuspended ? 'تنشيط المدرسة' : 'تعليق المدرسة'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ───────────── ACCOUNTS MANAGEMENT & SUPPORT ACCESS ─────────────
  Widget _buildAccountsTab(BuildContext context, dynamic store, AppUser owner) {
    final users = store.users;

    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة الحسابات (${users.length})'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final u = users[i];
          final isBlocked = u.status == AccountStatus.blocked;
          final isDisabled = u.status == AccountStatus.disabled;

          return Card(
            child: ListTile(
              leading: AppAvatar(user: u, size: 44, showBadge: true),
              title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${context.tr(u.role.l10nKey)} • ${u.phone}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (u.role != UserRole.superAdmin) ...[
                    // Support access button (troubleshoot without password)
                    IconButton(
                      icon: const Icon(Icons.login_rounded, color: AppColors.primary),
                      tooltip: 'الدخول للمعاينة الفنية (Support Access)',
                      onPressed: () => _startSupportAccess(context, owner, u, store),
                    ),
                    IconButton(
                      icon: Icon(
                        isBlocked ? Icons.lock_rounded : Icons.block_rounded,
                        color: isBlocked ? AppColors.danger : Colors.grey,
                      ),
                      tooltip: isBlocked ? 'إلغاء الحظر' : 'تعطيل / حظر الحساب',
                      onPressed: () => _toggleAccountStatus(context, u, store),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────── IRAQ SCHOOL MAP BY GOVERNORATE ─────────────
  Widget _buildMapTab(BuildContext context, dynamic store) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خريطة توزيع المدارس في محافظات العراق'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: previewGovernorateStats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final stat = previewGovernorateStats[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text('${stat.schools}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
              title: Text(stat.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              subtitle: Text(
                '${stat.students} طالباً • ${stat.teachers} مدرساً',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          );
        },
      ),
    );
  }

  // ───────────── SYSTEM OPS, BACKUPS, MAINTENANCE ─────────────
  Widget _buildSystemOpsTab(BuildContext context, dynamic store) {
    final health = store.health;
    final backups = store.backups;

    return Scaffold(
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي والنظام'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Server Health
          Card(
            color: AppColors.navy,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.dns_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'حالة الخوادم والاتصال',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('زمن الاستجابة: ${health?.responseMs ?? 140}ms', style: const TextStyle(color: Colors.white70)),
                  Text('المستخدمون المتصلون: ${health?.connectedUsers ?? 1200}', style: const TextStyle(color: Colors.white70)),
                  Text('خدمة الإشعارات: ${health?.pushUp == true ? "تعمل بكفاءة" : "متوقفة"}', style: const TextStyle(color: Colors.white70)),
                  Text('خدمة الاتصال الصوتي/المرئي: ${health?.rtcUp == true ? "تعمل بكفاءة" : "متوقفة"}', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Maintenance Mode Switch
          SwitchListTile(
            title: Text(context.tr('owner.maintenanceMode'), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('إغلاق التطبيق للصيانة مع إتاحة الدخول للمالك فقط'),
            value: store.maintenance.enabled,
            onChanged: (val) {
              store.maintenance.enabled = val;
              store.commit();
              setState(() {});
            },
          ),
          const Divider(),

          // Mandatory Update Switch
          SwitchListTile(
            title: Text(context.tr('owner.mandatoryUpdate'), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('إلزام جميع المستخدمين بالتحديث لأحدث إصدار من المتجر'),
            value: store.versionPolicy.mandatory,
            onChanged: (val) {
              store.versionPolicy.mandatory = val;
              store.commit();
              setState(() {});
            },
          ),
          const Divider(),

          // Backups
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('النسخ الاحتياطي التلقائي (AES-256)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              FilledButton.tonal(
                onPressed: () {
                  store.backups.insert(
                    0,
                    BackupRecord(
                      id: store.newId('bk'),
                      isAutomatic: false,
                      status: BackupStatus.success,
                      sizeMb: 840,
                    ),
                  );
                  store.commit();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إنشاء نسخة احتياطية مشفرة وتخزينها في مستودع مستقل')),
                  );
                },
                child: const Text('أخذ نسخة الآن'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...backups.map((bk) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  bk.status == BackupStatus.success ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: bk.status == BackupStatus.success ? AppColors.success : AppColors.danger,
                ),
                title: Text('نسخة ${bk.isAutomatic ? "تلقائية يومية" : "يدوية"} (${bk.sizeMb.toStringAsFixed(1)} MB)'),
                subtitle: Text('${context.formatDateTime(bk.createdAt)} • ${bk.storage}'),
                trailing: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم التحقق من سلامة ملفات النسخة الاحتياطية المشفرة')),
                    );
                  },
                  child: const Text('استعادة'),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _startSupportAccess(BuildContext context, AppUser owner, AppUser target, dynamic store) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('owner.supportAccess')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('owner.supportAccessNotice'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'سبب الدخول للمعاينة (مطلوب للتوثيق)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              final sessionId = store.newId('sa');
              store.supportSessions.add(
                SupportAccessSession(
                  id: sessionId,
                  ownerId: owner.id,
                  targetUserId: target.id,
                  reason: reasonCtrl.text.trim(),
                ),
              );
              store.audit(owner.id, 'support_access.start', 'user:${target.id}', reason: reasonCtrl.text.trim());
              store.commit();

              ref.read(sessionProvider.notifier).startSupportAccess(
                    owner: owner,
                    target: target,
                    sessionId: sessionId,
                  );

              Navigator.pop(context);

              // Route to target user's dashboard
              switch (target.role) {
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
                default:
                  break;
              }
            },
            child: const Text('بدء المعاينة'),
          ),
        ],
      ),
    );
  }

  void _toggleSchoolSuspension(BuildContext context, School s, dynamic store) {
    final isSuspended = s.status == SchoolStatus.suspended;
    if (isSuspended) {
      s.status = SchoolStatus.active;
      s.suspensionReason = null;
      store.commit();
      setState(() {});
    } else {
      final reasonCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('تعليق ${s.name}'),
          content: TextField(
            controller: reasonCtrl,
            decoration: const InputDecoration(labelText: 'سبب التعليق وتنبيه المدير'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
            FilledButton(
              onPressed: () {
                s.status = SchoolStatus.suspended;
                s.suspensionReason = reasonCtrl.text.trim();
                store.commit();
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('تأكيد التعليق'),
            ),
          ],
        ),
      );
    }
  }

  void _toggleSchoolVerification(School s, dynamic store) {
    s.verified = !s.verified;
    store.commit();
    setState(() {});
  }

  void _toggleAccountStatus(BuildContext context, AppUser u, dynamic store) {
    if (u.status == AccountStatus.blocked) {
      u.status = AccountStatus.active;
      store.commit();
      setState(() {});
    } else {
      u.status = AccountStatus.blocked;
      store.commit();
      setState(() {});
    }
  }

  void _showEditPlanPriceDialog(BuildContext context, SubscriptionPlan p, dynamic store) {
    final priceCtrl = TextEditingController(text: '${p.priceIqd}');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('تعديل سعر اشتراك ${context.tr(p.role.l10nKey)}'),
        content: TextField(
          controller: priceCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'السعر بالدينار العراقي (IQD)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              p.priceIqd = int.tryParse(priceCtrl.text.trim()) ?? p.priceIqd;
              store.commit();
              Navigator.pop(context);
              setState(() {});
            },
            child: Text(context.tr('common.save')),
          ),
        ],
      ),
    );
  }

  void _showAddDiscountDialog(BuildContext context, dynamic store) {
    final codeCtrl = TextEditingController(text: 'RAMADAN26');
    final pctCtrl = TextEditingController(text: '25');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إنشاء كود خصم ترويجي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'رمز الكود')),
            const SizedBox(height: 10),
            TextField(controller: pctCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'نسبة الخصم %')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              store.discounts.add(
                Discount(
                  id: store.newId('dc'),
                  code: codeCtrl.text.trim().toUpperCase(),
                  percent: int.tryParse(pctCtrl.text.trim()) ?? 20,
                  startsAt: DateTime.now(),
                  endsAt: DateTime.now().add(const Duration(days: 30)),
                ),
              );
              store.commit();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إنشاء كود الخصم بنجاح')),
              );
            },
            child: Text(context.tr('common.confirm')),
          ),
        ],
      ),
    );
  }
}
