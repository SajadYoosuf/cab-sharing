import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ride_share_app/features/auth/domain/entities/user_entity.dart';
import 'package:ride_share_app/features/auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/admin_auth_repository.dart';
import 'admin_dashboard_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repository = AdminAuthRepository();
  bool _isLoading = false;
  String _errorMessage = '';

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check for hardcoded credentials first
    if (_emailController.text.trim() == 'admin' && _passwordController.text.trim() == 'admin123') {
       // Perform real firebase auth with a reserved admin email
       const adminEmail = 'admin@ecoride.com';
       const adminPass = 'admin123'; // In a real app, this should be secure or managed via console
       
       bool success = await authProvider.login(adminEmail, adminPass);
       
       if (!success) {
         // If login fails, try to register this admin user (first run setup)
         if (authProvider.error != null && authProvider.error!.contains('user-not-found') || authProvider.error!.contains('No user found')) {
            success = await authProvider.register('Administrator', adminEmail, adminPass);
            // We need to enforce role update here if register doesn't do it or defaults to 'user'
            // But for now, let's rely on standard flow or assume we can update it manually or via another tool.
            // Ideally, we'd update Firestore role here:
            // await FirebaseFirestore.instance.collection('users').doc(authProvider.currentUser!.id).update({'role': 'admin'});
         }
       }

       if (success) {
         // CRITICAL: Ensure this user is marked as admin in Firestore
         // This fixes the permission issue where the user might exist but not have the 'admin' role
         try {
            await FirebaseFirestore.instance.collection('users').doc(authProvider.currentUser!.id).set({
              'role': 'admin',
              'email': adminEmail,
              'name': 'Administrator',
              'verificationStatus': 'approved', // Admins are auto-approved
            }, SetOptions(merge: true));
            
            // Reload user to get the new role content
            await authProvider.checkAuthStatus();
         } catch (e) {
            print('Error setting admin role: $e');
         }

         if (mounted) {
           Navigator.pushAndRemoveUntil(
             context,
             MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
             (route) => false,
           );
         }
       } else {
         if (mounted) {
           setState(() {
             _errorMessage = authProvider.error ?? 'Authentication failed';
             _isLoading = false;
           });
         }
       }
    } else {
      // Allow logging in with any other admin credentials if they exist
       final success = await authProvider.login(_emailController.text.trim(), _passwordController.text.trim());
       if (success) {
         final user = authProvider.currentUser;
         if (user != null && user.role == 'admin') {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
                (route) => false,
              );
            }
         } else {
            if (mounted) {
              setState(() {
                _errorMessage = 'Access Denied: Not an admin account';
                _isLoading = false;
              });
              authProvider.logout();
            }
         }
       } else {
         if (mounted) {
            setState(() {
              _errorMessage = authProvider.error ?? 'Login Failed';
              _isLoading = false;
            });
         }
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Admin Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _login,
                child: const Text('Login as Admin'),
              ),
          ],
        ),
      ),
    );
  }
}
