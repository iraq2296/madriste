import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Flutter does not ship Material/Cupertino localizations for Kurdish (Sorani).
/// These delegates serve Arabic framework strings (dates, dialogs, pickers)
/// when the app language is Kurdish, while app text comes from our own
/// translation tables. Text direction is RTL for both languages.
class KuMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const KuMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('ar'));

  @override
  bool shouldReload(KuMaterialLocalizationsDelegate old) => false;
}

class KuCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const KuCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('ar'));

  @override
  bool shouldReload(KuCupertinoLocalizationsDelegate old) => false;
}

class KuWidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const KuWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture<WidgetsLocalizations>(const _RtlWidgetsLocalizations());

  @override
  bool shouldReload(KuWidgetsLocalizationsDelegate old) => false;
}

class _RtlWidgetsLocalizations extends DefaultWidgetsLocalizations {
  const _RtlWidgetsLocalizations();
  @override
  TextDirection get textDirection => TextDirection.rtl;
}

const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  KuMaterialLocalizationsDelegate(),
  KuCupertinoLocalizationsDelegate(),
  KuWidgetsLocalizationsDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

