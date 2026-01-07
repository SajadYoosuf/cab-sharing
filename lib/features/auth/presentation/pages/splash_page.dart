import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:ride_share_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ride_share_app/core/constants/app_colors.dart';
import 'package:ride_share_app/core/services/location_service.dart';
import 'verification_status_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // 1. Wait for auth to be ready from local storage
      await authProvider.initialized;

      // 2. Initial delay for showing logo
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;

      // 2. Check location permissions
      final locationError = await _locationService.checkAndRequestPermission();
      if (locationError != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locationError),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      } finally {
      // 3. Always check auth and navigate
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.checkAuthStatus(); // Ensure we have latest data from Firestore

        if (authProvider.isAuthenticated) {
          final user = authProvider.currentUser;
          
          if (user?.role == 'admin') {
            Navigator.pushNamedAndRemoveUntil(context, '/admin_dashboard', (route) => false);
          } else {
             // Strict Access Control for Regular Users
             if (user?.verificationStatus == 'approved') {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
             } else if (user?.verificationStatus == 'pending' || user?.verificationStatus == 'rejected') {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VerificationStatusPage()));
             } else {
                // Not verified yet, continue flow (e.g. Phone Verification)
                // If phone is verified but docs are missing, provider usually handles this redirection or we go to phone page which redirects?
                // Let's go to PhoneVerification as the entry point for the "Flow"
                Navigator.pushNamedAndRemoveUntil(context, '/phone_verification', (route) => false);
             }
          }
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Stack(
          children: [
            // Decorative background elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_rounded,
                      size: 72,
                      color: Colors.white,
                    ),
                  ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack).then().shimmer(duration: 2.seconds),
                  const SizedBox(height: 32),
                  Text(
                    'EcoRide',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(delay: 400.ms).moveY(begin: 30, end: 0, curve: Curves.easeOutQuad),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Share Rides. Save Planet.',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.8, 0.8)),
                ],
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.5)),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 1200.ms),
          ],
        ),
      ),
    );
  }
}
