import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_share_app/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminRideDetailPage extends StatefulWidget {
  final Map<String, dynamic> rideData;
  final String rideId;

  const AdminRideDetailPage({super.key, required this.rideData, required this.rideId});

  @override
  State<AdminRideDetailPage> createState() => _AdminRideDetailPageState();
}

class _AdminRideDetailPageState extends State<AdminRideDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _deleteRide() async {
     bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ride?'),
        content: const Text('This will permanently delete the ride and cancel all bookings.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete Forever')
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('rides').doc(widget.rideId).delete();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride deleted successfully')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.rideData;
    final dateTime = (data['dateTime'] as Timestamp).toDate();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Ride Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
            onPressed: _deleteRide,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(data['status'] ?? 'open'),
            const SizedBox(height: 24),
            _buildSectionHeader('Route Information'),
            _buildInfoCard([
              _buildRow(Icons.radio_button_checked, 'From', data['from']['name']),
              const SizedBox(height: 16),
              _buildRow(Icons.location_on, 'To', data['to']['name']),
              const SizedBox(height: 16),
              _buildRow(Icons.calendar_today, 'Date', DateFormat('EEE, MMM d, y').format(dateTime)),
              const SizedBox(height: 16),
              _buildRow(Icons.access_time, 'Time', DateFormat('h:mm a').format(dateTime)),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('Host Details'),
             _buildInfoCard([
              _buildRow(Icons.person, 'Name', data['hostName'] ?? 'Unknown'),
              const SizedBox(height: 16),
              _buildRow(Icons.email, 'Host ID', data['hostId'] ?? 'N/A'), // In real app, fetch email
            ]),
             const SizedBox(height: 24),
            _buildSectionHeader('Vehicle & Pricing'),
            _buildInfoCard([
              _buildRow(Icons.directions_car, 'Vehicle Type', (data['vehicleType'] ?? 'car').toString().toUpperCase()),
              const SizedBox(height: 16),
              _buildRow(Icons.event_seat, 'Seats Available', '${data['seats'] ?? 0}'),
              const SizedBox(height: 16),
              _buildRow(Icons.attach_money, 'Price', '₹${data['price'] ?? 0}'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    Color color;
    switch (status) {
      case 'open': color = Colors.green; break;
      case 'booked': color = Colors.orange; break;
      case 'ongoing': color = Colors.blue; break;
      case 'completed': color = Colors.grey; break;
      default: color = Colors.black;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text('CURRENT STATUS', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 10)),
      ],
    );
  }
}
