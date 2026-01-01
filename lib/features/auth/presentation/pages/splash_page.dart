import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_car_filled_rounded,
              size: 80,
              color: Colors.white,
            ).animate().scale(duration: 600.ms).then().shake(),
            const SizedBox(height: 20),
            Text(
              'EcoRide',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),
            const SizedBox(height: 10),
            Text(
              'Share Rides. Save Planet.',
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 16,
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
