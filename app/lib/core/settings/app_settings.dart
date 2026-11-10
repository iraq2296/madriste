import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

/// Overridden in `main()` with the loaded [SharedPreferences] instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

@immutable
class AppSettings {
  const AppSettings({
    required this.language,
    required this.themeMode,
    required this.onboardingDone,
    required this.appLockEnabled,
    required this.appLockMethod,
    required this.notificationPrefs,
  });

  final AppLanguage language;
  final ThemeMode themeMode;
  final bool onboardingDone;
  final bool appLockEnabled;

  /// `pin`, `fingerprint` or `face`.
  final String appLockMethod;

  /// Notification category → enabled.
  final Map<String, bool> notificationPrefs;

  Locale get locale => Locale(language.code);

  AppSettings copyWith({
    AppLanguage? language,
    ThemeMode? themeMode,
    bool? onboardingDone,
    bool? appLockEnabled,
    String? appLockMethod,
    Map<String, bool>? notificationPrefs,
  }) =>
      AppSettings(
        language: language ?? this.language,
        themeMode: themeMode ?? this.themeMode,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        appLockEnabled: appLockEnabled ?? this.appLockEnabled,
        appLockMethod: appLockMethod ?? this.appLockMethod,
        notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      );
}

/// Notification categories the user can toggle individually.
const notificationCategories = <String>[
  'grades',
  'lessons',
  'exams',
  'attendance',
  'announcements',
  'messages',
  'requests',
  'meetings',
  'leaves',
  'security',
];

/// Persists user preferences (language, theme, app lock, notification prefs).
class AppSettingsController extends StateNotifier<AppSettings> {
  AppSettingsController(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static AppSettings _load(SharedPreferences p) {
    final prefs = <String, bool>{
      for (final c in notificationCategories) c: p.getBool('notif.$c') ?? true,
    };
    return AppSettings(
      language: AppLanguage.fromCode(p.getString('language')),
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == p.getString('themeMode'),
        orElse: () => ThemeMode.system,
      ),
      onboardingDone: p.getBool('onboardingDone') ?? false,
      appLockEnabled: p.getBool('appLock.enabled') ?? false,
      appLockMethod: p.getString('appLock.method') ?? 'pin',
      notificationPrefs: prefs,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    await _prefs.setString('language', language.code);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString('themeMode', mode.name);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingDone: true);
    await _prefs.setBool('onboardingDone', true);
  }

  /// Enables the optional app lock. The PIN itself is stored by the secure
  /// storage layer (Keychain/Keystore) in production — never in prefs.
  Future<void> setAppLock({required bool enabled, String? method}) async {
    state = state.copyWith(appLockEnabled: enabled, appLockMethod: method);
    await _prefs.setBool('appLock.enabled', enabled);
    if (method != null) await _prefs.setString('appLock.method', method);
  }

  Future<void> setNotificationPref(String category, bool enabled) async {
    state = state.copyWith(notificationPrefs: {...state.notificationPrefs, category: enabled});
    await _prefs.setBool('notif.$category', enabled);
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsController, AppSettings>(
  (ref) => AppSettingsController(ref.watch(sharedPreferencesProvider)),
);

