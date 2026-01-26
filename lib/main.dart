import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_share_app/core/theme/app_theme.dart';
import 'data/firebase_auth_repository.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/forgot_password_page.dart';
import 'data/firebase_ride_repository.dart';
import 'providers/ride_provider.dart';
import 'screens/main_navigation_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/create_ride_page.dart';
import 'screens/find_ride_page.dart';
import 'data/firebase_chat_repository.dart';
import 'package:ride_share_app/data/chat_repository.dart';
import 'package:ride_share_app/data/ride_repository.dart';
import 'package:ride_share_app/data/ride_request_repository.dart';
import 'package:ride_share_app/providers/verification_provider.dart';
import 'package:ride_share_app/screens/phone_verification_page.dart';
import 'providers/chat_provider.dart';
import 'screens/admin_dashboard_page.dart';
import 'data/firebase_ride_request_repository.dart';
import 'providers/ride_request_provider.dart';

import 'providers/feedback_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RideShareApp());
}

class RideShareApp extends StatelessWidget {
  const RideShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(FirebaseAuthRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => RideProvider(FirebaseRideRepository()),
        ), // Removed unavailable getIt
        ChangeNotifierProvider(
          create: (_) => RideRequestProvider(
            FirebaseRideRequestRepository(),
            FirebaseRideRepository(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(FirebaseChatRepository()),
        ),
        ChangeNotifierProvider(create: (_) => VerificationProvider()),
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
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
          '/phone_verification': (context) =>
              const PhoneVerificationPage(), // Added PhoneVerificationPage route
          '/home': (context) => const MainNavigationPage(),
          '/create_ride': (context) => const CreateRidePage(),
          '/find_ride': (context) => const FindRidePage(),
          '/admin_dashboard': (context) => const AdminDashboardPage(),
          '/forgot_password': (context) => const ForgotPasswordPage(),
        },
      ),
    );
  }
}
