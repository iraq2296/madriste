import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNextScreen();
  }

  Future<void> _checkNextScreen() async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final session = ref.read(sessionProvider);
    final settings = ref.read(appSettingsProvider);

    if (session.isAuthenticated) {
      final role = session.user!.role;
      _navigateToRole(role);
    } else if (!settings.onboardingDone) {
      context.go('/onboarding');
    } else {
      context.go('/login');
    }
  }

  void _navigateToRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        context.go('/student');
        break;
      case UserRole.teacher:
      case UserRole.instructor:
        context.go('/teacher');
        break;
      case UserRole.manager:
        context.go('/manager');
        break;
      case UserRole.parent:
        context.go('/parent');
        break;
      case UserRole.superAdmin:
        context.go('/owner');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.navy, AppColors.primary],
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogo(
              size: 96,
              monochrome: true,
            ),
            SizedBox(height: 24),
            Text(
              'مَدرَستي',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'مدرستك أقرب، ومستقبلك أكبر',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}

