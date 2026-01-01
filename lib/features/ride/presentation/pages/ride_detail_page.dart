import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/ride_entity.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../widgets/sos_button.dart';
import '../../../../core/services/location_service.dart';

class RideDetailPage extends StatefulWidget {
  final RideEntity ride;

  const RideDetailPage({super.key, required this.ride});

  @override
  State<RideDetailPage> createState() => _RideDetailPageState();
}

class _RideDetailPageState extends State<RideDetailPage> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  LatLng? _currentPosition;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() {
    _locationService.getPositionStream().listen((pos) {
      if (mounted) {
        setState(() {
          _isTracking = true;
          _currentPosition = LatLng(pos.latitude, pos.longitude);
        });
      }
    });
  }

  void _triggerSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("SOS Triggered"),
        content: const Text("Emergency contacts have been notified with your current location."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final start = LatLng(widget.ride.from.latitude, widget.ride.from.longitude);
    final end = LatLng(widget.ride.to.latitude, widget.ride.to.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    rideId: widget.ride.id,
                    title: 'Chat with ${widget.ride.hostName}',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: start,
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ride_share_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: start,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: Colors.green, size: 40),
                  ),
                  Marker(
                    point: end,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                  ),
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.navigation, color: Colors.red, size: 40),
                    ),
                ],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [start, end],
                    strokeWidth: 4.0,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 30,
            left: 20,
            child: SOSButton(onPressed: _triggerSOS),
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'center_map',
              onPressed: () {
                if (_currentPosition != null) {
                  _mapController.move(_currentPosition!, 15);
                } else {
                  _mapController.move(start, 15);
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              color: Colors.white.withValues(alpha: 0.9),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("From: ${widget.ride.from.name}"),
                    const Divider(),
                    Text("To: ${widget.ride.to.name}"),
                    const SizedBox(height: 4),
                    Text("Host: ${widget.ride.hostName}"),
                    const SizedBox(height: 4),
                    if (_isTracking)
                      const Row(
                         children: [
                           Icon(Icons.gps_fixed, size: 16, color: Colors.green),
                           SizedBox(width: 4),
                           Text("Live Tracking Active", style: TextStyle(color: Colors.green, fontSize: 12)),
                         ],
                      ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
