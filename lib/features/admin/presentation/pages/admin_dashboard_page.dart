import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Rides'),
              Tab(text: 'Users'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRidesTab(),
            _buildUsersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('rides').orderBy('dateTime', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error loading rides'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final rideId = docs[index].id;
            final hostName = data['hostName'] ?? 'Unknown';
            final status = data['status'] ?? 'open';
            
            return ListTile(
              title: Text('$hostName - $status'),
              subtitle: Text('${data['from']['name']} -> ${data['to']['name']}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteRide(rideId),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUsersTab() {
     // For now, listing users isn't fully set up in Auth Repo to sync to Firestore 'users' collection 
     // unless we implemented that trigger. 
     // We will just show a placeholder or list from 'rides' unique hostIds if possible, 
     // but let's assume we want to query a 'users' collection if it existed.
     // For this iteration, I'll display a placeholder explained.
     return const Center(
       child: Text('User Management coming in next update.\nRequires "users" collection sync.'),
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
