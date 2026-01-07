import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ride_share_app/core/constants/app_colors.dart';
import 'package:ride_share_app/features/ride/presentation/providers/ride_provider.dart';
import 'package:ride_share_app/features/auth/presentation/providers/auth_provider.dart';

class VerificationStatusPage extends StatefulWidget {
  const VerificationStatusPage({super.key});

  @override
  State<VerificationStatusPage> createState() => _VerificationStatusPageState();
}

class _VerificationStatusPageState extends State<VerificationStatusPage> {
  
  @override
  void initState() {
    super.initState();
    // Refresh user profile to get latest status
    Future.microtask(() => Provider.of<AuthProvider>(context, listen: false).checkAuthStatus());
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isRejected = user?.verificationStatus == 'rejected';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: (isRejected ? Colors.red : Colors.orange).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected ? Icons.dangerous_rounded : Icons.av_timer_rounded, 
                  size: 80, 
                  color: isRejected ? Colors.red : Colors.orange
                ),
              ),
              const SizedBox(height: 32),
              Text(
                isRejected ? 'Verification Rejected' : 'Verification Under Review',
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                isRejected 
                  ? 'Your documents did not match our requirements. Please contact support or try registering again.'
                  : 'Your documents have been submitted and are being reviewed by our admin team. This process usually takes 24 hours.',
                style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              
              if (isRejected)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextButton(
                    onPressed: () {
                       // Optionally allow re-upload or reset
                       Navigator.pushNamed(context, '/phone_verification');
                    }, 
                    child: const Text('Try Again')
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                     await Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
                     if (context.mounted) {
                        final updatedUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
                        if (updatedUser?.verificationStatus == 'approved') {
                           Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                        } else {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Status: ${updatedUser?.verificationStatus ?? "Unknown"}'))
                           );
                        }
                     }
                  },
                  icon: const Icon(Icons.refresh),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  label: const Text('Check Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
               const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                   Provider.of<AuthProvider>(context, listen: false).logout();
                   Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                child: const Text('Logout', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
