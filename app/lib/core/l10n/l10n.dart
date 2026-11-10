import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings.dart';
import 'strings_registry.dart';

/// Supported UI languages.
///
/// * `ar` – Arabic (primary, RTL)
/// * `ku` – Kurdish Sorani (RTL, Arabic script)
/// * `en` – English (LTR)
enum AppLanguage {
  ar('ar', 'العربية', true),
  ku('ku', 'کوردی', true),
  en('en', 'English', false);

  const AppLanguage(this.code, this.nativeName, this.isRtl);
  final String code;
  final String nativeName;
  final bool isRtl;

  static AppLanguage fromCode(String? code) =>
      AppLanguage.values.firstWhere((l) => l.code == code, orElse: () => AppLanguage.ar);
}

/// Localized string lookup.
///
/// Strings are declared per feature as
/// `Map<String, Map<String, String>>` → `{ 'key': {'ar': .., 'en': .., 'ku': ..} }`
/// and merged in [allStrings]. Missing translations fall back to Arabic, then
/// to the key itself so missing strings are visible during QA.
class L10n {
  const L10n(this.language);
  final AppLanguage language;

  String tr(String key, [Map<String, Object?> args = const {}]) {
    final entry = allStrings[key];
    var value = entry?[language.code] ?? entry?['ar'] ?? key;
    if (args.isNotEmpty) {
      args.forEach((k, v) => value = value.replaceAll('{$k}', '${v ?? ''}'));
    }
    return value;
  }
}

final l10nProvider = Provider<L10n>((ref) {
  final lang = ref.watch(appSettingsProvider.select((s) => s.language));
  return L10n(lang);
});

/// Convenience access from any widget that is under a [ProviderScope].
extension L10nX on BuildContext {
  /// Current localizer. Depends on [Localizations], so any widget calling it
  /// rebuilds automatically when the user switches language.
  L10n get l10n => L10n(AppLanguage.fromCode(Localizations.localeOf(this).languageCode));

  /// Translate [key], replacing `{name}` placeholders from [args].
  String tr(String key, [Map<String, Object?> args = const {}]) => l10n.tr(key, args);

  AppLanguage get language => l10n.language;

  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}
