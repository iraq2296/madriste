import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../core/l10n/l10n.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/role_badge.dart';
import '../../data/models/models.dart';
import '../../data/models/platform_models.dart';
import '../../data/providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(appSettingsProvider);
    final store = ref.watch(dataStoreProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('nav.settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Profile preview card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AppAvatar(user: user, size: 54, showBadge: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            RoleBadge(role: user.role, compact: true),
                            const SizedBox(width: 8),
                            Text(user.phone, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ───────────── PREFERENCES (LANGUAGE & THEME) ─────────────
          _sectionTitle('التفضيلات والمظهر'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                  title: Text(context.tr('settings.language')),
                  subtitle: Text(settings.language.nativeName),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showLanguageDialog(context, ref, settings),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.palette_outlined, color: AppColors.primary),
                  title: Text(context.tr('settings.theme')),
                  subtitle: Text(
                    settings.themeMode == ThemeMode.dark
                        ? context.tr('settings.themeDark')
                        : (settings.themeMode == ThemeMode.light
                            ? context.tr('settings.themeLight')
                            : context.tr('settings.themeSystem')),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showThemeDialog(context, ref, settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ───────────── SECURITY & ACCESS ─────────────
          _sectionTitle('الأمان وإدارة الحساب'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                  title: Text(context.tr('settings.appLock')),
                  subtitle: Text(context.tr('settings.appLockDesc'), style: const TextStyle(fontSize: 12)),
                  value: settings.appLockEnabled,
                  onChanged: (val) {
                    ref.read(appSettingsProvider.notifier).setAppLock(enabled: val);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.devices_rounded, color: AppColors.primary),
                  title: Text(context.tr('settings.devices')),
                  subtitle: Text(context.tr('settings.devicesNotice'), style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/devices'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_rounded, color: AppColors.primary),
                  title: Text(context.tr('settings.securityLog')),
                  subtitle: const Text('سجل الدخول والأجهزة والأحداث الأمنية', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/security-log'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_android_rounded, color: AppColors.primary),
                  title: Text(context.tr('settings.changePhone')),
                  subtitle: const Text('يتطلب التحقق بالبطاقة الوطنية ورمز OTP', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showChangePhoneDialog(context, user, store),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ───────────── SUBSCRIPTION (FOR PAID ROLES) ─────────────
          if (user.role.isPaid) ...[
            _sectionTitle('الاشتراك والفوترة'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.credit_card_rounded, color: AppColors.primary),
                title: Text(context.tr('sub.title')),
                subtitle: const Text('إدارة باقة الاشتراك والدفع عبر ماستركارد', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/subscription'),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ───────────── SUPPORT & POLICIES ─────────────
          _sectionTitle('الدعم والسياسات'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.warning),
                  title: const Text('تقديم اقتراح للإدارة'),
                  subtitle: const Text('شاركنا أفكارك لتطوير المنصة', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showSuggestionDialog(context, user, store),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.policy_outlined, color: AppColors.primary),
                  title: const Text('شروط الاستخدام وسياسة الخصوصية'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showPoliciesDialog(context, store),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ───────────── DANGER ZONE (ACCOUNT DELETION) ─────────────
          _sectionTitle('منطقة الحساب'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                  title: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                  onTap: () {
                    ref.read(sessionProvider.notifier).signOut();
                    context.go('/login');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: AppColors.danger),
                  title: Text(
                    context.tr('settings.deleteAccount'),
                    style: const TextStyle(color: AppColors.danger),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.danger),
                  onTap: () => context.push('/settings/delete-account'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App version badge
          Center(
            child: Text(
              'مَدرَستي — إصدار ${Env.appVersion}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.navy),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('settings.language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((lang) {
            return RadioListTile<AppLanguage>(
              value: lang,
              groupValue: settings.language,
              title: Text(lang.nativeName),
              onChanged: (val) {
                if (val != null) {
                  ref.read(appSettingsProvider.notifier).setLanguage(val);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('settings.theme')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              groupValue: settings.themeMode,
              title: Text(context.tr('settings.themeSystem')),
              onChanged: (val) {
                if (val != null) {
                  ref.read(appSettingsProvider.notifier).setThemeMode(val);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: settings.themeMode,
              title: Text(context.tr('settings.themeLight')),
              onChanged: (val) {
                if (val != null) {
                  ref.read(appSettingsProvider.notifier).setThemeMode(val);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: settings.themeMode,
              title: Text(context.tr('settings.themeDark')),
              onChanged: (val) {
                if (val != null) {
                  ref.read(appSettingsProvider.notifier).setThemeMode(val);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePhoneDialog(BuildContext context, AppUser user, dynamic store) {
    final newPhoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('settings.changePhone')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'لتغيير رقم هاتفك، يلزم تأكيد رقم الهاتف الجديد برمز OTP ومطابقة الهوية بالبطاقة الوطنية الموحدة.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم الهاتف العراقي الجديد'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إرسال رمز التحقق للرقم الجديد لمطابقة الهوية')),
              );
            },
            child: Text(context.tr('common.continue')),
          ),
        ],
      ),
    );
  }

  void _showSuggestionDialog(BuildContext context, AppUser user, dynamic store) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تقديم اقتراح'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان الاقتراح')),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'تفاصيل الاقتراح')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              store.suggestions.add(
                Suggestion(
                  id: store.newId('sg'),
                  userId: user.id,
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                ),
              );
              store.commit();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('شكراً لمشاركتك! تم إرسال اقتراحك للإدارة للمراجعة')),
              );
            },
            child: Text(context.tr('common.send')),
          ),
        ],
      ),
    );
  }

  void _showPoliciesDialog(BuildContext context, dynamic store) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('السياسات والشروط المعتمدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  const Text('سياسة الخصوصية:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('نجمع الحد الأدنى من البيانات. تُحذف صور التحقق والملفات المؤقتة شهرياً وفق سياسة الاستبقاء المعتمدة.'),
                  const SizedBox(height: 16),
                  const Text('شروط الاشتراكات والمدفوعات:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('حسابات الطلبة وأولياء الأمور مجانية دائماً. اشتراكات المدرسين والمدراء عبر ماستركارد بفترة تجريبية 7 أيام.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
