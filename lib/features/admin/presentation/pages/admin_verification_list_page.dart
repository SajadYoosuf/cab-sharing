import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ride_share_app/core/constants/app_colors.dart';
import 'package:ride_share_app/features/admin/presentation/pages/admin_verification_detail_page.dart';
import 'dart:convert';

class AdminVerificationListPage extends StatelessWidget {
  const AdminVerificationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pending Verifications'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query users where verificationStatus is pending
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('verificationStatus', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             print('Admin List Error: ${snapshot.error}'); // Debug print
             return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final docs = snapshot.data?.docs ?? [];
          
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                  const SizedBox(height: 16),
                  const Text('All caught up! No pending verifications.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final user = docs[index].data() as Map<String, dynamic>;
              final userId = docs[index].id;
              
              ImageProvider? selfieProvider;
              if (user['selfieBase64'] != null) {
                try {
                  selfieProvider = MemoryImage(base64Decode(user['selfieBase64']));
                } catch (e) {
                   // Ignore error
                }
              } else if (user['selfieUrl'] != null) {
                selfieProvider = NetworkImage(user['selfieUrl']);
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundImage: selfieProvider,
                    radius: 30,
                    child: selfieProvider == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(user['name'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Doc Type: ${user['docType'] ?? "N/A"}'),
                      if (user['licenseStatus'] == 'pending')
                         const Text('License: Pending', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminVerificationDetailPage(userId: userId, userData: user)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
