import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class AdminVerificationDetailPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const AdminVerificationDetailPage({super.key, required this.userId, required this.userData});

  @override
  State<AdminVerificationDetailPage> createState() => _AdminVerificationDetailPageState();
}

class _AdminVerificationDetailPageState extends State<AdminVerificationDetailPage> {
  bool _isLoading = false;

  Future<void> _updateStatus(String status, {String? licenseStatus}) async {
    setState(() => _isLoading = true);
    try {
      final updates = <String, dynamic>{
        'verificationStatus': status,
      };
      if (licenseStatus != null) {
        updates['licenseStatus'] = licenseStatus;
      }
      
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update(updates);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User $status')));
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
         setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userData;
    
    ImageProvider? selfieProvider;
    if (user['selfieBase64'] != null) {
      try {
        selfieProvider = MemoryImage(base64Decode(user['selfieBase64']));
      } catch (e) {
        // Fallback or ignore
      }
    } else if (user['selfieUrl'] != null) {
      selfieProvider = NetworkImage(user['selfieUrl']);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Verify User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                   CircleAvatar(
                    radius: 50,
                    backgroundImage: selfieProvider,
                    child: selfieProvider == null ? const Icon(Icons.person, size: 50) : null,
                   ),
                   const SizedBox(height: 12),
                   Text(user['name'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                   Text(user['email'] ?? '', style: const TextStyle(color: Colors.grey)),
                   Text(user['phone'] ?? '', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Identity Document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildImagePreview(user['identityDocBase64'] ?? user['identityDocUrl'], 'Identity Document'),
            
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('License Status: ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  (user['licenseStatus'] ?? 'none').toString().toUpperCase(), 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: user['licenseStatus'] == 'approved' ? Colors.green : Colors.orange
                  )
                ),
              ],
            ),
            if (user['licenseBase64'] != null || user['licenseUrl'] != null) ...[
               const SizedBox(height: 8),
               _buildImagePreview(user['licenseBase64'] ?? user['licenseUrl'], 'Driving License'),
            ],

            const SizedBox(height: 40),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus('rejected', licenseStatus: 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('REJECT'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus('approved', licenseStatus: user['licenseUrl'] != null ? 'approved' : 'none'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('APPROVE'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(String? source, String label) {
    if (source == null) return Text('No $label uploaded');
    
    Widget imageWidget;
    if (source.startsWith('http')) {
      imageWidget = Image.network(source, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Center(child: Icon(Icons.broken_image)));
    } else {
      try {
        imageWidget = Image.memory(base64Decode(source), fit: BoxFit.cover, errorBuilder: (c,e,s) => const Center(child: Icon(Icons.broken_image)));
      } catch (e) {
        imageWidget = const Center(child: Text('Invalid Image Data'));
      }
    }

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageWidget,
      ),
    );
  }
}
