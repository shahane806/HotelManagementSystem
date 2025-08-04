class PayUConfig {
  static const merchantKey = "FDbfXn";
  static const merchantSalt = "BzfHFbtbaJMkYUBeVMAIJexf0Uf2mD2t";
  static const merchantSecret = "5fcd4c398830074cac484dce7a9f511d4417c49c4e65c81c364e8abb33793358";
  static const iosSurl = "https://your-domain.com/payu/success";
  static const iosFurl = "https://your-domain.com/payu/failure";
  static const androidSurl = "https://your-domain.com/payu/success";
  static const androidFurl = "https://your-domain.com/payu/failure";
  static const merchantAccessKey = "";
  static const sodexoSourceId = "";
  static Map<String, dynamic> createPaymentParams({
    required String amount,
    required String name,
    required String email,
    required String phone,
    required String txnId,
    required String productInfo,
  }) {
     var additionalParam = {
      'udf1': "udf1",
      'udf3': "udf3",
      'udf4': "udf4",
      'udf5': "udf5",
      'merchantAccessKey': PayUConfig.merchantAccessKey,
      'sourceId': PayUConfig.sodexoSourceId,
    };
    return {
      'key': PayUConfig.merchantKey,
      'amount': amount,
      'productInfo': productInfo,
      'firstName': name,
      'email': email,
      'phone': phone,
      'ios_surl': PayUConfig.iosSurl,
      'ios_furl': PayUConfig.iosFurl,
      'android_surl': PayUConfig.androidSurl,
      'android_furl': PayUConfig.androidFurl,
      'environment': "0", // Change to "1" for production
      'userCredential': "${PayUConfig.merchantKey}:$name",
      'transactionId': txnId,
      'additionalParam': additionalParam,
      'enableNativeOTP': true,
      'userToken': "",
    };
  }

  static Map<String, dynamic> createConfigParams() {
     var paymentModesOrder = [
      {"Wallets": "PHONEPE"},
      {"UPI": "TEZ"},
      {"Wallets": ""},
      {"EMI": ""},
      {"NetBanking": ""},
    ];
    return {
      'primaryColor': "#3f3f97",
      'secondaryColor': "#FFFFFF",
      'merchantName': "SHAHANE OM PRASHANT",
      'merchantLogo': "logo",
      'showExitConfirmationOnCheckoutScreen': true,
      'showExitConfirmationOnPaymentScreen': true,
      'paymentModesOrder': paymentModesOrder,
      'merchantResponseTimeout': 30000,
      'autoSelectOtp': true,
      'waitingTime': 30000,
      'autoApprove': true,
      'merchantSMSPermission': true,
      'showCbToolbar': true,
    };
  }
}
