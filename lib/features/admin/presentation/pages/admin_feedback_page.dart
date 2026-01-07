import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:ride_share_app/features/admin/presentation/pages/admin_verification_detail_page.dart';
import 'package:ride_share_app/features/ride/presentation/providers/feedback_provider.dart';
import 'package:ride_share_app/features/ride/domain/entities/feedback_entity.dart';
import 'package:ride_share_app/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class AdminFeedbackPage extends StatelessWidget {
  const AdminFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final feedbackProvider = Provider.of<FeedbackProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Ride Feedback', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<FeedbackEntity>>(
        stream: feedbackProvider.getAllFeedbacks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final feedbacks = snapshot.data ?? [];
          if (feedbacks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No feedback submitted yet', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: feedbacks.length,
            itemBuilder: (context, index) {
              final feedback = feedbacks[index];
              return _buildFeedbackCard(context, feedback);
            },
          );
        },
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context, FeedbackEntity feedback) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildUserProfileTrigger(context, feedback.passengerId, feedback.passengerName, Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(feedback.passengerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Text('Passenger', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(feedback.hostName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Text('Host', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildUserProfileTrigger(context, feedback.hostId, feedback.hostName, Colors.orange),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (index) => Icon(
                  index < feedback.rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.orange,
                  size: 18,
                )),
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(feedback.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          if (feedback.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '"${feedback.comment}"',
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.textPrimary),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ride ID: ${feedback.rideId.substring(0, 8)}...',
                style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
              ),
               const Icon(Icons.verified_rounded, size: 14, color: Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileTrigger(BuildContext context, String userId, String name, Color color) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminVerificationDetailPage(userId: userId)),
      ),
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          String? photoUrl;
          String? selfieBase64;
          
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            photoUrl = data['selfieUrl'];
            selfieBase64 = data['selfieBase64'];
          }

          ImageProvider? image;
          if (selfieBase64 != null) {
            try {
              image = MemoryImage(base64Decode(selfieBase64));
            } catch (_) {}
          } else if (photoUrl != null) {
            image = NetworkImage(photoUrl);
          }

          return CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.1),
            backgroundImage: image,
            child: image == null 
              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: color, fontWeight: FontWeight.bold))
              : null,
          );
        },
      ),
    );
  }
}

