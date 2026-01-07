import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:ride_share_app/core/constants/app_colors.dart';
import 'package:ride_share_app/features/auth/presentation/providers/verification_provider.dart';
import 'package:ride_share_app/features/auth/presentation/pages/identity_intro_page.dart';

class PhoneVerificationPage extends StatefulWidget {
  const PhoneVerificationPage({super.key});

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _codeSent = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VerificationProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mobile Verification'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
           onPressed: () {
             if (Navigator.canPop(context)) {
               Navigator.pop(context);
             } else {
               Navigator.pushReplacementNamed(context, '/login');
             }
           },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.phonelink_ring_rounded, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              _codeSent ? 'Verify OTP' : 'Enter Mobile Number',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _codeSent 
                  ? 'Enter the code sent to ${_phoneController.text}'
                  : 'We will send you a verification code to confirm your number.',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            if (!_codeSent)
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixText: '+91 ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone),
                ),
              )
            else
              Pinput(
                length: 6,
                controller: _otpController,
                defaultPinTheme: PinTheme(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                onCompleted: (pin) => _verifyOtp(context, pin),
              ),

             const SizedBox(height: 32),
             
             if (provider.isLoading)
               const Center(child: CircularProgressIndicator())
             else
               ElevatedButton(
                 onPressed: _codeSent 
                    ? () => _verifyOtp(context, _otpController.text)
                    : () async {
                        if (_phoneController.text.length < 10) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid number')));
                          return;
                        }
                        await provider.sendOtp('+91${_phoneController.text}');
                        if (provider.error == null) {
                           setState(() => _codeSent = true);
                        } else {
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error!), backgroundColor: Colors.red));
                           }
                        }
                    },
                 style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 ),
                 child: Text(_codeSent ? 'Verify Code' : 'Send OTP', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
               ),

             if (_codeSent)
                TextButton(
                  onPressed: () => setState(() => _codeSent = false),
                  child: const Text('Change Number'),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyOtp(BuildContext context, String otp) async {
    final provider = Provider.of<VerificationProvider>(context, listen: false);
    if (otp.length != 6) return;

    final success = await provider.verifyOtp(otp);
    if (success && context.mounted) {
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const IdentityIntroPage()));
    } else if (provider.error != null && context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error!), backgroundColor: Colors.red));
    }
  }
}
