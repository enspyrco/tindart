import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:tindart/cards/card_back.dart';
import 'package:tindart/cards/flip_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DocumentSnapshot? lastSnapshot;
  final List<Widget> cards = [];
  final List<String> _cardDocIds = []; // Store doc IDs for current batch
  List<String> _docIds = [];
  bool _retrievingIds = false;
  bool _retrievingUrls = false;
  int _index = 0;

  Future<void> _getRandomisedDocIds() async {
    setState(() {
      _retrievingIds = true;
    });

    DocumentSnapshot<Map<String, dynamic>> docIdsDoc = await FirebaseFirestore
        .instance
        .collection('doc-id-lists')
        .doc('RMCevRY4dGpUTTcrltun')
        .get();

    _docIds = List<String>.from(docIdsDoc['ids'] as List);

    _docIds.shuffle();

    setState(() {
      _retrievingIds = false;
    });

    _retrieveNextImages();
  }

  Future<void> _retrieveNextImages() async {
    setState(() {
      _retrievingUrls = true;
    });

    cards.clear();
    _cardDocIds.clear(); // Clear the doc IDs for new batch

    final endIndex = (_index + 5).clamp(0, _docIds.length);
    List<String> ids = _docIds.sublist(_index, endIndex);
    _index = endIndex;
    if (_index >= _docIds.length) _index = 0;

    // Retrieve all `images` documents where the document's id is in the `ids`
    // list
    final QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance
            .collection('image-docs')
            .where(FieldPath.documentId, whereIn: ids)
            .get();

    for (final doc in querySnapshot.docs) {
      final String fileName = doc.data()['name'];
      final String docId = doc.id;

      _cardDocIds.add(docId); // Store the doc ID for this card

      cards.add(
        FlipCard(
          front: Center(
            child: Container(
              color: Colors.white,
              width: double.infinity,
              height: double.infinity,
              child: Image.network(
                'https://storage.googleapis.com/tindart-8c83b.firebasestorage.app/$fileName',
              ),
            ),
          ),
          back: CardBack(fileName: fileName),
        ),
      );
    }

    cards.add(Center(child: CircularProgressIndicator()));

    setState(() {
      _retrievingUrls = false;
    });
  }

  Future<void> _savePreference({
    required String docId,
    required String userId,
    required String field,
  }) async {
    try {
      await Future.wait([
        FirebaseFirestore.instance.collection('preferences').doc(userId).set({
          field: FieldValue.arrayUnion([docId]),
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
        FirebaseFirestore.instance.collection('image-docs').doc(docId).set({
          field: FieldValue.arrayUnion([userId]),
        }, SetOptions(merge: true)),
      ]);
    } catch (e) {
      log('Error saving $field: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    _getRandomisedDocIds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (_retrievingIds || _retrievingUrls)
          ? Center(child: CircularProgressIndicator())
          : CardSwiper(
              cardsCount: cards.length,
              padding: const EdgeInsets.all(0),
              allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
                horizontal: true,
              ),
              cardBuilder:
                  (context, index, percentThresholdX, percentThresholdY) =>
                      cards[index],
              onSwipe: (previousIndex, currentIndex, direction) async {
                if (currentIndex == 5) {
                  _retrieveNextImages();
                  return true;
                }

                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId == null ||
                    currentIndex == null ||
                    currentIndex >= _cardDocIds.length) {
                  return true;
                }

                final docId = _cardDocIds[currentIndex];

                if (direction == CardSwiperDirection.left) {
                  await _savePreference(
                    docId: docId,
                    userId: userId,
                    field: 'disliked',
                  );
                } else if (direction == CardSwiperDirection.right) {
                  await _savePreference(
                    docId: docId,
                    userId: userId,
                    field: 'liked',
                  );
                }

                return true;
              },
            ),
    );
  }
}
