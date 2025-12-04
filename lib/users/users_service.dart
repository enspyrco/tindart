import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersService {
  UsersService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<int> retrieveViewedImages() async {
    if (_auth.currentUser == null) {
      throw 'You must be signed in to access the database';
    }

    String userId = _auth.currentUser!.uid;

    final snapshot =
        await _firestore.collection('preferences').doc(userId).get();

    Map<String, Object?> data = snapshot.data() ?? {};

    List liked = data['liked'] as List? ?? [];
    List disliked = data['disliked'] as List? ?? [];

    return liked.length + disliked.length;
  }

  Future<String> getUserName() async {
    String userId = _auth.currentUser!.uid;

    DocumentSnapshot doc =
        await _firestore.collection('profiles').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      return data['name'] as String? ??
          ''; // Assuming 'name' field holds the username
    } else {
      return '';
    }
  }
}
