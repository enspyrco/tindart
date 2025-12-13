import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindart/comments/comments_service.dart';

void main() {
  group('CommentsService', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore fakeFirestore;
    late CommentsService commentsService;
    late MockUser mockUser;

    setUp(() {
      mockUser = MockUser(uid: 'test-user-123');
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      fakeFirestore = FakeFirebaseFirestore();
      commentsService = CommentsService(
        auth: mockAuth,
        firestore: fakeFirestore,
      );
    });

    group('addComment', () {
      test('adds a comment to Firestore with correct fields', () async {
        await commentsService.addComment(
          'This is a test comment',
          'Test User',
          'image-123',
        );

        final snapshot = await fakeFirestore.collection('comments').get();

        expect(snapshot.docs.length, equals(1));

        final comment = snapshot.docs.first.data();
        expect(comment['userId'], equals('test-user-123'));
        expect(comment['userName'], equals('Test User'));
        expect(comment['commentText'], equals('This is a test comment'));
        expect(comment['imageId'], equals('image-123'));
        // FakeFirestore converts FieldValue.serverTimestamp() to Timestamp
        expect(comment['timestamp'], isA<Timestamp>());
      });

      test('adds multiple comments', () async {
        await commentsService.addComment('Comment 1', 'User 1', 'img-1');
        await commentsService.addComment('Comment 2', 'User 2', 'img-2');
        await commentsService.addComment('Comment 3', 'User 3', 'img-3');

        final snapshot = await fakeFirestore.collection('comments').get();

        expect(snapshot.docs.length, equals(3));
      });
    });

    group('getComments', () {
      test('returns empty list when no comments exist', () async {
        final stream = commentsService.getComments();

        expect(
          stream,
          emits(isEmpty),
        );
      });

      test('returns comments ordered by timestamp descending', () async {
        // Add comments with specific timestamps
        await fakeFirestore.collection('comments').add({
          'userId': 'user-1',
          'userName': 'First User',
          'commentText': 'First comment',
          'timestamp': Timestamp.fromDate(DateTime(2024, 1, 1)),
          'imageId': 'img-1',
        });

        await fakeFirestore.collection('comments').add({
          'userId': 'user-2',
          'userName': 'Second User',
          'commentText': 'Second comment',
          'timestamp': Timestamp.fromDate(DateTime(2024, 1, 3)),
          'imageId': 'img-2',
        });

        await fakeFirestore.collection('comments').add({
          'userId': 'user-3',
          'userName': 'Third User',
          'commentText': 'Third comment',
          'timestamp': Timestamp.fromDate(DateTime(2024, 1, 2)),
          'imageId': 'img-3',
        });

        final comments = await commentsService.getComments().first;

        expect(comments.length, equals(3));
        // Should be ordered by timestamp descending (newest first)
        expect(comments[0].userName, equals('Second User'));
        expect(comments[1].userName, equals('Third User'));
        expect(comments[2].userName, equals('First User'));
      });

      test('handles null userName with default "Anonymous"', () async {
        await fakeFirestore.collection('comments').add({
          'userId': 'user-1',
          'userName': null,
          'commentText': 'Comment without username',
          'timestamp': Timestamp.now(),
          'imageId': 'img-1',
        });

        final comments = await commentsService.getComments().first;

        expect(comments.length, equals(1));
        expect(comments[0].userName, equals('Anonymous'));
      });

      test('handles null commentText with default', () async {
        await fakeFirestore.collection('comments').add({
          'userId': 'user-1',
          'userName': 'Test User',
          'commentText': null,
          'timestamp': Timestamp.now(),
          'imageId': 'img-1',
        });

        final comments = await commentsService.getComments().first;

        expect(comments.length, equals(1));
        expect(comments[0].commentText, equals('No comment text'));
      });

      test('handles null timestamp', () async {
        await fakeFirestore.collection('comments').add({
          'userId': 'user-1',
          'userName': 'Test User',
          'commentText': 'Comment with null timestamp',
          'timestamp': null,
          'imageId': 'img-1',
        });

        final comments = await commentsService.getComments().first;

        expect(comments.length, equals(1));
        expect(comments[0].timestamp, isNull);
      });
    });
  });
}
