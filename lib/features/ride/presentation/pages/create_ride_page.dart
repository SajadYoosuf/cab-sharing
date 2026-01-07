import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_share_app/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ride_entity.dart';
import '../providers/ride_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../widgets/location_picker.dart';

class CreateRidePage extends StatefulWidget {
  const CreateRidePage({super.key});

  @override
  State<CreateRidePage> createState() => _CreateRidePageState();
}

class _CreateRidePageState extends State<CreateRidePage> {
  final _formKey = GlobalKey<FormState>();
  RideType _rideType = RideType.offer;
  
  // Locations
  RideLocation? _fromLocation;
  RideLocation? _toLocation;
  
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  
  final _priceController = TextEditingController();
  final _noteController = TextEditingController(); // Added note controller
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _seats = 1;
  VehicleType _vehicleType = VehicleType.car; // Default to car

  // Preferences
  bool _noAlcohol = false;
  bool _noSmoking = false;
  bool _noPets = false;
  bool _noLuggage = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _priceController.dispose();
    _noteController.dispose(); // Dispose note controller
    super.dispose();
  }

  Future<void> _pickLocation(bool isFrom) async {
    // Default to a known location if not yet selected, or current selection
    // Mountain View default
    final initialPos = isFrom 
        ? (_fromLocation != null ? LatLng(_fromLocation!.latitude, _fromLocation!.longitude) : const LatLng(37.42796133580664, -122.085749655962))
        : (_toLocation != null ? LatLng(_toLocation!.latitude, _toLocation!.longitude) : const LatLng(37.42796133580664, -122.085749655962));

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPicker(
          initialLocation: initialPos,
          onLocationPicked: (name, location) {
            setState(() {
              if (isFrom) {
                _fromLocation = RideLocation(
                  name: name,
                  latitude: location.latitude,
                  longitude: location.longitude,
                );
                _fromController.text = name;
              } else {
                _toLocation = RideLocation(
                  name: name,
                  latitude: location.latitude,
                  longitude: location.longitude,
                );
                _toController.text = name;
              }
            });
          },
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030), // Fixed: Updated to 2030
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submitRide() async {
    if (_formKey.currentState!.validate()) {
      if (_fromLocation == null || _toLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both locations from map')),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final rideProvider = Provider.of<RideProvider>(context, listen: false);

      final user = authProvider.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to create a ride')),
        );
        return;
      }

      final DateTime finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final newRide = RideEntity(
        id: '', 
        hostId: user.id,
        hostName: user.name,
        type: RideType.offer,
        vehicleType: _vehicleType, 
        note: _noteController.text,
        from: _fromLocation!,
        to: _toLocation!,
        dateTime: finalDateTime,
        seats: _seats,
        price: double.tryParse(_priceController.text) ?? 0.0,
        status: RideStatus.open,
        noAlcohol: _noAlcohol,
        noSmoking: _noSmoking,
        noPets: _noPets,
        noLuggage: _noLuggage,
      );

      final success = await rideProvider.createRide(newRide);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride created successfully!'),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(rideProvider.error ?? 'Failed to create ride'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _checkLicense();
    });
  }

  Future<void> _checkLicense() async {
     final auth = Provider.of<AuthProvider>(context, listen: false);
     final user = auth.currentUser;
     
     if (user == null) return;
     
     // Fetch fresh data from firestore to check status
     // We ideally should update UserEntity to hold this status or fetch specifically
     // For now, let's fetch doc from firestore directly for safety check
     final doc = await FirebaseFirestore.instance.collection('users').doc(user.id).get();
     final data = doc.data();
     
     if (data == null || data['licenseStatus'] != 'approved') {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('License Required'),
            content: const Text('To offer rides, you must have an approved driving license. Please upload your license for verification.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close CreateRidePage
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        );
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Offer a Ride', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Vehicle Details'),
              const SizedBox(height: 16),
              _buildVehicleSelector(),
              const SizedBox(height: 32),
              
              _buildSectionTitle('Route Details'),
              const SizedBox(height: 16),
              _buildLocationField(
                controller: _fromController,
                label: 'Pick-up Location',
                icon: Icons.my_location_rounded,
                onTap: () => _pickLocation(true),
              ),
              const SizedBox(height: 16),
              _buildLocationField(
                controller: _toController,
                label: 'Drop-off Location',
                icon: Icons.location_on_rounded,
                onTap: () => _pickLocation(false),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Schedule & Capacity'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerButton(
                      icon: Icons.calendar_today_rounded,
                      label: "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPickerButton(
                      icon: Icons.access_time_rounded,
                      label: _selectedTime.format(context),
                      onTap: () => _selectTime(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Seats: $_seats',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.primary.withOpacity(0.1),
                            thumbColor: AppColors.primary,
                            overlayColor: AppColors.primary.withOpacity(0.1),
                          ),
                          child: Slider(
                            value: _seats.toDouble(),
                            min: 1,
                            max: _vehicleType == VehicleType.bike ? 1 : 6,
                            divisions: _vehicleType == VehicleType.bike ? 1 : 5,
                            onChanged: _vehicleType == VehicleType.bike ? null : (v) => setState(() => _seats = v.toInt()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Additional Notes'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Any specific instructions for riders...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.note_add_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Preferences'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                   _buildPreferenceChip('No Alcohol', _noAlcohol, (v) => setState(() => _noAlcohol = v)),
                   _buildPreferenceChip('No Smoking', _noSmoking, (v) => setState(() => _noSmoking = v)),
                   _buildPreferenceChip('No Pets', _noPets, (v) => setState(() => _noPets = v)),
                   _buildPreferenceChip('No Luggage', _noLuggage, (v) => setState(() => _noLuggage = v)),
                ],
              ),

              if (_vehicleType == VehicleType.bike) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Safety Warning: Helmets are mandatory for both host and passenger during bike rides.',
                          style: TextStyle(color: Colors.orange.shade900, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitRide,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                  child: const Text('Post Ride Offer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
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

  Widget _buildVehicleSelector() {
    return Row(
      children: [
        _buildVehicleOption(VehicleType.car, 'Car', Icons.directions_car_rounded),
        const SizedBox(width: 16),
        _buildVehicleOption(VehicleType.bike, 'Bike', Icons.directions_bike_rounded),
      ],
    );
  }

  Widget _buildVehicleOption(VehicleType type, String label, IconData icon) {
    bool isSelected = _vehicleType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _vehicleType = type;
          if (type == VehicleType.bike) _seats = 1;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200),
            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade600, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField({required TextEditingController controller, required String label, required IconData icon, required VoidCallback onTap}) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: const Icon(Icons.map_rounded, size: 20),
      ),
      validator: (v) => v!.isEmpty ? 'Please pick a location' : null,
    );
  }

  Widget _buildPickerButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceChip(String label, bool isSelected, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
      ),
    );
  }
}
