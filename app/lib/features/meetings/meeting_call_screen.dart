import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_avatar.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';

class MeetingCallScreen extends ConsumerStatefulWidget {
  const MeetingCallScreen({super.key, required this.meeting});

  final Meeting meeting;

  @override
  ConsumerState<MeetingCallScreen> createState() => _MeetingCallScreenState();
}

class _MeetingCallScreenState extends ConsumerState<MeetingCallScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeaker = true;

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(dataStoreProvider);
    final user = ref.watch(currentUserProvider);

    final otherId = (user.id == widget.meeting.parentId) ? widget.meeting.staffId : widget.meeting.parentId;
    final otherUser = store.userById(otherId);

    final isVideo = widget.meeting.type == MeetingType.video;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            // Video / Call Background Area
            Center(
              child: isVideo && !_isVideoOff
                  ? Container(
                      color: const Color(0xFF1E293B),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppAvatar(user: otherUser!, size: 100, showBadge: true),
                            const SizedBox(height: 20),
                            Text(
                              otherUser.fullName,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'مكالمة فيديو مدرسية مشفرة (غير محدودة المدة مجاناً)',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppAvatar(user: otherUser!, size: 100, showBadge: true),
                        const SizedBox(height: 20),
                        Text(
                          otherUser.fullName,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'مكالمة صوتية مدرسية • ${widget.meeting.topic}',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
            ),

            // Top Info Bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_rounded, color: AppColors.success, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          isVideo ? 'مكالمة فيديو آمنة' : 'مكالمة صوتية آمنة',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Text(
                      'مجانية دون حد زمني',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Call Controls
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _callButton(
                    icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: _isMuted ? Colors.white : Colors.white24,
                    iconColor: _isMuted ? Colors.black : Colors.white,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),
                  if (isVideo)
                    _callButton(
                      icon: _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                      color: _isVideoOff ? Colors.white : Colors.white24,
                      iconColor: _isVideoOff ? Colors.black : Colors.white,
                      onTap: () => setState(() => _isVideoOff = !_isVideoOff),
                    ),
                  _callButton(
                    icon: _isSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                    color: _isSpeaker ? Colors.white : Colors.white24,
                    iconColor: _isSpeaker ? Colors.black : Colors.white,
                    onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                  ),
                  _callButton(
                    icon: Icons.call_end_rounded,
                    color: AppColors.danger,
                    iconColor: Colors.white,
                    size: 64,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _callButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    double size = 52,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: size * 0.48),
      ),
    );
  }
}
