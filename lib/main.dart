import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tindart/auth/auth_service.dart';
import 'package:tindart/auth/sign_in_screen.dart';
import 'package:tindart/comments/comments_service.dart';
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
// Set via --dart-define=USE_FIREBASE_EMULATOR=true
const bool useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Connect to Firebase emulator for testing
  if (useEmulator) {
    // Android emulator uses 10.0.2.2 to reach host, iOS uses localhost
    final host = defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
    debugPrint('🔧 Emulator mode: connecting to $host');
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
    // Auto sign-in with test user for screenshots (with retry)
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        debugPrint('🔧 Sign-in attempt $attempt...');
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'testpassword123',
        );
        debugPrint('🔧 Sign-in successful!');
        // Mark user as onboarded in SharedPreferences (used by AuthService)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarded', true);
        break;
      } catch (e) {
        debugPrint('🔧 Sign-in attempt $attempt failed: $e');
        if (attempt < 3) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
  }

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
  Locator.add<CommentsService>(
    CommentsService(auth: auth, firestore: firestore),
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router);
  }
}

// Test comment
