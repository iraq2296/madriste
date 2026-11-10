import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers/providers.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';

/// Displayed at the top of screens when a paid account's subscription has expired.
///
/// PER SPEC:
/// When subscription expires:
/// - Read-only access remains.
/// - Editing, publishing, and administrative operations are disabled.
/// - Existing data must remain safe.
/// - Display a clear renewal message.
class ReadOnlyBanner extends ConsumerWidget {
  const ReadOnlyBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReadOnly = ref.watch(readOnlyProvider);
    if (!isReadOnly) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock, color: AppColors.danger, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('banner.readOnly'),
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () => context.push('/subscription'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 36),
            ),
            child: Text(
              context.tr('banner.renew'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
