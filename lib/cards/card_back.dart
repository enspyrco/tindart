import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tindart/auth/auth_service.dart';
import 'package:tindart/cards/wallpaper_service.dart';
import 'package:tindart/cards/web_detection_sheet.dart';
import 'package:tindart/comments/comments_widget.dart';
import 'package:tindart/utils/locator.dart';

enum _MenuAction { signOut, profile, setWallpaper, webDetection }

class CardBack extends StatefulWidget {
  const CardBack({required this.fileName, required this.docId, super.key});

  final String fileName;
  final String docId;

  @override
  State<CardBack> createState() => _CardBackState();
}

class _CardBackState extends State<CardBack> {
  bool _settingWallpaper = false;
  bool _searchingWeb = false;

  Future<void> _signOut() async {
    await locate<AuthService>().signOut();
    if (mounted) {
      context.go('/signin');
    }
  }

  Future<void> _handleSetWallpaper() async {
    setState(() {
      _settingWallpaper = true;
    });
    try {
      await WallpaperService.showWallpaperDialog(context, widget.fileName);
    } finally {
      if (mounted) {
        setState(() {
          _settingWallpaper = false;
        });
      }
    }
  }

  Future<void> _showWebDetectionResults() async {
    setState(() {
      _searchingWeb = true;
    });

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('detectWeb')
          .call({'imageDocId': widget.docId});

      if (!mounted) return;

      setState(() {
        _searchingWeb = false;
      });

      final responseData = Map<String, dynamic>.from(result.data as Map);
      final data = responseData['data'] != null
          ? Map<String, dynamic>.from(responseData['data'] as Map)
          : null;
      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No web detection results found')),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => WebDetectionSheet(data: data),
      );
    } catch (e) {
      setState(() {
        _searchingWeb = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TindArt'),
        actions: [
          Semantics(
            identifier: 'menu',
            button: true,
            child: PopupMenuButton<_MenuAction>(
              tooltip: 'menu',
              icon: const Icon(Icons.more_vert),
              onSelected: (action) {
                switch (action) {
                  case _MenuAction.signOut:
                    _signOut();
                  case _MenuAction.profile:
                    context.push('/profile');
                  case _MenuAction.setWallpaper:
                    _handleSetWallpaper();
                  case _MenuAction.webDetection:
                    _showWebDetectionResults();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: _MenuAction.signOut,
                  child: Text('Sign Out'),
                ),
                const PopupMenuItem(
                  value: _MenuAction.profile,
                  child: Text('Profile'),
                ),
                // Wallpaper feature is only available on mobile
                if (WallpaperService.isSupported)
                  const PopupMenuItem(
                    value: _MenuAction.setWallpaper,
                    child: Row(
                      children: [
                        Icon(Icons.wallpaper, size: 20),
                        SizedBox(width: 8),
                        Text('Set as Wallpaper'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: _MenuAction.webDetection,
                  child: Row(
                    children: [
                      Icon(Icons.image_search, size: 20),
                      SizedBox(width: 8),
                      Text('Find Similar'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(child: CommentsWidget(imageId: widget.fileName)),
          if (_settingWallpaper || _searchingWeb)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
