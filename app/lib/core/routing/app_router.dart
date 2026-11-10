import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../features/auth/account_recovery_screen.dart';
import '../../features/auth/face_verification_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/register_form_screen.dart';
import '../../features/auth/register_role_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/manager/manager_dashboard.dart';
import '../../features/meetings/meeting_call_screen.dart';
import '../../features/messaging/chat_list_screen.dart';
import '../../features/messaging/chat_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/owner/owner_dashboard.dart';
import '../../features/parent/parent_dashboard.dart';
import '../../features/settings/delete_account_screen.dart';
import '../../features/settings/device_management_screen.dart';
import '../../features/settings/security_log_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/student/student_dashboard.dart';
import '../../features/subscriptions/subscription_screen.dart';
import '../../features/teacher/teacher_dashboard.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '+9647701234567';
          return OtpScreen(phoneE164: phone);
        },
      ),
      GoRoute(
        path: '/register/role',
        builder: (context, state) {
          final phone = state.extra as String?;
          return RegisterRoleScreen(phoneE164: phone);
        },
      ),
      GoRoute(
        path: '/register/form',
        builder: (context, state) {
          final map = state.extra as Map<String, dynamic>? ?? {};
          final role = map['role'] as UserRole? ?? UserRole.student;
          final phone = map['phone'] as String? ?? '+9647701234567';
          return RegisterFormScreen(role: role, phoneE164: phone);
        },
      ),
      GoRoute(
        path: '/register/face-verify',
        builder: (context, state) {
          final user = state.extra as AppUser;
          return FaceVerificationScreen(user: user);
        },
      ),
      GoRoute(
        path: '/recovery',
        builder: (context, state) => const AccountRecoveryScreen(),
      ),

      // Dashboards
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboard(),
      ),
      GoRoute(
        path: '/manager',
        builder: (context, state) => const ManagerDashboard(),
      ),
      GoRoute(
        path: '/parent',
        builder: (context, state) => const ParentDashboard(),
      ),
      GoRoute(
        path: '/owner',
        builder: (context, state) => const OwnerDashboard(),
      ),

      // Shared
      GoRoute(
        path: '/library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => const ChatListScreen(),
        routes: [
          GoRoute(
            path: 'chat',
            builder: (context, state) {
              final conv = state.extra as Conversation;
              return ChatScreen(conversation: conv);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/meeting-call',
        builder: (context, state) {
          final meeting = state.extra as Meeting;
          return MeetingCallScreen(meeting: meeting);
        },
      ),

      // Settings
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'devices',
            builder: (context, state) {
              final phone = state.extra as String?;
              return DeviceManagementScreen(phoneE164: phone);
            },
          ),
          GoRoute(
            path: 'security-log',
            builder: (context, state) => const SecurityLogScreen(),
          ),
          GoRoute(
            path: 'delete-account',
            builder: (context, state) => const DeleteAccountScreen(),
          ),
        ],
      ),
    ],
  );
});

