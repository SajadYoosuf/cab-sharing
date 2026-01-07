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
    final inputEmail = _emailController.text.trim();
    final inputPass = _passwordController.text.trim();

    // 1. Support hardcoded admin shortcut
    if ((inputEmail == 'admin' || inputEmail == 'admin@ecoride.com') && inputPass == 'admin123') {
       const adminEmail = 'admin@ecoride.com';
       const adminPass = 'admin123';
       bool success = await authProvider.login(adminEmail, adminPass);
       
       if (!success) {
         // Fallback A: Manual Firestore check (bypass auth issues)
         try {
           final snapshot = await FirebaseFirestore.instance
               .collection('users')
               .where('email', isEqualTo: 'admin@ecoride.com')
               .limit(1).get();

           if (snapshot.docs.isNotEmpty) {
             final doc = snapshot.docs.first;
             if (doc.data()['role'] == 'admin') {
                final adminUser = UserEntity.fromMap({...doc.data(), 'id': doc.id});
                await Provider.of<AuthProvider>(context, listen: false).setManualUser(adminUser);
                if (mounted) {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminDashboardPage()), (r) => false);
                }
                return;
             }
           }
         } catch (e) { print('Manual check failed: $e'); }

         // Fallback B: Attempt auto-registration
         final registerSuccess = await authProvider.register('Administrator', adminEmail, adminPass);
         if (registerSuccess) {
            success = true;
         } else {
            final error = authProvider.error ?? '';
            if (mounted) {
               setState(() {
                 _errorMessage = error.contains('already registered') ? 'Incorrect password for existing admin.' : error;
                 _isLoading = false;
               });
            }
            return;
         }
       }

       if (success) {
         // Update/Ensure role
         try {
            await FirebaseFirestore.instance.collection('users').doc(authProvider.currentUser!.id).set({
              'role': 'admin',
              'email': adminEmail,
              'name': 'Administrator',
              'verificationStatus': 'approved',
            }, SetOptions(merge: true));
            await authProvider.checkAuthStatus();
         } catch (e) { print('Role update failed: $e'); }

         if (mounted) {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminDashboardPage()), (r) => false);
         }
       }
    } else {
       // 2. Regular Admin Login
       final success = await authProvider.login(inputEmail, inputPass);
       if (success) {
         final user = authProvider.currentUser;
         if (user != null && user.role == 'admin') {
            if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminDashboardPage()), (r) => false);
         } else {
            if (mounted) {
               setState(() { _errorMessage = 'Access Denied: Not an admin account'; _isLoading = false; });
               authProvider.logout();
            }
         }
       } else {
         if (mounted) setState(() { _errorMessage = authProvider.error ?? 'Login Failed'; _isLoading = false; });
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
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              ),
              
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                   ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                  // Debug/Rescue Options
                  ExpansionTile(
                    title: const Text('Developer Options', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    children: [
                       Padding(
                         padding: const EdgeInsets.all(8.0),
                         child: Column(
                           children: [
                             const Text('Force Login with UID:', style: TextStyle(fontSize: 12)),
                             TextField(
                               decoration: const InputDecoration(
                                 hintText: 'e.g. go6e3xQJ7kCl1Opj0T0b',
                                 isDense: true,
                                 border: OutlineInputBorder(),
                               ),
                               onSubmitted: (uid) async {
                                  if (uid.isEmpty) return;
                                  setState(() => _isLoading = true);
                                  _bypassWithUid(uid);
                               },
                             ),
                             const SizedBox(height: 12),
                             const Divider(),
                             const SizedBox(height: 8),
                             const Text('Known Accounts:', style: TextStyle(fontSize: 10, color: Colors.grey)),
                             const SizedBox(height: 8),
                             SizedBox(
                               width: double.infinity,
                               child: OutlinedButton(
                                 onPressed: () {
                                    // Pre-fill and submit automatically for the requested account
                                    final uid = 'go6e3xQJ7kCl1Opj0T0b';
                                    setState(() => _isLoading = true);
                                    _bypassWithUid(uid);
                                 },
                                 child: const Text('Rescue Admin (go6e3x...)'),
                               ),
                             ),
                           ],
                         ),
                       )
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _bypassWithUid(String uid) async {
      try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (doc.exists) {
            final user = UserEntity.fromMap({...doc.data()!, 'id': doc.id});
            if (user.role == 'admin') {
              if (mounted) {
                 await Provider.of<AuthProvider>(context, listen: false).setManualUser(user);
                 Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
                    (route) => false,
                 );
              }
            } else {
              if (mounted) setState(() => _errorMessage = 'User found but ROLE is not admin');
            }
          } else {
            if (mounted) setState(() => _errorMessage = 'No user found with this UID');
          }
      } catch (e) {
          if (mounted) setState(() => _errorMessage = 'Bypass Error: $e');
      } finally {
          if (mounted) setState(() => _isLoading = false);
      }
  }
}
