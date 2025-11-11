import 'dart:io';

class ApiConstants {
  // 🔹 Detect environment via Flutter build flag
  //    You can pass this flag when running your app:
  //    flutter run --dart-define=IS_EMULATOR=true
  //
  //    When building for phone, just run normally (default = false)
  static const bool isEmulator =
      bool.fromEnvironment('IS_EMULATOR', defaultValue: false);

  // 🔹 API URL
  static String get url {
    if (Platform.isAndroid) {
      // Use special host for emulator, your PC's IP for physical device
      return isEmulator
          ? "http://10.0.2.2:3001"
          : "http://192.168.1.9:3001"; // 👈 your PC Wi-Fi IP
    } else {
      // iOS simulator or Mac
      return "http://localhost:3001";
    }
  }

  // 🔹 Socket URL
  static String get socketUrl {
    if (Platform.isAndroid) {
      return isEmulator
          ? "http://10.0.2.2:3000"
          : "http://192.168.1.9:3000"; // 👈 your PC Wi-Fi IP
    } else {
      return "http://localhost:3000";
    }
  }
}
