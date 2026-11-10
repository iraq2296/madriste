import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';

class RegisterRoleScreen extends StatelessWidget {
  const RegisterRoleScreen({super.key, this.phoneE164});

  final String? phoneE164;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final roles = [
      _RoleOption(
        role: UserRole.manager,
        titleKey: 'role.manager',
        desc: 'إدارة المدرسة، الهيئة التدريسية، الطلبة، الشعب، والمصادقة على الانضمام',
        icon: Icons.admin_panel_settings_rounded,
        color: AppColors.navy,
      ),
      _RoleOption(
        role: UserRole.teacher,
        titleKey: 'role.teacher',
        desc: 'نشر الدروس، رصد الدرجات، تسجيل الحضور لكل حصة، وإدارة الشعب المسندة',
        icon: Icons.school_rounded,
        color: AppColors.primary,
      ),
      _RoleOption(
        role: UserRole.instructor,
        titleKey: 'role.instructor',
        desc: 'تعليم المواد الدراسية، متابعة الحضور والدرجات، والتواصل مع الطلبة وأولياء الأمور',
        icon: Icons.co_present_rounded,
        color: const Color(0xFF0FA5B5),
      ),
      _RoleOption(
        role: UserRole.student,
        titleKey: 'role.student',
        desc: 'حساب مجاني دائماً: متابعة الدروس والدرجات والحضور والامتحانات والمكتبة العامة',
        icon: Icons.backpack_rounded,
        color: AppColors.success,
      ),
      _RoleOption(
        role: UserRole.parent,
        titleKey: 'role.parent',
        desc: 'حساب مجاني دائماً: متابعة عدة أبناء بمدارس مختلفة، طلبات الإجازة، والاجتماعات',
        icon: Icons.family_restroom_rounded,
        color: AppColors.warning,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('auth.chooseRole')),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: roles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final opt = roles[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: InkWell(
                onTap: () {
                  context.push(
                    '/register/form',
                    extra: {
                      'role': opt.role,
                      'phone': phoneE164 ?? '+9647701234567',
                    },
                  );
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: opt.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Icon(opt.icon, color: opt.color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(opt.titleKey),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              opt.desc,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleOption {
  const _RoleOption({
    required this.role,
    required this.titleKey,
    required this.desc,
    required this.icon,
    required this.color,
  });

  final UserRole role;
  final String titleKey;
  final String desc;
  final IconData icon;
  final Color color;
}
