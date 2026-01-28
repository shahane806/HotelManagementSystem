import 'package:flutter/foundation.dart' show kIsWeb;
// Only import dart:io on non-web platforms
// ignore: avoid_web_libraries_in_flutter
import 'dart:io' show Platform;

class ApiConstants {
  static const bool isEmulator =
      bool.fromEnvironment('IS_EMULATOR', defaultValue: false);

  static String get url {
    if (kIsWeb) {
      // 🌐 Running in browser
      // return "http://localhost:3001";
      // or your hosted API endpoint:
      return "https://hotelmanagementsystem-ysx7.onrender.com";
    }

    // 📱 Native (mobile/desktop)
    if (Platform.isAndroid) {
      return isEmulator
          ? "http://10.0.2.2:3001"
         : "https://hotelmanagementsystem-ysx7.onrender.com";
      //  : "http://192.168.29.93:3001"; // your PC Wi-Fi IP
    } else {
      return "http://10.0.2.2:3001";
    }
  }

  static String get socketUrl {
    if (kIsWeb) {
      // 🌐 WebSocket URL for browser
      // return "ws://localhost:3000";
      // Or hosted socket endpoint:
      return "https://hotelmanagementsystem-socket.onrender.com";
    }

    // 📱 Native
    if (Platform.isAndroid) {
      return isEmulator
          ? "http://10.0.2.2:3000"
          : "https://hotelmanagementsystem-socket.onrender.com";
          // :"http://192.168.29.93:3000";
    } else {
      return "http://10.0.2.2:3000";
    }
  }
}
