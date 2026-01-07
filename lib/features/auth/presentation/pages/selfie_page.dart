import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ride_share_app/core/constants/app_colors.dart';
import 'package:ride_share_app/features/auth/presentation/providers/verification_provider.dart';
import 'package:ride_share_app/features/auth/presentation/pages/license_upload_page.dart';

class SelfiePage extends StatelessWidget {
  const SelfiePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VerificationProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Take a Selfie'),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
         padding: const EdgeInsets.all(24),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             Text(
               'We need a selfie to match your ID',
               style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 12),
             const Text(
               'Please make sure your face is clearly visible and you are not wearing sunglasses or a mask.',
               style: TextStyle(color: Colors.grey, fontSize: 16),
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 40),
             Center(
               child: GestureDetector(
                 onTap: () => provider.pickSelfieImage(),
                 child: Container(
                   width: 280,
                   height: 350,
                   decoration: BoxDecoration(
                     color: Colors.grey.shade100,
                     borderRadius: BorderRadius.circular(200), // Elliptical/Oval shape
                     border: Border.all(color: AppColors.primary, width: 2),
                   ),
                   child: provider.selfieImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Tap to take photo'),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(200),
                          child: Image.file(provider.selfieImage!, fit: BoxFit.cover),
                        ),
                 ),
               ),
             ),
             const SizedBox(height: 40),
             ElevatedButton(
               onPressed: provider.selfieImage != null
                   ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LicenseUploadPage()))
                   : null,
               style: ElevatedButton.styleFrom(
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               ),
               child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
             ),
           ],
         ),
      ),
    );
  }
}
