import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/config/env.dart';
import '../../core/utils/validators.dart';
import '../models/models.dart';
import '../store/data_store.dart';

/// Thrown when an external provider is required but not configured.
/// The message names the missing configuration so it is never hidden.
class ServiceNotConfiguredException implements Exception {
  ServiceNotConfiguredException(this.service, this.requirement);
  final String service;
  final String requirement;
  @override
  String toString() => '$service is not configured: $requirement';
}

class AuthException implements Exception {
  AuthException(this.code);

  /// invalid_phone | otp_invalid | otp_rate_limited | account_disabled | account_blocked
  final String code;
  @override
  String toString() => 'AuthException($code)';
}

/// Result of OTP verification.
class OtpResult {
  const OtpResult({this.user, required this.phone, this.deviceLimitReached = false});

  /// Null when the phone is not registered yet → continue to registration.
  final AppUser? user;
  final String phone;

  /// True when the account already has [DataStore.maxDevices] active devices.
  final bool deviceLimitReached;
}

/// Phone + OTP authentication (Iraqi numbers, +964).
abstract class AuthService {
  Future<void> requestOtp(String phoneE164);
  Future<OtpResult> verifyOtp(String phoneE164, String code);
  Future<void> signOut();
}

/// Production implementation backed by Supabase Auth (SMS provider such as
/// Twilio / MessageBird / Vonage configured in the Supabase dashboard).
/// Rate limiting & OTP abuse protection: Supabase Auth limits + the
/// `otp_guard` Edge Function (per-phone & per-IP throttling).
class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._store);
  final DataStore _store;
  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  @override
  Future<void> requestOtp(String phoneE164) async {
    if (!Validators.isIraqiE164(phoneE164)) throw AuthException('invalid_phone');
    try {
      await _client.auth.signInWithOtp(phone: phoneE164, shouldCreateUser: true);
    } on sb.AuthException catch (e) {
      if (e.statusCode == '429') throw AuthException('otp_rate_limited');
      rethrow;
    }
  }

  @override
  Future<OtpResult> verifyOtp(String phoneE164, String code) async {
    try {
      await _client.auth.verifyOTP(phone: phoneE164, token: code, type: sb.OtpType.sms);
    } on sb.AuthException {
      throw AuthException('otp_invalid');
    }
    // Profile + device registration is enforced server-side by the
    // `register_device` RPC, which rejects a 3rd simultaneous device.
    final profile = await _client.from('profiles').select().eq('phone', phoneE164).maybeSingle();
    if (profile == null) return OtpResult(phone: phoneE164);
    final user = _store.userByPhone(phoneE164);
    final devices = await _client.rpc('register_device', params: {'p_device_name': 'mobile'});
    return OtpResult(user: user, phone: phoneE164, deviceLimitReached: devices == 'limit_reached');
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}

/// Preview implementation: no SMS is sent. The code `123456` is accepted and
/// shown on screen so reviewers can sign in to any sample account.
class PreviewAuthService implements AuthService {
  PreviewAuthService(this._store);
  final DataStore _store;
  static const previewCode = '123456';
  final _attempts = <String, int>{};

  @override
  Future<void> requestOtp(String phoneE164) async {
    if (!Validators.isIraqiE164(phoneE164)) throw AuthException('invalid_phone');
    final n = (_attempts[phoneE164] ?? 0) + 1;
    _attempts[phoneE164] = n;
    if (n > 5) throw AuthException('otp_rate_limited');
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<OtpResult> verifyOtp(String phoneE164, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (code != previewCode) throw AuthException('otp_invalid');
    final user = _store.userByPhone(phoneE164);
    if (user != null && user.status == AccountStatus.disabled) throw AuthException('account_disabled');
    if (user != null && user.status == AccountStatus.blocked) throw AuthException('account_blocked');
    final devices = user == null ? 0 : _store.devices.where((d) => d.userId == user.id).length;
    return OtpResult(user: user, phone: phoneE164, deviceLimitReached: devices > DataStore.maxDevices);
  }

  @override
  Future<void> signOut() async {}
}

AuthService createAuthService(DataStore store) =>
    Env.isBackendConfigured ? SupabaseAuthService(store) : PreviewAuthService(store);

