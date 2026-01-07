import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_share_app/core/constants/app_colors.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ride_share_app/features/ride/domain/entities/ride_entity.dart';
import 'package:ride_share_app/features/chat/presentation/pages/chat_page.dart';
import 'package:ride_share_app/core/services/location_service.dart';
import 'package:provider/provider.dart';
import 'package:ride_share_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ride_share_app/features/ride/presentation/providers/ride_request_provider.dart';
import 'package:ride_share_app/features/ride/domain/entities/ride_request_entity.dart';
import 'package:ride_share_app/features/ride/presentation/providers/ride_provider.dart';
import 'package:ride_share_app/features/ride/presentation/providers/feedback_provider.dart';
import 'package:ride_share_app/features/ride/domain/entities/feedback_entity.dart';

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
  RideRequestStatus? _requestStatus;
  bool _isLoadingStatus = true;
  bool _isHost = false;
  bool _hasSubmittedFeedback = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _isHost = user?.id == widget.ride.hostId;
    _startTracking();
    if (!_isHost) {
      _checkRequestStatus();
    } else {
      setState(() => _isLoadingStatus = false);
    }
    
    if (widget.ride.status == RideStatus.completed) {
      _checkFeedbackStatus();
    }
  }

  Future<void> _checkFeedbackStatus() async {
     final auth = Provider.of<AuthProvider>(context, listen: false);
     final feedbackProvider = Provider.of<FeedbackProvider>(context, listen: false);
     if (auth.currentUser != null) {
        final submitted = await feedbackProvider.hasSubmittedFeedback(widget.ride.id, auth.currentUser!.id);
        if (mounted) setState(() => _hasSubmittedFeedback = submitted);
     }
  }

  Future<void> _checkRequestStatus() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final requestProvider = Provider.of<RideRequestProvider>(context, listen: false);
    if (auth.currentUser != null) {
      final status = await requestProvider.getRequestStatus(widget.ride.id, auth.currentUser!.id);
      if (mounted) {
        setState(() {
          _requestStatus = status;
          _isLoadingStatus = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingStatus = false);
    }
  }

  void _startTracking() {
    _locationService.getPositionStream().listen((pos) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
        });
        
        // If host, update location in Firestore
        if (_isHost) {
          Provider.of<RideProvider>(context, listen: false)
              .updateHostLocation(widget.ride.id, pos.latitude, pos.longitude);
        }
      }
    });
  }

  Future<void> _sendRideRequest() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final requestProvider = Provider.of<RideRequestProvider>(context, listen: false);
    
    if (auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to request a ride")));
      return;
    }

    final request = RideRequestEntity(
      id: '',
      rideId: widget.ride.id,
      passengerId: auth.currentUser!.id,
      passengerName: auth.currentUser!.name,
      hostId: widget.ride.hostId,
      status: RideRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    final success = await requestProvider.sendRequest(request);
    if (mounted) {
      if (success) {
        setState(() => _requestStatus = RideRequestStatus.pending);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request sent successfully!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to send request or already requested.")));
      }
    }
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppColors.primary),
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
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: start,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ride_share_app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [start, end],
                    strokeWidth: 5.0,
                    color: AppColors.primary.withOpacity(0.6),
                    gradientColors: [AppColors.primary, AppColors.secondary],
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: start,
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
                          child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 24),
                        ),
                      ],
                    ),
                  ),
                  Marker(
                    point: end,
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
                          child: const Icon(Icons.location_on_rounded, color: AppColors.secondary, size: 24),
                        ),
                      ],
                    ),
                  ),
                  if (widget.ride.hostLatitude != null && widget.ride.hostLongitude != null)
                    Marker(
                      point: LatLng(widget.ride.hostLatitude!, widget.ride.hostLongitude!),
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.orange, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.directions_car_filled_rounded, color: Colors.orange, size: 20),
                        ),
                      ),
                    ),
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.person_pin_circle_rounded, color: AppColors.primary, size: 20),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.35,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.ride.hostName}\'s Trip',
                                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Text(
                                      widget.ride.vehicleType.name.toUpperCase(),
                                      style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${widget.ride.seats} Seats Available',
                                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${widget.ride.price.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text('Route Information', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildRouteInfo(),
                    const SizedBox(height: 32),
                    Text('Ride Preferences', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.ride.noAlcohol) _buildPrefChip(Icons.no_drinks_rounded, 'No Alcohol'),
                        if (widget.ride.noSmoking) _buildPrefChip(Icons.smoke_free_rounded, 'No Smoking'),
                        if (widget.ride.noPets) _buildPrefChip(Icons.pets_rounded, 'No Pets'),
                        if (widget.ride.noLuggage) _buildPrefChip(Icons.no_backpack_rounded, 'No Luggage'),
                        if (!widget.ride.noAlcohol && !widget.ride.noSmoking && !widget.ride.noPets && !widget.ride.noLuggage)
                          Text('No specific preferences set', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text('Host Profile', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildHostInfo(),
                    if (widget.ride.note.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Text('Trip Notes', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildNoteSection(),
                    ],
                    if (widget.ride.status == RideStatus.completed && !_isHost && _requestStatus == RideRequestStatus.accepted) ...[
                      const SizedBox(height: 32),
                      _buildFeedbackSection(),
                    ],
                    const SizedBox(height: 40),
                    if (_isHost)
                      Column(
                        children: [
                          if (widget.ride.status == RideStatus.open || widget.ride.status == RideStatus.booked)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '';
                                  Provider.of<RideProvider>(context, listen: false).updateRideStatus(widget.ride.id, RideStatus.ongoing, userId);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text('Start Trip', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          if (widget.ride.status == RideStatus.ongoing)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '';
                                  Provider.of<RideProvider>(context, listen: false).updateRideStatus(widget.ride.id, RideStatus.completed, userId);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text('Complete Trip', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(rideId: widget.ride.id, title: 'Trip Group Chat'))),
                                  icon: const Icon(Icons.group_rounded),
                                  label: const Text('Group Chat'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _isLoadingStatus 
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                onPressed: _requestStatus == null ? _sendRideRequest : null,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  backgroundColor: _getStatusColor(_requestStatus),
                                  elevation: 8,
                                  shadowColor: _getStatusColor(_requestStatus).withOpacity(0.4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: Text(
                                  _getRequestButtonText(), 
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                                ),
                              ),
                          ),
                          const SizedBox(width: 16),
                          _buildSafeSOSButton(),
                        ],
                      ),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),
          
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                _mapController.move(_currentPosition ?? start, 15);
              },
              child: const Icon(Icons.my_location_rounded, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(RideRequestStatus? status) {
    if (status == null) return AppColors.primary;
    switch (status) {
      case RideRequestStatus.pending: return Colors.orange;
      case RideRequestStatus.accepted: return Colors.green;
      case RideRequestStatus.rejected: return Colors.red;
      case RideRequestStatus.cancelled: return Colors.grey;
    }
  }

  String _getRequestButtonText() {
    if (_requestStatus == null) return 'Request to Join';
    switch (_requestStatus!) {
      case RideRequestStatus.pending: return 'Request Pending';
      case RideRequestStatus.accepted: return 'Accepted';
      case RideRequestStatus.rejected: return 'Rejected';
      case RideRequestStatus.cancelled: return 'Cancelled';
    }
  }

  Widget _buildSafeSOSButton() {
     return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
        onPressed: _triggerSOS,
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Row(
      children: [
        Column(
          children: [
            const Icon(Icons.circle_outlined, size: 16, color: AppColors.primary),
            Container(width: 2, height: 40, color: Colors.grey.shade200),
            const Icon(Icons.location_on_rounded, size: 16, color: AppColors.secondary),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.ride.from.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 36),
              Text(widget.ride.to.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHostInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(widget.ride.hostName[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.ride.hostName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Text('Verified Host • 4.8 ★', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

    );
  }

  Widget _buildFeedbackSection() {
     return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.rate_review_rounded, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            _hasSubmittedFeedback ? 'Thank you for your feedback!' : 'How was your trip?',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _hasSubmittedFeedback 
              ? 'Your review helps us maintain a great community.'
              : 'Share your experience to help others in the community.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (!_hasSubmittedFeedback)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showFeedbackDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Rate Your Experience', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Trip Feedback'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate the host and overall experience'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.orange,
                    size: 32,
                  ),
                  onPressed: () => setDialogState(() => rating = index + 1.0),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final feedbackProvider = Provider.of<FeedbackProvider>(context, listen: false);
                
                final feedback = FeedbackEntity(
                  id: '',
                  rideId: widget.ride.id,
                  hostId: widget.ride.hostId,
                  hostName: widget.ride.hostName,
                  passengerId: auth.currentUser!.id,
                  passengerName: auth.currentUser!.name,
                  rating: rating,
                  comment: commentController.text.trim(),
                  createdAt: DateTime.now(),
                );

                final success = await feedbackProvider.submitFeedback(feedback);
                if (success && mounted) {
                  setState(() => _hasSubmittedFeedback = true);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback submitted successfully!'))
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Note from Host', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        Text(
          widget.ride.note,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPrefChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
