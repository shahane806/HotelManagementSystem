import 'dart:math';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';
import '../app/payu_config.dart';
import 'payu_hash_service.dart';

class PayUService {
  final PayUCheckoutProFlutter _payU;
  final PayUHashService _hashService;

  PayUService({required PayUCheckoutProFlutter payU})
      : _payU = payU,
        _hashService = PayUHashService(
          merchantSalt: PayUConfig.merchantSalt,
          merchantSecretKey: PayUConfig.merchantSecret,
        );

  String generateTxnId(String userId) {
    final rand = Random().nextInt(9000) + 1000;
    return "U${userId}D${DateTime.now().millisecondsSinceEpoch}R$rand";
  }

  Future<void> startPayment({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    required String amount,
    required String productInfo,
  }) async {
    final txnId = generateTxnId(userId);
    final paymentParams = PayUConfig.createPaymentParams(
      amount: amount,
      name: fullName,
      email: email,
      phone: phone,
      txnId: txnId,
      productInfo:productInfo,
    );
    final configParams = PayUConfig.createConfigParams();

    await _payU.openCheckoutScreen(
      payUPaymentParams: paymentParams,
      payUCheckoutProConfig: configParams,
    );
  }

  void handleHash(Map response) {
    final hash = _hashService.generateHash(
      hashName: response['hashName'],
      hashString: response['hashString'],
      hashType: response['hashType'],
      postSalt: response['postSalt'],
    );
    _payU.hashGenerated(hash: hash);
  }
}
