import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:tindart/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
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
            .doc('kDWqPbT7U2XQxQmEHtYl')
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

    final QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance
            .collection('images')
            .where(FieldPath.documentId, whereIn: ids)
            .get();

    for (final doc in querySnapshot.docs) {
      final String fileName = doc.data()['name'];

      cards.add(
        Center(
          child: Container(
            color: Colors.white,
            width: double.infinity,
            height: double.infinity,
            child: Image.network(
              'https://storage.googleapis.com/tindart-8c83b.firebasestorage.app/$fileName',
            ),
          ),
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
    return MaterialApp(
      home: Scaffold(
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
                    }

                    return true;
                  },
                ),
      ),
    );
  }
}
