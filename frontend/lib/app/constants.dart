import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color primaryColor = Color(0xFF007BFF);
  static const Color secondaryColor = Color(0xFF28A745);
  static const Color backgroundColor = Color(0xFFF5F6F5);
  static const Color textColor = Color(0xFF212529);
  static const Color errorColor = Color(0xFFDC3545);
  static const Color cardColor = Colors.white;
  static const inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
    borderSide: BorderSide(color: Colors.grey),
  );
  // Dimensions
  static const double paddingSmall = 8.0;
  static const double paddingLarge = 16.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;

  // GST and Merchant Info
  static const double gstRate = 0.18; // 18% GST
  static const String merchantGstNumber = '27AABCU9603R1ZM'; // Example GSTIN
  static const String companyName = 'Your Restaurant Name';
  static const String companyAddress = '123 Food Street, City, Country';

  // Currency Symbol
  static const String rupeeSymbol = '₹';

  // Animation Duration
  static const Duration animationDuration = Duration(milliseconds: 600);
}