import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
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
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _seats = 1;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _priceController.dispose();
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
      lastDate: DateTime(2025),
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
        type: _rideType,
        from: _fromLocation!,
        to: _toLocation!,
        dateTime: finalDateTime,
        seats: _seats,
        price: double.tryParse(_priceController.text) ?? 0.0,
        status: RideStatus.open,
      );

      try {
        await rideProvider.createRide(newRide);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ride created successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Ride'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ride Type Selector
              SegmentedButton<RideType>(
                segments: const [
                  ButtonSegment(
                    value: RideType.offer,
                    label: Text('Offer Ride'),
                    icon: Icon(Icons.directions_car),
                  ),
                  ButtonSegment(
                    value: RideType.request,
                    label: Text('Request Ride'),
                    icon: Icon(Icons.hail),
                  ),
                ],
                selected: {_rideType},
                onSelectionChanged: (Set<RideType> newSelection) {
                  setState(() {
                    _rideType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // From
              TextFormField(
                controller: _fromController,
                readOnly: true,
                onTap: () => _pickLocation(true),
                decoration: const InputDecoration(
                  labelText: 'From',
                  hintText: 'Tap to pick on map',
                  prefixIcon: Icon(Icons.my_location),
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.map),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please pick a start location' : null,
              ),
              const SizedBox(height: 16),
              
              // To
              TextFormField(
                controller: _toController,
                readOnly: true,
                onTap: () => _pickLocation(false),
                decoration: const InputDecoration(
                  labelText: 'To',
                  hintText: 'Tap to pick on map',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.map),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please pick a destination' : null,
              ),
              const SizedBox(height: 16),

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectTime(context),
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Seats & Price
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seats: $_seats',
                            style: Theme.of(context).textTheme.titleMedium),
                        Slider(
                          value: _seats.toDouble(),
                          min: 1,
                          max: 6,
                          divisions: 5,
                          label: _seats.toString(),
                          onChanged: (double value) {
                            setState(() {
                              _seats = value.toInt();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price per Seat',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit
              FilledButton(
                onPressed: _submitRide,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Post Ride', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
