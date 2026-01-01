import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/location_service.dart';

class LocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(String name, LatLng location) onLocationPicked;

  const LocationPicker({
    super.key,
    this.initialLocation,
    required this.onLocationPicked,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final MapController _mapController = MapController();
  LatLng _currentCenter = const LatLng(37.42796133580664, -122.085749655962); // Default
  String _address = "Searching...";
  bool _isLoadingPayload = false;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _currentCenter = widget.initialLocation!;
      _getAddressFromLatLng(_currentCenter);
    } else {
      _errorMessage = "Fetching current location...";
      _checkLocation();
    }
  }

  String _errorMessage = "";

  Future<void> _checkLocation() async {
    final pos = await _locationService.getCurrentLocation();
    if (pos != null) {
      if (mounted) {
        setState(() {
          _currentCenter = LatLng(pos.latitude, pos.longitude);
          _mapController.move(_currentCenter, 15);
        });
        _getAddressFromLatLng(_currentCenter);
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = "Could not get current location.";
          _getAddressFromLatLng(_currentCenter); // Resolve default
        });
      }
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    if (!mounted) return;
    setState(() {
      _isLoadingPayload = true;
    });
    
    final address = await _locationService.getAddressFromCoordinates(position.latitude, position.longitude);
    
    if (mounted) {
      setState(() {
        _address = address;
        _isLoadingPayload = false;
      });
    }
  }

  void _onMapPositionChanged(MapCamera position, bool hasGesture) {
    setState(() {
      _currentCenter = position.center;
    });
  }

  void _onMapIdle() {
     _getAddressFromLatLng(_currentCenter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              widget.onLocationPicked(_address, _currentCenter);
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15.0,
              onPositionChanged: _onMapPositionChanged,
              onMapEvent: (evt) {
                 if (evt is MapEventMoveEnd) {
                   _onMapIdle();
                 }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ride_share_app',
              ),
            ],
          ),
          // Center Marker
          const Center(
            child: Icon(Icons.location_pin, size: 48, color: Colors.red),
          ),
          // Address Card
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                      ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _isLoadingPayload
                              ? const LinearProgressIndicator()
                              : Text(
                                  _address,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
             right: 20,
             bottom: 100,
             child: FloatingActionButton(
                heroTag: "my_location",
                onPressed: _checkLocation,
                child: const Icon(Icons.my_location),
             ),
          )
        ],
      ),
    );
  }
}
