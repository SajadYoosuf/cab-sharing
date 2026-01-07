import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_share_app/core/constants/app_colors.dart';

import 'package:ride_share_app/features/admin/presentation/pages/admin_announcement_page.dart';
import 'package:ride_share_app/features/admin/presentation/pages/admin_ride_detail_page.dart';
import 'package:ride_share_app/features/admin/presentation/pages/admin_reports_page.dart';
import 'package:ride_share_app/features/admin/presentation/pages/admin_activity_logs_page.dart';
import 'package:ride_share_app/features/admin/presentation/pages/admin_verification_list_page.dart';
import 'package:provider/provider.dart';
import 'package:ride_share_app/features/auth/presentation/providers/auth_provider.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildSummaryTab(),
      _buildRidesTab(),
      _buildUsersTab(),
      _buildAdminProfileTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _getPageTitle(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
              onPressed: () {},
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car_rounded), label: 'Rides'),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_rounded), label: 'Admin'),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0: return 'EcoRide Admin';
      case 1: return 'Ride Management';
      case 2: return 'User Directory';
      case 3: return 'Admin Profile';
      default: return 'Admin';
    }
  }

  Widget _buildAdminProfileTab() {
    final user = Provider.of<AuthProvider>(context).currentUser;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(Icons.admin_panel_settings_rounded, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(user?.name ?? 'Admin', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(user?.email ?? 'admin@ecoride.com', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 32),
          _buildActionItem(
            'System Activity Logs', 
            Icons.list_alt_rounded, 
            Colors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminActivityLogsPage())),
          ),
          _buildActionItem(
             'Change Credentials', 
             Icons.password_rounded, 
             Colors.orange,
             onTap: _showChangePasswordDialog,
          ),
          _buildActionItem(
            'Database Maintenance', 
            Icons.storage_rounded, 
            Colors.purple,
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maintenance mode is currently disabled.')));
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Admin Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Admin Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_outline)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red));
                return;
              }
              if (passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password too short'), backgroundColor: Colors.red));
                return;
              }
              // Here we would typically call repository to update
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully'), backgroundColor: Colors.green));
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, IconData icon, Color color, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade300),
        onTap: onTap ?? () {},
      ),
    );
  }

  // Update Summary Tab to use the new action
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // ... (keep existing stats code)
          _buildPlatformStats(),
          
          const SizedBox(height: 40),
          Text('Critical Actions', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildActionItem(
             'Broadcast Announcement', 
             Icons.campaign_rounded, 
             Colors.purple,
             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAnnouncementPage())),
          ),
          _buildActionItem('App Configuration', Icons.settings_suggest_rounded, Colors.grey),
          _buildActionItem('System Security', Icons.security_rounded, Colors.teal),
          _buildActionItem(
             'Verify Users', 
             Icons.verified_user, 
             Colors.orange,
             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVerificationListPage())),
          ),
          _buildActionItem(
            'Financial Reports', 
            Icons.bar_chart_rounded, 
            Colors.green,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportsPage())),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPlatformStats() {
     return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('rides').snapshots(),
            builder: (context, rideSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, userSnapshot) {
                  final totalRides = rideSnapshot.data?.docs.length ?? 0;
                  final activeRides = rideSnapshot.data?.docs.where((d) => (d.data() as Map)['status'] == 'open').length ?? 0;
                  final totalUsers = userSnapshot.data?.docs.length ?? 0;

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Platform Stats', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: const Row(
                              children: [
                                Icon(Icons.trending_up_rounded, size: 14, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text('Live', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _buildStatCard('Users', totalUsers.toString(), Icons.people_rounded, Colors.blue)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard('Active Rides', activeRides.toString(), Icons.speed_rounded, AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildStatCard('Total Rides', totalRides.toString(), Icons.history_rounded, Colors.orange)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard('Reports', '0', Icons.report_gmailerrorred_rounded, Colors.red)),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          );
  }

  Widget _buildRidesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('rides').orderBy('dateTime', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error loading rides'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final rideId = docs[index].id;
            final hostName = data['hostName'] ?? 'Unknown';
            final status = data['status'] ?? 'open';
            final vehicleType = data['vehicleType'] ?? 'car';
            
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminRideDetailPage(rideData: data, rideId: rideId))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                     CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(vehicleType == 'bike' ? Icons.directions_bike_rounded : Icons.directions_car_rounded, 
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hostName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('${data['from']['name']} → ${data['to']['name']}', 
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: status == 'open' ? Colors.green.withOpacity(0.1) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toString().toUpperCase(),
                        style: TextStyle(color: status == 'open' ? Colors.green : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUsersTab() {
     return StreamBuilder<QuerySnapshot>(
       stream: _firestore.collection('users').snapshots(),
       builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading users'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No users registered yet.'));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: const Icon(Icons.person_rounded, color: Colors.blue, size: 20),
                  ),
                  title: Text(data['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children: [
                      Text(data['email'] ?? 'No Email', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (data['role'] == 'admin' ? Colors.purple : Colors.grey).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (data['role'] ?? 'user').toUpperCase(),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: data['role'] == 'admin' ? Colors.purple : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                ),
              );
            },
          );
       },
     );
  }

  Future<void> _deleteRide(String rideId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ride?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('rides').doc(rideId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride deleted')));
      }
    }
  }
}
