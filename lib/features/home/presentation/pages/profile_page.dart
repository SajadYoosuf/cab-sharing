import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ride/presentation/providers/ride_provider.dart';
import 'package:ride_share_app/features/auth/domain/entities/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'account_settings_page.dart';
import 'notifications_page.dart';
import 'ride_history_page.dart';
import 'about_page.dart';
import 'vehicle_settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final rideProvider = Provider.of<RideProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Account', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.id).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final currentUser = UserEntity.fromMap({...userData, 'id': user.id});

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildProfileHeader(currentUser),
                const SizedBox(height: 32),
                _buildVerificationSection(currentUser),
                const SizedBox(height: 32),
                _buildMenuSection([
                  _buildMenuItem(Icons.directions_car_filled_outlined, 'Vehicle Settings', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleSettingsPage()));
                  }),
                  _buildMenuItem(Icons.settings_outlined, 'Account Settings', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountSettingsPage()));
                  }),
                  _buildMenuItem(Icons.notifications_none_rounded, 'Notifications', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
                  }),
                  _buildMenuItem(Icons.history_rounded, 'Ride History', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RideHistoryPage()));
                  }),
                  _buildMenuItem(Icons.info_outline_rounded, 'About EcoRide', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
                  }),
                ]),
                const SizedBox(height: 32),
                _buildDocumentsSection(currentUser),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _showLogoutDialog(context, authProvider),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.error.withOpacity(0.1))),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildProfileHeader(UserEntity user) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
          ),
          child: CircleAvatar(
            radius: 54,
            backgroundColor: AppColors.primary,
            backgroundImage: user.selfieBase64 != null 
                ? MemoryImage(base64Decode(user.selfieBase64!)) as ImageProvider
                : (user.selfieUrl != null ? NetworkImage(user.selfieUrl!) as ImageProvider : null),
            child: (user.selfieBase64 == null && user.selfieUrl == null) ? const Icon(Icons.person_rounded, size: 64, color: Colors.white) : null,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          user.name,
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.email_outlined, user.email),
        if (user.phone != null) ...[
          const SizedBox(height: 4),
          _buildInfoRow(Icons.phone_outlined, user.phone!),
        ],
      ],
    );
  }

  Widget _buildVerificationSection(UserEntity user) {
     return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(user.verificationStatus).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              user.verificationStatus == 'approved' ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
              color: _getStatusColor(user.verificationStatus),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification Status',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                Text(
                  user.verificationStatus.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: _getStatusColor(user.verificationStatus)
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(UserEntity user) {
    bool hasIdentity = user.identityDocBase64 != null || user.identityDocUrl != null;
    bool hasLicense = user.licenseBase64 != null || user.licenseUrl != null;
    
    if (!hasIdentity && !hasLicense) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text('Your Documents', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              if (hasIdentity)
                _buildDocTile('Identity Document', user.identityDocBase64 ?? user.identityDocUrl!),
              if (hasIdentity && hasLicense)
                const Divider(height: 32),
              if (hasLicense)
                _buildDocTile('Driving License', user.licenseBase64 ?? user.licenseUrl!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocTile(String label, String source) {
    Widget imageWidget;
    if (source.startsWith('http')) {
       imageWidget = Image.network(source, width: 60, height: 40, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image));
    } else {
       try {
         imageWidget = Image.memory(base64Decode(source), width: 60, height: 40, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image));
       } catch (e) {
         imageWidget = const Icon(Icons.error);
       }
    }

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageWidget,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
