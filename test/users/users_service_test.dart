import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindart/users/users_service.dart';

void main() {
  group('UsersService', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore fakeFirestore;
    late UsersService usersService;
    late MockUser mockUser;

    setUp(() {
      mockUser = MockUser(uid: 'test-user-123');
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      fakeFirestore = FakeFirebaseFirestore();
      usersService = UsersService(
        auth: mockAuth,
        firestore: fakeFirestore,
      );
    });

    group('retrieveViewedImages', () {
      test('throws when user is not signed in', () async {
        mockAuth = MockFirebaseAuth(signedIn: false);
        usersService = UsersService(
          auth: mockAuth,
          firestore: fakeFirestore,
        );

        expect(
          () => usersService.retrieveViewedImages(),
          throwsA(equals('You must be signed in to access the database')),
        );
      });

      test('returns 0 when no preferences exist', () async {
        final count = await usersService.retrieveViewedImages();

        expect(count, equals(0));
      });

      test('returns count of liked images only', () async {
        await fakeFirestore.doc('preferences/test-user-123').set({
          'liked': ['img-1', 'img-2', 'img-3'],
        });

        final count = await usersService.retrieveViewedImages();

        expect(count, equals(3));
      });

      test('returns count of disliked images only', () async {
        await fakeFirestore.doc('preferences/test-user-123').set({
          'disliked': ['img-1', 'img-2'],
        });

        final count = await usersService.retrieveViewedImages();

        expect(count, equals(2));
      });

      test('returns combined count of liked and disliked', () async {
        await fakeFirestore.doc('preferences/test-user-123').set({
          'liked': ['img-1', 'img-2', 'img-3'],
          'disliked': ['img-4', 'img-5'],
        });

        final count = await usersService.retrieveViewedImages();

        expect(count, equals(5));
      });

      test('handles empty arrays', () async {
        await fakeFirestore.doc('preferences/test-user-123').set({
          'liked': [],
          'disliked': [],
        });

        final count = await usersService.retrieveViewedImages();

        expect(count, equals(0));
      });
    });

    group('getUserName', () {
      test('returns name from profile document', () async {
        await fakeFirestore.doc('profiles/test-user-123').set({
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        final name = await usersService.getUserName();

        expect(name, equals('John Doe'));
      });

      test('returns empty string when profile does not exist', () async {
        final name = await usersService.getUserName();

        expect(name, equals(''));
      });

      test('returns empty string when name field is missing', () async {
        await fakeFirestore.doc('profiles/test-user-123').set({
          'email': 'john@example.com',
        });

        final name = await usersService.getUserName();

        expect(name, equals(''));
      });

      test('returns empty string when name is null', () async {
        await fakeFirestore.doc('profiles/test-user-123').set({
          'name': null,
          'email': 'john@example.com',
        });

        final name = await usersService.getUserName();

        expect(name, equals(''));
      });
    });
  });
}
