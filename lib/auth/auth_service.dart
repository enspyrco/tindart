import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore {
    // When a User object is emitted by the FirebaseAuth's onAuthStateChanges
    // stream we create a subscription to the firestore, which is cancelled on
    // sign out to avoid listening to the firestore while signed out.
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        if (profileStreamSubscription != null) {
          profileStreamSubscription!.cancel();
        }

        profileStreamSubscription = _firestore
            .doc('profiles/${user.uid}')
            .snapshots()
            .map<Map<String, Object?>?>((ref) {
          return ref.data();
        }).listen((profile) {
          if (profile != null) {
            _userSubject.add(profile);
          }
        });
      }
    });
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  final _userSubject = BehaviorSubject<Map<String, Object?>>.seeded({});
  StreamSubscription<Map<String, Object?>?>? profileStreamSubscription;

  Stream<Map<String, Object?>?> get profileDocStream => _userSubject.stream;

  String? get currentUserId {
    return _auth.currentUser?.uid;
  }

  /// Check shared prefs for onboarding status.
  Future<bool> get userHasOnboarded async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarded') ?? false;
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      final _ = await FirebaseAuth.instance.signInWithPopup(googleProvider);

      // Or use signInWithRedirect
      // return await FirebaseAuth.instance.signInWithRedirect(googleProvider);
    } else {
      // serverClientId is required for Android to complete OAuth with 2FA
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId:
            '498580446520-1k97o45ftqc7htv00ahio8jmrmqcfp6q.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        throw Exception('Google sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final _ = await _auth.signInWithCredential(credential);
    }
  }

  Future<void> signInWithApple() async {
    final appleProvider = AppleAuthProvider();
    appleProvider.addScope('email');
    appleProvider.addScope('name');

    if (kIsWeb) {
      final _ = await FirebaseAuth.instance.signInWithPopup(appleProvider);
    } else {
      final _ = await FirebaseAuth.instance.signInWithProvider(appleProvider);
    }
  }

  Future<void> signOut() async {
    await profileStreamSubscription?.cancel();
    return _auth.signOut();
  }

  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }

  /// Get list of provider IDs linked to current user (e.g., 'google.com', 'apple.com')
  List<String> getLinkedProviders() {
    final user = _auth.currentUser;
    if (user == null) return [];
    return user.providerData.map((info) => info.providerId).toList();
  }

  bool isGoogleLinked() => getLinkedProviders().contains('google.com');
  bool isAppleLinked() => getLinkedProviders().contains('apple.com');

  /// Link Google account to current user
  Future<void> linkWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');

    if (kIsWeb) {
      // On web, use linkWithPopup and capture result to avoid JS interop issues
      final googleProvider = GoogleAuthProvider();
      final result = await user.linkWithPopup(googleProvider);
      if (result.user == null) {
        throw Exception('Failed to link Google account');
      }
    } else {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId:
            '498580446520-1k97o45ftqc7htv00ahio8jmrmqcfp6q.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.linkWithCredential(credential);
    }
    // Reload user to refresh provider data
    await _auth.currentUser?.reload();
  }

  /// Link Apple account to current user
  Future<void> linkWithApple() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');

    final appleProvider = AppleAuthProvider();
    appleProvider.addScope('email');
    appleProvider.addScope('name');

    if (kIsWeb) {
      // On web, use linkWithPopup and capture result to avoid JS interop issues
      final result = await user.linkWithPopup(appleProvider);
      if (result.user == null) {
        throw Exception('Failed to link Apple account');
      }
    } else {
      await user.linkWithProvider(appleProvider);
    }
    // Reload user to refresh provider data
    await _auth.currentUser?.reload();
  }

  /// Unlink a provider from current user
  Future<void> unlinkProvider(String providerId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');

    // Don't allow unlinking if it's the only provider
    if (user.providerData.length <= 1) {
      throw Exception('Cannot unlink the only sign-in method');
    }

    await user.unlink(providerId);
    await _auth.currentUser?.reload();
  }
}
