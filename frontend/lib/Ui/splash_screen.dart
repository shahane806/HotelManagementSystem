import 'package:flutter/material.dart';
import 'dart:async';

import 'package:frontend/Ui/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to the next screen after 3 seconds
    Timer(const Duration(seconds: 7), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()), // Change to your home/login screen
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hotel logo/icon
             Icon(Icons.hotel, size: 100, color: Colors.indigo),

             SizedBox(height: 20),

            // App title
             Text(
              'Hotel Management System',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),

             SizedBox(height: 10),

            // Tagline
             Text(
              'Manage guests, bookings, and payments with ease',
              style: TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),

             SizedBox(height: 40),

            // Loading indicator
             CircularProgressIndicator(color: Colors.indigo),
          ],
        ),
      ),
    );
  }
}

