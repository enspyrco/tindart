import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tindart/comments/models/comment.dart';

class CommentsService {
  CommentsService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> addComment(
    String commentText,
    String userName,
    String imageId,
  ) async {
    await _firestore.collection('comments').add({
      'userId': _auth.currentUser!.uid,
      'userName': userName,
      'commentText': commentText,
      'timestamp': FieldValue.serverTimestamp(),
      'imageId': imageId,
    });
  }

  Stream<List<Comment>> getComments() {
    return _firestore
        .collection('comments')
        .orderBy('timestamp', descending: true) // Order comments by most recent
        .snapshots()
        .map<List<Comment>>((querySnapshot) {
      final List<Comment> comments = [];
      for (final queryDocumentSnapshot in querySnapshot.docs) {
        final String userName =
            queryDocumentSnapshot['userName'] ?? 'Anonymous';
        final String commentText =
            queryDocumentSnapshot['commentText'] ?? 'No comment text';
        final Timestamp? doc = queryDocumentSnapshot['timestamp'] as Timestamp?;

        comments.add(Comment(userName, commentText, doc));
      }
      return comments;
    });
  }
}
