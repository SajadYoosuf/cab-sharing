import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_share_app/core/constants/app_colors.dart';
import 'package:ride_share_app/features/auth/presentation/providers/verification_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'verification_status_page.dart';

class ProcessingPage extends StatefulWidget {
  const ProcessingPage({super.key});

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startUpload();
  }

  Future<void> _startUpload() async {
    // Simulate initial progress
    for (var i = 0; i <= 30; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
      if (mounted) setState(() => _progress = i / 100);
    }

    if (!mounted) return;
    final provider = Provider.of<VerificationProvider>(context, listen: false);
    
    // Start actual upload
    final success = await provider.submitVerification();

    if (success) {
      // Complete progress
      for (var i = 30; i <= 100; i++) {
         await Future.delayed(const Duration(milliseconds: 10));
         if (mounted) setState(() => _progress = i / 100);
      }
      
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VerificationStatusPage()));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Upload Failed')));
        Navigator.pop(context); // Go back to retry
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(strokeWidth: 4, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 40),
            Text(
              'Processing Data...',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 250,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey.shade100,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
