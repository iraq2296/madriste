import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/providers/providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final store = ref.watch(dataStoreProvider);

    final allUserNotifs = store.notifications.where((n) => n.userId == user.id).toList();
    final filtered = _selectedCategory == 'all'
        ? allUserNotifs
        : allUserNotifs.where((n) => n.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('nav.notifications')),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'تحديد الكل كمقروء',
            onPressed: () {
              for (final n in allUserNotifs) {
                n.read = true;
              }
              store.commit();
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('all', 'الكل'),
                _buildFilterChip('grades', 'الدرجات'),
                _buildFilterChip('attendance', 'الحضور'),
                _buildFilterChip('lessons', 'الدروس'),
                _buildFilterChip('exams', 'الامتحانات'),
                _buildFilterChip('requests', 'الطلبات'),
                _buildFilterChip('meetings', 'الاجتماعات'),
                _buildFilterChip('announcements', 'الإعلانات'),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    title: 'لا توجد إشعارات حالياً',
                    icon: Icons.notifications_none_rounded,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final notif = filtered[i];
                      final catIcon = switch (notif.category) {
                        'grades' => Icons.grade_rounded,
                        'attendance' => Icons.fact_check_rounded,
                        'lessons' => Icons.menu_book_rounded,
                        'exams' => Icons.event_note_rounded,
                        'meetings' => Icons.video_call_rounded,
                        'announcements' => Icons.campaign_rounded,
                        _ => Icons.notifications_rounded,
                      };

                      return Card(
                        color: notif.read ? null : AppColors.primary.withValues(alpha: 0.05),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: notif.read
                                ? Colors.grey.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.15),
                            child: Icon(catIcon, color: notif.read ? Colors.grey : AppColors.primary, size: 22),
                          ),
                          title: Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: notif.read ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(notif.body),
                              const SizedBox(height: 4),
                              Text(
                                context.relativeTime(notif.createdAt),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          onTap: () {
                            notif.read = true;
                            store.commit();
                            setState(() {});
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (_) => setState(() => _selectedCategory = category),
      ),
    );
  }
}

