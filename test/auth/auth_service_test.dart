import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindart/auth/auth_service.dart';

void main() {
  group('AuthService', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore fakeFirestore;
    late AuthService authService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      fakeFirestore = FakeFirebaseFirestore();
    });

    group('currentUserId', () {
      test('returns null when no user is signed in', () {
        authService = AuthService(auth: mockAuth, firestore: fakeFirestore);

        expect(authService.currentUserId, isNull);
      });

      test('returns uid when user is signed in', () async {
        final user = MockUser(uid: 'test-uid-123');
        mockAuth = MockFirebaseAuth(mockUser: user, signedIn: true);
        authService = AuthService(auth: mockAuth, firestore: fakeFirestore);

        expect(authService.currentUserId, equals('test-uid-123'));
      });
    });

    group('profileDocStream', () {
      test('emits empty map initially', () async {
        authService = AuthService(auth: mockAuth, firestore: fakeFirestore);

        expect(
          authService.profileDocStream,
          emits(equals({})),
        );
      });

      test('emits profile data when user signs in and profile exists',
          () async {
        final user = MockUser(uid: 'test-uid-123');
        mockAuth = MockFirebaseAuth(mockUser: user, signedIn: true);

        // Set up profile document before creating service
        await fakeFirestore.doc('profiles/test-uid-123').set({
          'name': 'Test User',
          'email': 'test@example.com',
        });

        authService = AuthService(auth: mockAuth, firestore: fakeFirestore);

        // Give time for the auth state listener to set up the firestore listener
        await Future.delayed(Duration(milliseconds: 100));

        expect(
          authService.profileDocStream,
          emits(containsPair('name', 'Test User')),
        );
      });
    });

    group('signOut', () {
      test('signs out the user', () async {
        final user = MockUser(uid: 'test-uid-123');
        mockAuth = MockFirebaseAuth(mockUser: user, signedIn: true);
        authService = AuthService(auth: mockAuth, firestore: fakeFirestore);

        expect(mockAuth.currentUser, isNotNull);

        await authService.signOut();

        expect(mockAuth.currentUser, isNull);
      });
    });

    group('deleteAccount', () {
      test('deletes the current user', () async {
        final user = MockUser(uid: 'test-uid-123');
        mockAuth = MockFirebaseAuth(mockUser: user, signedIn: true);
        authService = AuthService(auth: mockAuth, firestore: fakeFirestore);

        // Should not throw
        await authService.deleteAccount();
      });

      test('does nothing when no user is signed in', () async {
        authService = AuthService(auth: mockAuth, firestore: fakeFirestore);

        // Should not throw when no user
        await authService.deleteAccount();
      });
    });
  });
}
