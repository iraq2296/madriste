import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final store = ref.watch(dataStoreProvider);

    // Conversations where current user is a participant
    final myConversations = store.conversations.where((c) => c.participantIds.contains(user.id)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('nav.messages')),
      ),
      body: myConversations.isEmpty
          ? const EmptyState(
              title: 'لا توجد محادثات نشطة',
              message: 'المحادثات المدرسية تقتصر على المدرسة المعنية للحفاظ على الخصوصية.',
              icon: Icons.chat_bubble_outline_rounded,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: myConversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final conv = myConversations[i];
                final otherId = conv.participantIds.firstWhere((id) => id != user.id, orElse: () => user.id);
                final otherUser = store.userById(otherId);
                final school = store.schoolById(conv.schoolId);

                // Last message in this conversation
                final messages = store.messages.where((m) => m.conversationId == conv.id).toList();
                final lastMsg = messages.isNotEmpty ? messages.last : null;

                return Card(
                  child: ListTile(
                    leading: AppAvatar(user: otherUser!, size: 48, showBadge: true),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            otherUser.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastMsg != null)
                          Text(
                            context.relativeTime(lastMsg.sentAt),
                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${context.tr(otherUser.role.l10nKey)} • ${school?.name ?? ""}',
                          style: TextStyle(fontSize: 11, color: AppColors.primary.withValues(alpha: 0.8)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lastMsg != null
                              ? (lastMsg.type == MessageType.file
                                  ? '📎 ملف مرفق: ${lastMsg.fileName}'
                                  : lastMsg.text)
                              : 'بدء المحادثة',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/messages/chat', extra: conv),
                  ),
                );
              },
            ),
    );
  }
}

