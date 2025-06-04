import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersService {
  UsersService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<int> retrieveViewedImages() async {
    if (_auth.currentUser == null) {
      throw 'You must be signed in to access the database';
    }

    String userId = _auth.currentUser!.uid;

    final AggregateQuerySnapshot snapshot =
        await _firestore
            .collection('image-docs')
            .where(
              Filter.or(
                Filter('liked', arrayContains: userId),
                Filter('disliked', arrayContains: userId),
              ),
            )
            .count()
            .get();

    return snapshot.count!;
  }
}
