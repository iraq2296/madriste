// ==============================================================================
// MADRASI — مَدرَستي
// Secure Mastercard Payment Gateway Integration Interface
// PCI-DSS Compliance: Full Card Numbers and CVV are NEVER touched or stored.
// ==============================================================================

class CheckoutSessionResult {
  const CheckoutSessionResult({
    required this.sessionUrl,
    required this.sessionToken,
    required this.cardLast4,
  });

  /// The secure hosted payment URL provided by the payment gateway
  final String sessionUrl;

  /// The gateway-minted token (never a card number)
  final String sessionToken;

  /// Only the last 4 digits of the card (for receipt/invoice purposes)
  final String cardLast4;
}

class PaymentVerificationResult {
  const PaymentVerificationResult({
    required this.succeeded,
    required this.providerRef,
    required this.cardLast4,
    required this.amountIqd,
    this.failureReason,
  });

  final bool succeeded;
  final String providerRef;
  final String cardLast4;
  final int amountIqd;
  final String? failureReason;
}

abstract class PaymentGateway {
  /// Create a secure checkout session URL for 3-D Secure authentication
  Future<CheckoutSessionResult> createCheckoutSession({
    required String userId,
    required String planId,
    required int amountIqd,
    required String currency,
  });

  /// Verify a transaction using the gateway-provided reference
  Future<PaymentVerificationResult> verifyTransaction(String providerRef);
}

/// Sandbox implementation used for Development and QA.
/// Generates synthetic tokens and simulates 3-D Secure OTP verification.
class MastercardSandboxPaymentGateway implements PaymentGateway {
  const MastercardSandboxPaymentGateway();

  @override
  Future<CheckoutSessionResult> createCheckoutSession({
    required String userId,
    required String planId,
    required int amountIqd,
    required String currency,
  }) async {
    // Simulate gateway API handshake
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final token = 'tok_sandbox_mc_${DateTime.now().millisecondsSinceEpoch}';

    return CheckoutSessionResult(
      sessionUrl: 'https://sandbox.gateway.madrasi.iq/checkout?token=$token',
      sessionToken: token,
      cardLast4: '5412',
    );
  }

  @override
  Future<PaymentVerificationResult> verifyTransaction(String providerRef) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return PaymentVerificationResult(
      succeeded: true,
      providerRef: providerRef,
      cardLast4: '5412',
      amountIqd: 25000,
    );
  }
}

/// Live implementation stub: Strictly locked until formal user approval.
/// Prevents any live payments from being triggered without explicit confirmation.
class UnconfiguredLivePaymentGateway implements PaymentGateway {
  const UnconfiguredLivePaymentGateway();

  @override
  Future<CheckoutSessionResult> createCheckoutSession({
    required String userId,
    required String planId,
    required int amountIqd,
    required String currency,
  }) {
    throw UnsupportedError(
      'Live payment gateway is locked. Awaiting user review and explicit approval '
      'of the designated Iraqi payment provider before activating live mode.',
    );
  }

  @override
  Future<PaymentVerificationResult> verifyTransaction(String providerRef) {
    throw UnsupportedError(
      'Live payment gateway is locked. Awaiting user review and explicit approval.',
    );
  }
}
