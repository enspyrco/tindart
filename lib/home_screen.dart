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
  List<String> _docIds = [];
  bool _retrievingIds = false;
  bool _retrievingUrls = false;
  int _index = 0;

  Future<void> _getRandomisedDocIds() async {
    setState(() {
      _retrievingIds = true;
    });

    DocumentSnapshot<Map<String, dynamic>> docIdsDoc =
        await FirebaseFirestore.instance
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

    List<String> ids = _docIds.sublist(_index, _index + 5);
    _index = _index + 5;
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

  @override
  void initState() {
    super.initState();

    _getRandomisedDocIds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          (_retrievingIds || _retrievingUrls)
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
                onSwipe: (previousIndex, currentIndex, direction) {
                  if (currentIndex == 5) {
                    _retrieveNextImages();
                  } else {
                    if (currentIndex != null &&
                        direction == CardSwiperDirection.left) {
                      FirebaseFirestore.instance
                          .collection('preferences')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .set({
                            'disliked': FieldValue.arrayUnion([
                              _docIds[currentIndex],
                            ]),
                            'timestamp': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));

                      FirebaseFirestore.instance
                          .collection('image-docs')
                          .doc(_docIds[currentIndex])
                          .set({
                            'disliked': FieldValue.arrayUnion([
                              FirebaseAuth.instance.currentUser!.uid,
                            ]),
                          }, SetOptions(merge: true));

                      return true;
                    }

                    if (currentIndex != null &&
                        direction == CardSwiperDirection.right) {
                      FirebaseFirestore.instance
                          .collection('preferences')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .set({
                            'liked': FieldValue.arrayUnion([
                              _docIds[currentIndex],
                            ]),
                            'timestamp': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));

                      FirebaseFirestore.instance
                          .collection('image-docs')
                          .doc(_docIds[currentIndex])
                          .set({
                            'liked': FieldValue.arrayUnion([
                              FirebaseAuth.instance.currentUser!.uid,
                            ]),
                          }, SetOptions(merge: true));

                      return true;
                    }
                  }

                  return false;
                },
              ),
    );
  }
}
