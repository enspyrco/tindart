import 'dart:io' as io;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
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
  String _progressString = 'waiting for selection';
  List<PlatformFile> imageFiles = [];
  double _progressNum = 0;
  int _filesNum = 0;

  Future<void> _pickFile() async {
    try {
      setState(() {
        _progressString = 'copying files into app cache...';
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg'],
      );

      setState(() {
        _progressString = 'cache is ready';
      });

      for (final PlatformFile file in result!.files) {
        String basename = path.basename(file.path!);
        if (basename.substring(0, 7) == 'FB_IMG_') {
          imageFiles.add(file);
        }
      }

      setState(() {
        _filesNum = imageFiles.length;
        _progressString = 'Uploading $_filesNum files...';
      });

      for (final PlatformFile file in imageFiles) {
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('facebook')
            .child(path.basename(file.path!));

        ref.putFile(io.File(file.path!)).then((snapshot) {
          if (snapshot.state == TaskState.success) {
            FirebaseFirestore.instance
                .collection('images')
                .add({'filePath': snapshot.ref.fullPath, 'source': 'facebook'})
                .then((docRef) {
                  setState(() {
                    _progressNum += 1 / imageFiles.length;
                    _progressString = 'Uploading ${--_filesNum} files...';
                  });
                });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(child: Text(_progressString)),
            LinearProgressIndicator(value: _progressNum),
            TextButton(
              onPressed: () {
                _pickFile();
              },
              child: Text('open'),
            ),
          ],
        ),
      ),
    );
  }
}
