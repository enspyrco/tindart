import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Artwork {
  final String docId;
  final String fileName;
  final String imageUrl;

  Artwork({
    required this.docId,
    required this.fileName,
    required this.imageUrl,
  });

  factory Artwork.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final fileName = data['name'] as String;
    return Artwork(
      docId: doc.id,
      fileName: fileName,
      imageUrl:
          'https://storage.googleapis.com/tindart-8c83b.firebasestorage.app/$fileName',
    );
  }
}

class ArtworkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _allDocIds = [];
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final docIdsDoc = await _firestore
        .collection('doc-id-lists')
        .doc('RMCevRY4dGpUTTcrltun')
        .get();

    _allDocIds = List<String>.from(docIdsDoc['ids'] as List);
    _initialized = true;
  }

  Future<List<String>> getRandomizedDocIds() async {
    await _ensureInitialized();
    final shuffled = List<String>.from(_allDocIds);
    shuffled.shuffle();
    return shuffled;
  }

  Future<List<Artwork>> getArtworksBatch(List<String> docIds) async {
    if (docIds.isEmpty) return [];

    final querySnapshot = await _firestore
        .collection('image-docs')
        .where(FieldPath.documentId, whereIn: docIds)
        .get();

    return querySnapshot.docs.map((doc) => Artwork.fromFirestore(doc)).toList();
  }

  Future<Artwork?> getArtworkById(String docId) async {
    final doc = await _firestore.collection('image-docs').doc(docId).get();
    if (!doc.exists) return null;
    return Artwork.fromFirestore(doc);
  }

  Future<List<Artwork>> getPaginatedArtworks({
    required int page,
    required int limit,
  }) async {
    await _ensureInitialized();

    final startIndex = page * limit;
    if (startIndex >= _allDocIds.length) return [];

    final endIndex = (startIndex + limit).clamp(0, _allDocIds.length);
    final pageDocIds = _allDocIds.sublist(startIndex, endIndex);

    return getArtworksBatch(pageDocIds);
  }

  Future<int> getTotalArtworkCount() async {
    await _ensureInitialized();
    return _allDocIds.length;
  }

  Future<List<Artwork>> getLikedArtworks() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    final prefsDoc =
        await _firestore.collection('preferences').doc(userId).get();
    if (!prefsDoc.exists) return [];

    final likedIds = List<String>.from(prefsDoc.data()?['liked'] ?? []);
    if (likedIds.isEmpty) return [];

    // Firestore whereIn limited to 30 items, so batch if needed
    final artworks = <Artwork>[];
    for (var i = 0; i < likedIds.length; i += 30) {
      final batch = likedIds.sublist(
        i,
        (i + 30).clamp(0, likedIds.length),
      );
      artworks.addAll(await getArtworksBatch(batch));
    }

    return artworks;
  }

  Future<void> savePreference({
    required String docId,
    required String field,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await Future.wait([
      _firestore.collection('preferences').doc(userId).set({
        field: FieldValue.arrayUnion([docId]),
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
      _firestore.collection('image-docs').doc(docId).set({
        field: FieldValue.arrayUnion([userId]),
      }, SetOptions(merge: true)),
    ]);
  }

  Future<bool> isArtworkLiked(String docId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    final prefsDoc =
        await _firestore.collection('preferences').doc(userId).get();
    if (!prefsDoc.exists) return false;

    final likedIds = List<String>.from(prefsDoc.data()?['liked'] ?? []);
    return likedIds.contains(docId);
  }
}
