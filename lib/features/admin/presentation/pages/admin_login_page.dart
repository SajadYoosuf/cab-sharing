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
    final inputEmail = _emailController.text.trim();
    final inputPass = _passwordController.text.trim();

    // Support both 'admin' and 'admin@ecoride.com' as shortcuts
    if ((inputEmail == 'admin' || inputEmail == 'admin@ecoride.com') && 
        inputPass == 'admin123') {
       
       const adminEmail = 'admin@ecoride.com';
       const adminPass = 'admin123';
       
       bool success = await authProvider.login(adminEmail, adminPass);
       
       if (!success) {
         // Fallback: Check Firestore directly for existing admin user (Bypass for Recaptcha/Auth issues)
         try {
           final snapshot = await FirebaseFirestore.instance
               .collection('users')
               .where('email', isEqualTo: 'admin@ecoride.com')
               .limit(1)
               .get();

               if (snapshot.docs.isNotEmpty) {
                 final doc = snapshot.docs.first;
                 if (doc.data()['role'] == 'admin') {
                    // Found the admin doc! Force login.
                    final adminUser = UserEntity.fromMap({...doc.data(), 'id': doc.id});
                    await Provider.of<AuthProvider>(context, listen: false).setManualUser(adminUser);
                    
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
                        (route) => false,
                      );
                    }
                    return; // Stop here, we are logged in!
                 }
               }
             } catch (e) {
               print('Manual admin check failed: $e');
             }
         }
       }

       if (!success) {
         // Login failed and Manual Check failed.
         // Due to Firebase 'Email Enumeration Protection', we might receive 'invalid-credential'
         // for BOTH 'wrong password' and 'user not found'.
         // So, we blindly attempt to REGISTER the admin account now.
         
         final registerSuccess = await authProvider.register('Administrator', adminEmail, adminPass);
         
         if (registerSuccess) {
            // Registration worked! Proceed as if login worked.
            success = true;
         } else {
            // Registration failed too.
            // If it failed because "email already ready in use", then the original login failure 
            // was definitely a WRONG PASSWORD.
            final error = authProvider.error ?? '';
            if (error.contains('already registered') || error.contains('email-already-in-use')) {
               if (mounted) {
                  setState(() {
                    _errorMessage = 'Incorrect Admin Password. Account exists.';
                    _isLoading = false;
                  });
               }
            } else {
               // Some other error (network, weak password, etc)
               if (mounted) {
                  setState(() {
                    _errorMessage = error;
                    _isLoading = false;
                  });
               }
            }
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
