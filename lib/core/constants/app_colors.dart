import 'package:flutter/material.dart';

class AppColors {
  // Primary: Sophisticated Teal
  static const Color primary = Color(0xFF00796B); 
  static const Color primaryDark = Color(0xFF004D40);
  static const Color primaryLight = Color(0xFF4DB6AC);
  
  // Secondary: Soft Amber/Gold
  static const Color secondary = Color(0xFFFFB300); 
  static const Color accent = Color(0xFF00BFA5);
  
  // Neutral Colors
  static const Color background = Color(0xFFF1F4F8);
  static const Color surface = Colors.white;
  static const Color cardBg = Colors.white;
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF42474E);
  static const Color textHint = Color(0xFF72777E);
  
  // State Colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF1F4F8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Glassmorphism helper
  static Color glass(Color color, [double opacity = 0.1]) => color.withOpacity(opacity);
}
