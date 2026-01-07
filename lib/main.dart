import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/ride/data/repositories/firebase_ride_repository.dart';
import 'features/ride/presentation/providers/ride_provider.dart';
import 'features/home/presentation/pages/main_navigation_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'features/ride/presentation/pages/create_ride_page.dart';
import 'features/ride/presentation/pages/find_ride_page.dart';
import 'features/chat/data/repositories/firebase_chat_repository.dart';
import 'package:ride_share_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:ride_share_app/features/ride/domain/repositories/ride_repository.dart';
import 'package:ride_share_app/features/ride/domain/repositories/ride_request_repository.dart';
import 'package:ride_share_app/features/auth/presentation/providers/verification_provider.dart';
import 'package:ride_share_app/features/auth/presentation/pages/phone_verification_page.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/admin/presentation/pages/admin_dashboard_page.dart';
import 'features/ride/data/repositories/firebase_ride_request_repository.dart';
import 'features/ride/presentation/providers/ride_request_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RideShareApp());
}

class RideShareApp extends StatelessWidget {
  const RideShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(FirebaseAuthRepository())),
        ChangeNotifierProvider(create: (_) => RideProvider(FirebaseRideRepository())), // Removed unavailable getIt
        ChangeNotifierProvider(create: (_) => RideRequestProvider(
          FirebaseRideRequestRepository(),
          FirebaseRideRepository()
        )),
        ChangeNotifierProvider(create: (_) => ChatProvider(
          FirebaseChatRepository(),
        )),
        ChangeNotifierProvider(create: (_) => VerificationProvider()),
      ],
      child: MaterialApp(
        title: 'RideShare Eco',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashPage(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/phone_verification': (context) => const PhoneVerificationPage(), // Added PhoneVerificationPage route
          '/home': (context) => const MainNavigationPage(),
          '/create_ride': (context) => const CreateRidePage(),
          '/find_ride': (context) => const FindRidePage(),
          '/admin_dashboard': (context) => const AdminDashboardPage(),
        },
      ),
    );
  }
}
