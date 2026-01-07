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
    final error = await _locationService.checkAndRequestPermission();
    if (error == null) {
      final pos = await _locationService.getCurrentLocation();
      if (pos != null && mounted) {
        setState(() {
          _currentCenter = LatLng(pos.latitude, pos.longitude);
          _mapController.move(_currentCenter, 15);
          _errorMessage = "";
        });
        _getAddressFromLatLng(_currentCenter);
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = error;
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

  final TextEditingController _searchController = TextEditingController();

  Future<void> _searchAddress(String value) async {
    if (value.isEmpty) return;
    
    setState(() => _isLoadingPayload = true);
    final coords = await _locationService.getCoordinatesFromAddress(value);
    
    if (mounted) {
      if (coords != null) {
        final newPos = LatLng(coords[0], coords[1]);
        _mapController.move(newPos, 15);
        _currentCenter = newPos;
        _getAddressFromLatLng(newPos);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not found. Please try again.')),
        );
        setState(() => _isLoadingPayload = false);
      }
    }
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
          // Search Bar
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for place...',
                  border: InputBorder.none,
                  icon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  ),
                ),
                onSubmitted: _searchAddress,
              ),
            ),
          ),
          // Center Marker
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40), // Offset for pin point
              child: Icon(Icons.location_on_rounded, size: 50, color: Colors.red),
            ),
          ),
          // Address Card
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.location_on, color: Colors.blue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _isLoadingPayload
                              ? const LinearProgressIndicator()
                              : Text(
                                  _address,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
             bottom: 120,
             child: FloatingActionButton(
                heroTag: "my_location",
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                onPressed: _checkLocation,
                child: const Icon(Icons.my_location),
             ),
          )
        ],
      ),
    );
  }
}
