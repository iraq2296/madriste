import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/platform_models.dart';
import '../../data/providers/providers.dart';

class DeviceManagementScreen extends ConsumerStatefulWidget {
  const DeviceManagementScreen({super.key, this.phoneE164});

  final String? phoneE164;

  @override
  ConsumerState<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends ConsumerState<DeviceManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(dataStoreProvider);
    final user = ref.watch(currentUserProvider);

    // Get devices for current user
    final devices = store.devices.where((d) => d.userId == user.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings.devices')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('settings.devicesNotice'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navy),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...devices.map((dev) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: dev.isCurrent ? AppColors.success.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                  child: Icon(
                    dev.platform.contains('iOS') || dev.platform.contains('iPad') ? Icons.apple_rounded : Icons.android_rounded,
                    color: dev.isCurrent ? AppColors.success : Colors.grey,
                  ),
                ),
                title: Row(
                  children: [
                    Text(dev.deviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (dev.isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('هذا الجهاز', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                subtitle: Text('${dev.platform} • ${dev.city ?? "العراق"} • نشط ${context.relativeTime(dev.lastActive)}'),
                trailing: !dev.isCurrent
                    ? TextButton(
                        onPressed: () {
                          store.devices.remove(dev);
                          store.securityEvent(
                            user.id,
                            SecurityEventType.remoteLogout,
                            'تم تسجيل الخروج عن بُعد من جهاز ${dev.deviceName}',
                          );
                          store.commit();
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم تسجيل الخروج من ${dev.deviceName} بنجاح')),
                          );
                        },
                        child: const Text('تسجيل خروج', style: TextStyle(color: AppColors.danger)),
                      )
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}
