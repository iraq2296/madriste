import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import 'auth_service.dart';
import 'integrations.dart';

final authServiceProvider = Provider<AuthService>((ref) => createAuthService(ref.read(dataStoreProvider)));
final paymentGatewayProvider = Provider<PaymentGateway>((ref) => createPaymentGateway());
final faceServiceProvider = Provider<FaceVerificationService>((ref) => createFaceService());
final ocrServiceProvider = Provider<OcrService>((ref) => createOcrService());
final callServiceProvider = Provider<CallService>((ref) => createCallService());

