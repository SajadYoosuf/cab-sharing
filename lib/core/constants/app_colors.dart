import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF009688); // Teal for eco-friendly
  static const Color primaryDark = Color(0xFF00796B);
  static const Color primaryLight = Color(0xFFB2DFDB);
  
  static const Color secondary = Color(0xFFFFC107); // Amber for accents
  
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
