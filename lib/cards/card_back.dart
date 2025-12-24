import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tindart/auth/auth_service.dart';
import 'package:tindart/cards/wallpaper_service.dart';
import 'package:tindart/cards/web_detection_sheet.dart';
import 'package:tindart/comments/comments_widget.dart';
import 'package:tindart/utils/locator.dart';

enum _MenuAction { signOut, deleteAccount, profile, setWallpaper, webDetection }

class CardBack extends StatefulWidget {
  const CardBack({required this.fileName, required this.docId, super.key});

  final String fileName;
  final String docId;

  @override
  State<CardBack> createState() => _CardBackState();
}

class _CardBackState extends State<CardBack> {
  bool _deleting = false;
  bool _settingWallpaper = false;
  bool _searchingWeb = false;

  Future<void> _signOut() async {
    await locate<AuthService>().signOut();
    if (mounted) {
      context.go('/signin');
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        icon: const Icon(Icons.warning, color: Colors.red, size: 40),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This action will permanently:'),
            SizedBox(height: 8),
            Text('• Delete all user data'),
            Text('• Remove all account information'),
            Text('• Clear all app preferences'),
            SizedBox(height: 16),
            Text(
              'This action cannot be undone.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.clear();
      });
      _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _deleting = true;
    });
    await FirebaseFunctions.instance.httpsCallable('deleteUserAccount').call();
    setState(() {
      _deleting = false;
    });
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
                  case _MenuAction.deleteAccount:
                    if (!_deleting) _showDeleteConfirmation(context);
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
                  value: _MenuAction.deleteAccount,
                  child: Text('Delete Account'),
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
          if (_deleting || _settingWallpaper || _searchingWeb)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
