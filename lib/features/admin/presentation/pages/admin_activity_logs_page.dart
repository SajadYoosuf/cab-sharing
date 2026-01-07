import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ride_share_app/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class AdminActivityLogsPage extends StatelessWidget {
  const AdminActivityLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('System Activity Logs', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('rides').orderBy('dateTime', descending: true).limit(20).snapshots(),
        builder: (context, rideSnapshot) {
          if (!rideSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('announcements').orderBy('dateTime', descending: true).limit(10).snapshots(),
            builder: (context, announceSnapshot) {
               if (!announceSnapshot.hasData) return const Center(child: CircularProgressIndicator());

               final rides = rideSnapshot.data!.docs;
               final announcements = announceSnapshot.data!.docs;

               // Merge and sort
               final List<Map<String, dynamic>> logs = [];
               
               for (var doc in rides) {
                 final data = doc.data() as Map<String, dynamic>;
                 logs.add({
                   'type': 'ride',
                   'title': 'New Ride Created',
                   'subtitle': 'Host: ${data['hostName'] ?? 'Unknown'}',
                   'time': (data['dateTime'] as Timestamp).toDate(),
                   'icon': Icons.directions_car_rounded,
                   'color': Colors.blue
                 });
               }

               for (var doc in announcements) {
                 final data = doc.data() as Map<String, dynamic>;
                 logs.add({
                   'type': 'announcement',
                   'title': 'Announcement Broadcasted',
                   'subtitle': data['title'] ?? 'No Title',
                   'time': (data['dateTime'] as Timestamp).toDate(),
                   'icon': Icons.campaign_rounded,
                   'color': Colors.purple
                 });
               }
               
               // Mock System logs for "Activity"
               logs.add({
                 'type': 'system',
                 'title': 'System Backup',
                 'subtitle': 'Automated daily backup completed',
                 'time': DateTime.now().subtract(const Duration(hours: 4)),
                 'icon': Icons.storage_rounded,
                 'color': Colors.green
               });
                logs.add({
                 'type': 'login',
                 'title': 'Admin Login',
                 'subtitle': 'Administrator access granted',
                 'time': DateTime.now().subtract(const Duration(minutes: 30)),
                 'icon': Icons.shield_rounded,
                 'color': Colors.orange
               });

               logs.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

               return ListView.separated(
                 padding: const EdgeInsets.all(20),
                 itemCount: logs.length,
                 separatorBuilder: (context, index) => const SizedBox(height: 16),
                 itemBuilder: (context, index) {
                   final log = logs[index];
                   return _buildLogCard(log);
                 },
               );
            },
          );
        },
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (log['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(log['icon'] as IconData, color: log['color'], size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(log['subtitle'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          Text(
            _formatTime(log['time'] as DateTime),
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(time);
  }
}
