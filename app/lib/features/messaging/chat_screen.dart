import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_avatar.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage({MessageType type = MessageType.text, String? fileName}) {
    final text = _textCtrl.text.trim();
    if (type == MessageType.text && text.isEmpty) return;

    final user = ref.read(currentUserProvider);
    final store = ref.read(dataStoreProvider);

    store.messages.add(
      ChatMessage(
        id: store.newId('msg'),
        conversationId: widget.conversation.id,
        senderId: user.id,
        type: type,
        text: type == MessageType.text ? text : '',
        fileName: fileName,
        readBy: {user.id},
      ),
    );
    widget.conversation.updatedAt = DateTime.now();
    store.commit();

    _textCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final store = ref.watch(dataStoreProvider);

    final otherId = widget.conversation.participantIds.firstWhere((id) => id != user.id, orElse: () => user.id);
    final otherUser = store.userById(otherId);
    final school = store.schoolById(widget.conversation.schoolId);

    final messages = store.messages.where((m) => m.conversationId == widget.conversation.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AppAvatar(user: otherUser!, size: 36, showBadge: true),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(otherUser.fullName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(
                    '${context.tr(otherUser.role.l10nKey)} • ${school?.name ?? ""}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Security disclaimer header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primary.withValues(alpha: 0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'محادثة مدرسية آمنة تابعة لـ (${school?.name ?? ""})',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),

          // Message bubbles
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final msg = messages[i];
                final isMe = msg.senderId == user.id;

                return Align(
                  alignment: isMe ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (msg.type == MessageType.file) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.attachment_rounded, color: isMe ? Colors.white : AppColors.primary, size: 20),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  msg.fileName ?? 'ملف مرفق',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isMe ? Colors.white : AppColors.navy,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            msg.text,
                            style: TextStyle(
                              color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          context.formatTime(msg.sentAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Message input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded, color: AppColors.primary),
                  tooltip: 'إرفاق ملف',
                  onPressed: () => _sendMessage(type: MessageType.file, fileName: 'homework_sheet.pdf'),
                ),
                IconButton(
                  icon: const Icon(Icons.image_outlined, color: AppColors.primary),
                  tooltip: 'إرفاق صورة',
                  onPressed: () => _sendMessage(type: MessageType.image, fileName: 'board_photo.jpg'),
                ),
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالتك هنا…',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

