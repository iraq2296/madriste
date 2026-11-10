/// Input validation helpers. Each returns a translation key on failure
/// (or `null` when valid) so form fields can show localized messages:
///
/// ```dart
/// validator: (v) => context.trOrNull(Validators.phone(v)),
/// ```
class Validators {
  Validators._();

  static final _localMobile = RegExp(r'^7[0-9]{9}$');

  /// Normalizes user input (Arabic-Indic digits, spaces, leading 0 / +964)
  /// to the 10-digit local form `7XXXXXXXXX`.
  static String normalizeLocalPhone(String input) {
    var s = toLatinDigits(input).replaceAll(RegExp(r'[\s\-()]'), '');
    if (s.startsWith('+964')) s = s.substring(4);
    if (s.startsWith('00964')) s = s.substring(5);
    if (s.startsWith('964')) s = s.substring(3);
    if (s.startsWith('0')) s = s.substring(1);
    return s;
  }

  /// `+9647XXXXXXXXX`
  static String toE164(String input) => '+964${normalizeLocalPhone(input)}';

  static bool isIraqiE164(String phone) =>
      phone.startsWith('+964') && _localMobile.hasMatch(phone.substring(4));

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'common.required';
    return _localMobile.hasMatch(normalizeLocalPhone(v)) ? null : 'validation.phone';
  }

  static String? required(String? v) => (v == null || v.trim().isEmpty) ? 'common.required' : null;

  /// Iraqi full names are usually at least three parts (name, father, grandfather).
  static String? fullName(String? v) {
    if (v == null || v.trim().isEmpty) return 'common.required';
    final parts = v.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.length >= 3 ? null : 'validation.name';
  }

  static String? number(String? v, {double min = 0, double? max}) {
    if (v == null || v.trim().isEmpty) return 'common.required';
    final n = double.tryParse(toLatinDigits(v.trim()));
    if (n == null || n < min || (max != null && n > max)) return 'validation.number';
    return null;
  }

  static String? otp(String? v) {
    final s = toLatinDigits(v ?? '');
    return RegExp(r'^[0-9]{6}$').hasMatch(s) ? null : 'auth.otp.invalidFormat';
  }

  /// Converts Arabic-Indic (٠-٩) and Persian (۰-۹) digits to ASCII.
  static String toLatinDigits(String input) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final b = StringBuffer();
    for (final ch in input.split('')) {
      final a = arabic.indexOf(ch);
      final p = persian.indexOf(ch);
      b.write(a >= 0 ? '$a' : (p >= 0 ? '$p' : ch));
    }
    return b.toString();
  }
}

