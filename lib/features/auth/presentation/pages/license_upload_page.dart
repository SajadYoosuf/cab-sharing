import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ride_share_app/core/constants/app_colors.dart';
import 'package:ride_share_app/features/auth/presentation/providers/verification_provider.dart';
import 'package:ride_share_app/features/auth/presentation/pages/processing_page.dart';

class LicenseUploadPage extends StatelessWidget {
  const LicenseUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VerificationProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Driving License (Optional)'),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.skipLicense();
              _submit(context);
            },
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Do you want to offer rides?',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'To offer rides, you must upload a valid driving license. If you skip this, you can only join rides as a passenger.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => provider.pickLicenseImage(),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: provider.licenseImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.drive_eta_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('Upload License Front', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(provider.licenseImage!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: provider.licenseImage != null
                  ? () => _submit(context)
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProcessingPage()));
  }
}
