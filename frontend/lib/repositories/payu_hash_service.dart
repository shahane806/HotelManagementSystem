import 'dart:convert';
import 'package:crypto/crypto.dart';

class PayUHashService {
  final String merchantSalt;
  final String merchantSecretKey;

  PayUHashService({
    required this.merchantSalt,
    required this.merchantSecretKey,
  });

  Map<String, String> generateHash({
    required String hashName,
    required String hashString,
    required String hashType,
    String? postSalt,
  }) {
    String finalHash;

    if (hashType == 'v2') {
      finalHash = _hmacSha256(hashString, merchantSalt);
    } else if (hashName == 'mcpLookup') {
      finalHash = _hmacSha1(hashString, merchantSecretKey);
    } else {
      var data = hashString + merchantSalt + (postSalt ?? '');
      finalHash = _sha512(data);
    }

    return {hashName: finalHash};
  }

  String _sha512(String input) {
    return sha512.convert(utf8.encode(input)).toString();
  }

  String _hmacSha256(String input, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    return base64Encode(hmac.convert(utf8.encode(input)).bytes);
  }

  String _hmacSha1(String input, String key) {
    final hmac = Hmac(sha1, utf8.encode(key));
    return hmac.convert(utf8.encode(input)).toString();
  }
}
