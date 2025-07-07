import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tindart/auth/auth_service.dart';
import 'package:tindart/auth/sign_in_screen.dart';
import 'package:tindart/firebase_options.dart';
import 'package:tindart/home_screen.dart';
import 'package:tindart/onboarding/onboarding_screen.dart';
import 'package:tindart/onboarding/privacy_policy_screen.dart';
import 'package:tindart/users/profile_screen.dart';
import 'package:tindart/users/users_service.dart';
import 'package:tindart/utils/locator.dart';

final _router = GoRouter(
  initialLocation:
      locate<AuthService>().currentUserId == null ? '/signin' : '/',
  routes: [
    GoRoute(
      name: 'home',
      path: '/',
      builder: (context, state) => const HomeScreen(),
      redirect: (BuildContext context, GoRouterState state) async {
        bool onboarded = await locate<AuthService>().userHasOnboarded;
        if (!onboarded) {
          return '/onboarding-screen';
        } else {
          return null;
        }
      },
    ),
    GoRoute(
      name: 'signin',
      path: '/signin',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      name: 'onboarding-screen',
      path: '/onboarding-screen',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      name: 'privacy-policy',
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      name: 'profile',
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Setup the data layer of the "data layer architecture"
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  // The services make up the repositories layer of the "data layer architecture"
  Locator.add<AuthService>(AuthService(auth: auth, firestore: firestore));
  Locator.add<UsersService>(UsersService(auth: auth, firestore: firestore));

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router);
  }
}
