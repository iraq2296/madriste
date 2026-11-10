import '../../core/config/env.dart';
import 'auth_service.dart';

// Integration interfaces for external providers.
//
// Each interface has:
//  * a production adapter that calls our backend (Edge Functions hold all
//    provider secrets — never the client), and
//  * a preview adapter used only when the backend is not configured.
// When a provider is missing, the adapter throws [ServiceNotConfiguredException]
// naming exactly what must be configured. Nothing pretends to succeed.

// ───────────────────────────── Payments (Mastercard only) ─────────────────────────────

class CheckoutSession {
  const CheckoutSession({required this.sessionId, required this.redirectUrl, required this.amountIqd});
  final String sessionId;

  /// Hosted payment page (3-D Secure) – opened in an in-app browser.
  final String redirectUrl;
  final int amountIqd;
}

/// Mastercard-only payment gateway.
///
/// PROVIDER STATUS: **pending legal/commercial verification**. Candidate
/// providers that process Mastercard in Iraq must be confirmed with the
/// business owner (e.g. Mastercard Payment Gateway Services via an Iraqi
/// acquiring bank, or a licensed Iraqi PSP). See docs/PAYMENTS.md.
abstract class PaymentGateway {
  Future<CheckoutSession> createCheckout({required String planId, String? discountCode, required bool autoRenew});
  Future<bool> confirm(String sessionId);
  Future<void> cancelAutoRenew(String subscriptionId);
}

class BackendPaymentGateway implements PaymentGateway {
  @override
  Future<CheckoutSession> createCheckout({required String planId, String? discountCode, required bool autoRenew}) =>
      throw ServiceNotConfiguredException(
        'Payment gateway',
        'Set PAYMENT_PROVIDER + PAYMENT_MERCHANT_ID + PAYMENT_API_SECRET in Edge Function secrets after a '
            'Mastercard-capable Iraqi provider is contracted (docs/PAYMENTS.md).',
      );
  @override
  Future<bool> confirm(String sessionId) => throw ServiceNotConfiguredException('Payment gateway', 'see docs/PAYMENTS.md');
  @override
  Future<void> cancelAutoRenew(String subscriptionId) async {}
}

// ───────────────────────────── Face match & liveness ─────────────────────────────

class FaceCheckResult {
  const FaceCheckResult({required this.matchScore, required this.livenessPassed});
  final double matchScore;
  final bool livenessPassed;
  bool get passed => livenessPassed && matchScore >= 0.85;
}

/// Camera-based face matching between the profile photo and a live capture.
/// Production: on-device capture + server-side comparison through the
/// `verify-face` Edge Function (provider e.g. AWS Rekognition / Azure Face /
/// FaceTec — requires FACE_PROVIDER credentials). This confirms that the
/// person is the one in the photo; it is NOT a government or professional check.
abstract class FaceVerificationService {
  Future<FaceCheckResult> verify({required String userId});
}

class BackendFaceVerificationService implements FaceVerificationService {
  @override
  Future<FaceCheckResult> verify({required String userId}) => throw ServiceNotConfiguredException(
        'Face verification',
        'Configure FACE_PROVIDER, FACE_API_KEY in Edge Function secrets (docs/VERIFICATION.md).',
      );
}

// ───────────────────────────── OCR (Unified National ID) ─────────────────────────────

class OcrResult {
  const OcrResult({required this.fullName, required this.confidence, this.documentNumberMasked});
  final String fullName;
  final double confidence;
  final String? documentNumberMasked;
}

/// OCR extracts text to *assist* reviewers. It never proves authenticity
/// or legal relationship; uncertain results are routed to manual review.
abstract class OcrService {
  Future<OcrResult> readNationalId(String fileName);
}

class BackendOcrService implements OcrService {
  @override
  Future<OcrResult> readNationalId(String fileName) => throw ServiceNotConfiguredException(
        'OCR',
        'Configure OCR_PROVIDER (e.g. Google Cloud Vision) credentials in Edge Function secrets.',
      );
}

// ───────────────────────────── Audio / video calls ─────────────────────────────

/// In-app audio/video meetings (no app-imposed duration limit).
/// Production: Agora RTC (AGORA_APP_ID public, AGORA_APP_CERTIFICATE secret
/// used by the `rtc-token` Edge Function to mint short-lived tokens).
abstract class CallService {
  Future<String> joinToken({required String meetingId, required bool video});
}

class BackendCallService implements CallService {
  @override
  Future<String> joinToken({required String meetingId, required bool video}) {
    if (Env.agoraAppId.isEmpty) {
      throw ServiceNotConfiguredException('Audio/Video calls', 'Set AGORA_APP_ID and AGORA_APP_CERTIFICATE.');
    }
    throw ServiceNotConfiguredException('Audio/Video calls', 'Deploy the rtc-token Edge Function.');
  }
}

// ───────────────────────────── Preview adapters ─────────────────────────────

class PreviewPaymentGateway implements PaymentGateway {
  @override
  Future<CheckoutSession> createCheckout({required String planId, String? discountCode, required bool autoRenew}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return CheckoutSession(sessionId: 'preview-${DateTime.now().millisecondsSinceEpoch}', redirectUrl: '', amountIqd: 0);
  }

  @override
  Future<bool> confirm(String sessionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return true;
  }

  @override
  Future<void> cancelAutoRenew(String subscriptionId) async {}
}

class PreviewFaceVerificationService implements FaceVerificationService {
  int _calls = 0;
  @override
  Future<FaceCheckResult> verify({required String userId}) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    _calls++;
    // First attempt fails to demonstrate the 3-attempt policy; then passes.
    return _calls == 1
        ? const FaceCheckResult(matchScore: 0.62, livenessPassed: true)
        : const FaceCheckResult(matchScore: 0.93, livenessPassed: true);
  }
}

class PreviewOcrService implements OcrService {
  @override
  Future<OcrResult> readNationalId(String fileName) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return const OcrResult(fullName: 'علي عبد الله محمود', confidence: 0.82, documentNumberMasked: '•••• •••• 4471');
  }
}

class PreviewCallService implements CallService {
  @override
  Future<String> joinToken({required String meetingId, required bool video}) async => 'preview-token';
}

PaymentGateway createPaymentGateway() => Env.isPreview ? PreviewPaymentGateway() : BackendPaymentGateway();
FaceVerificationService createFaceService() =>
    Env.isPreview ? PreviewFaceVerificationService() : BackendFaceVerificationService();
OcrService createOcrService() => Env.isPreview ? PreviewOcrService() : BackendOcrService();
CallService createCallService() => Env.isPreview ? PreviewCallService() : BackendCallService();

