import 'package:flutter/material.dart';
import 'package:frontend/widgets/wrapper.dart';

import 'myapp.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(wrapper(const MyApp()));
}

