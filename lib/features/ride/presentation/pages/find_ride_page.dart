import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_share_app/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:ride_share_app/core/services/location_service.dart';
import '../../domain/entities/ride_entity.dart';
import '../providers/ride_provider.dart';
import 'ride_detail_page.dart';

class FindRidePage extends StatefulWidget {
  const FindRidePage({super.key});

  @override
  State<FindRidePage> createState() => _FindRidePageState();
}

class _FindRidePageState extends State<FindRidePage> {
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _fetchRidesAndLocation();
  }

  Future<void> _fetchRidesAndLocation() async {
    setState(() => _isLocating = true);
    final provider = Provider.of<RideProvider>(context, listen: false);
    
    await provider.loadAvailableRides();
    
    try {
      final pos = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _isLocating = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Nearby Rides', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isLocating ? Icons.location_searching_rounded : Icons.my_location_rounded, 
                 color: _currentPosition != null ? AppColors.primary : Colors.grey),
            onPressed: _fetchRidesAndLocation,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<RideProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading || _isLocating) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return _buildErrorState(provider);
          }

          final filteredRides = _currentPosition == null 
              ? provider.availableRides 
              : provider.availableRides.where((ride) {
                  final distance = Geolocator.distanceBetween(
                    _currentPosition!.latitude, _currentPosition!.longitude, 
                    ride.from.latitude, ride.from.longitude
                  );
                  return distance <= 50000; // 50km
                }).toList();

          if (filteredRides.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: filteredRides.length,
            itemBuilder: (context, index) {
              final ride = filteredRides[index];
              double? dist;
              if (_currentPosition != null) {
                dist = Geolocator.distanceBetween(
                  _currentPosition!.latitude, _currentPosition!.longitude, 
                  ride.from.latitude, ride.from.longitude
                ) / 1000;
              }
              return _buildRideCard(context, ride, dist);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create_ride'),
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Offer Ride', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildErrorState(RideProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text('Oops! Something went wrong', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(provider.error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _fetchRidesAndLocation, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(_currentPosition == null ? 'Finding rides...' : 'No rides nearby', 
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(_currentPosition == null 
                ? 'Enable location to see rides in your area.' 
                : 'There are no open rides within 50km of your current location.', 
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, RideEntity ride, double? distance) {
    final timeFormat = DateFormat.jm();
    final dateFormat = DateFormat('MMM d');
    final isFull = ride.seats == 0 || ride.status == RideStatus.booked || ride.status == RideStatus.ongoing;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isFull ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => RideDetailPage(ride: ride))),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Opacity(
              opacity: isFull ? 0.6 : 1.0,
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(ride.hostName[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ride.hostName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text('4.8', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
                                if (distance != null) ...[
                                  const SizedBox(width: 8),
                                  Text('• ${distance.toStringAsFixed(1)} km away', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isFull)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                          child: const Text('FULL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 18)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text('₹${ride.price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildRouteLine(ride),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _buildCardFooter(ride, dateFormat, timeFormat),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteLine(RideEntity ride) {
    return Row(
      children: [
        Column(
          children: [
            const Icon(Icons.circle_outlined, size: 16, color: AppColors.primary),
            Container(width: 2, height: 24, color: Colors.grey.shade200),
            const Icon(Icons.location_on_rounded, size: 16, color: AppColors.secondary),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ride.from.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 20),
              Text(ride.to.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardFooter(RideEntity ride, DateFormat d, DateFormat t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Text('${d.format(ride.dateTime)} at ${t.format(ride.dateTime)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20)),
          child: Text('${ride.seats} seats left', style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
