import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/platform_models.dart';
import '../../data/providers/providers.dart';

class SecurityLogScreen extends ConsumerWidget {
  const SecurityLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(dataStoreProvider);
    final user = ref.watch(currentUserProvider);

    final events = store.securityEvents.where((e) => e.userId == user.id).toList()
      ..sort((a, b) => b.at.compareTo(a.at));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings.securityLog')),
      ),
      body: events.isEmpty
          ? const Center(child: Text('لا توجد أحداث أمنية مسجلة'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final ev = events[i];
                final icon = switch (ev.type) {
                  SecurityEventType.login => Icons.login_rounded,
                  SecurityEventType.newDevice => Icons.phonelink_setup_rounded,
                  SecurityEventType.remoteLogout => Icons.phonelink_erase_rounded,
                  SecurityEventType.phoneChanged => Icons.phone_forwarded_rounded,
                  SecurityEventType.recoveryAttempt => Icons.lock_reset_rounded,
                  _ => Icons.shield_rounded,
                };

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Icon(icon, color: AppColors.primary, size: 20),
                    ),
                    title: Text(ev.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${ev.device ?? "الجهاز"} • ${context.formatDateTime(ev.at)}'),
                  ),
                );
              },
            ),
    );
  }
}
