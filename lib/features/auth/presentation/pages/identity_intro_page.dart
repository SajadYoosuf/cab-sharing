import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_share_app/core/constants/app_colors.dart';
import 'package:ride_share_app/features/auth/presentation/pages/residency_proof_page.dart';

class IdentityIntroPage extends StatelessWidget {
  const IdentityIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Container(
                 padding: const EdgeInsets.all(30),
                 decoration: BoxDecoration(
                   color: AppColors.primary.withOpacity(0.1),
                   shape: BoxShape.circle,
                 ),
                 child: const Icon(Icons.verified_user_rounded, size: 80, color: AppColors.primary),
               ),
               const SizedBox(height: 40),
               Text(
                 'Let\'s Verify Your Identity',
                 style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
                 textAlign: TextAlign.center,
               ),
               const SizedBox(height: 16),
               Text(
                 'To ensure the safety of our community, we need to verify your identity. This helps us create a trusted environment for everyone.',
                 style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
                 textAlign: TextAlign.center,
               ),
               const Spacer(),
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const ResidencyProofPage()));
                   },
                   style: ElevatedButton.styleFrom(
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   ),
                   child: const Text('Verify Identity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }
}
