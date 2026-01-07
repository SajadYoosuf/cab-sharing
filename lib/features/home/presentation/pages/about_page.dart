import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('About EcoRide', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco_rounded, size: 80, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'EcoRide',
              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            _buildAboutCard(
              'Our Mission',
              'EcoRide is dedicated to reducing carbon emissions and traffic congestion by promoting carpooling and shared mobility solutions. Our goal is to make every commute green and affordable.',
            ),
            const SizedBox(height: 20),
            _buildAboutCard(
              'Sustainability',
              'By sharing rides, we\'ve collectively saved over 5000kg of CO2 this year alone. Every ride you share contributes to a cleaner, greener planet.',
            ),
            const SizedBox(height: 20),
            _buildAboutCard(
              'Safety First',
              'EcoRide implements strict verification processes for both drivers and passengers. With features like live location sharing and instant SOS, your safety is our top priority.',
            ),
            const SizedBox(height: 40),
            const Text(
              'Developed by regional college projects\n© 2026 EcoRide Inc.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 12),
          Text(description, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
        ],
      ),
    );
  }
}
