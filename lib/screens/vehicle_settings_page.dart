import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_share_app/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ride_share_app/core/constants/app_colors.dart';
import 'package:ride_share_app/models/ride.dart';
import 'package:ride_share_app/models/user.dart';

class VehicleSettingsPage extends StatefulWidget {
  const VehicleSettingsPage({super.key});

  @override
  State<VehicleSettingsPage> createState() => _VehicleSettingsPageState();
}

class _VehicleSettingsPageState extends State<VehicleSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _vehicleNameController;
  late TextEditingController _vehicleNumberController;
  late TextEditingController _seatsController;
  VehicleType _vehicleType = VehicleType.car;
  File? _licenseImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _vehicleNameController = TextEditingController(
      text: user?.vehicleName ?? '',
    );
    _vehicleNumberController = TextEditingController(
      text: user?.vehicleNumber ?? '',
    );
    _seatsController = TextEditingController(text: user?.vehicleSeats ?? '4');

    if (user?.vehicleType != null) {
      try {
        _vehicleType = VehicleType.values.firstWhere(
          (e) => e.name == user!.vehicleType,
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _vehicleNameController.dispose();
    _vehicleNumberController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _licenseImage = File(pickedFile.path));
    }
  }

  Future<void> _saveSettings() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    if (user == null) return;

    final isLicenseApproved = user.verificationStatus == 'approved';

    if (_formKey.currentState!.validate()) {
      // If not approved and no existing license URL/Base64, image is mandatory
      // Note: Here we are just checking local file. In a real scenario we'd check if remote exists too.
      // For now, assuming if not approved, re-upload might be needed or handled elsewhere.
      // But strictly speaking:
      if (!isLicenseApproved &&
          _licenseImage == null &&
          user.licenseUrl == null &&
          user.licenseBase64 == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload your license image for verification.'),
          ),
        );
        return;
      }

      setState(() => _isSaving = true);

      // Update User Model locally first
      UserModel updatedUser = user.copyWith(
        vehicleType: _vehicleType.name,
        vehicleName: _vehicleNameController.text.trim(),
        vehicleNumber: _vehicleNumberController.text.trim(),
        vehicleSeats: _seatsController.text.trim(),
      );

      // TODO: If _licenseImage is not null, upload it or convert to Base64 and update updatedUser
      // For this specific task, we are focusing on vehicle details text fields as requested.

      final success = await auth.updateUser(updatedUser);

      setState(() => _isSaving = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle settings saved successfully!'),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(auth.error ?? 'Failed to save settings')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Vehicle Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSectionTitle('Vehicle Details'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<VehicleType>(
                    value: _vehicleType,
                    decoration: _inputDecoration(
                      'Vehicle Type',
                      Icons.commute_rounded,
                    ),
                    items: VehicleType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _vehicleType = val!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vehicleNameController,
                    decoration: _inputDecoration(
                      'Make & Model (e.g. Maruti Swift)',
                      Icons.directions_car_filled_rounded,
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vehicleNumberController,
                    decoration: _inputDecoration(
                      'Vehicle Number (e.g. KL 01 AB 1234)',
                      Icons.numbers_rounded,
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _seatsController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      'Total Seats (including driver)',
                      Icons.event_seat_rounded,
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ],
              ),
            ),
            // Only show verification section if not already approved
            if (Provider.of<AuthProvider>(
                  context,
                ).currentUser?.verificationStatus !=
                'approved') ...[
              const SizedBox(height: 32),
              _buildSectionTitle('Verification'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Driving License',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _licenseImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _licenseImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.cloud_upload_rounded,
                                    size: 40,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to upload license image',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 48),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Vehicle Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}
