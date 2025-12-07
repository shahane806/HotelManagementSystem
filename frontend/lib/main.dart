import 'package:flutter/material.dart';
import 'package:frontend/app/constants.dart';
import 'package:frontend/widgets/wrapper.dart';
import 'myapp.dart';
import 'services/socketService.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final socketService = SocketService();
  socketService.connect(); // Manually connect
  AppConstants.initiateSharedPreferences();
  runApp(wrapper(const MyApp()));
}
