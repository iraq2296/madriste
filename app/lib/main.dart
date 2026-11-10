import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'core/config/env.dart';
import 'core/l10n/kurdish_localizations.dart';
import 'core/l10n/l10n.dart';
import 'core/routing/app_router.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared preferences for settings persistence
  final prefs = await SharedPreferences.getInstance();

  // Initialize Supabase only if configured
  if (Env.isBackendConfigured) {
    await sb.Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MadrasiApp(),
    ),
  );
}

class MadrasiApp extends ConsumerWidget {
  const MadrasiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'مَدرَستي — MADRASI',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(settings.language.code),
      darkTheme: AppTheme.dark(settings.language.code),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLanguage.values.map((l) => Locale(l.code)),
      localizationsDelegates: appLocalizationsDelegates,
    );
  }
}
