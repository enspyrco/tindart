import 'dart:io';

import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tindart/auth/auth_service.dart';
import 'package:tindart/cards/web_detection_sheet.dart';
import 'package:tindart/comments/comments_widget.dart';
import 'package:tindart/utils/locator.dart';

const _storageBaseUrl =
    'https://storage.googleapis.com/tindart-8c83b.firebasestorage.app';

enum _MenuAction { signOut, deleteAccount, profile, setWallpaper, webDetection }

class CardBack extends StatefulWidget {
  const CardBack({required this.fileName, super.key});

  final String fileName;

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
      barrierDismissible: false, // User must tap a button to close
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
      // Perform the deletion
      _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _deleting = true;
    });
    final _ = await FirebaseFunctions.instance
        .httpsCallable('deleteUserAccount')
        .call();
    setState(() {
      _deleting = false;
    });
    if (mounted) {
      context.go('/signin');
    }
  }

  /// Downloads the image to a temporary file and returns it.
  /// Caller is responsible for deleting the file when done.
  Future<File> _downloadImageToTempFile() async {
    final imageUrl = '$_storageBaseUrl/${widget.fileName}';
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download image (HTTP ${response.statusCode})',
      );
    }
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/tindart_wallpaper_temp.jpg');
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  Future<void> _showWallpaperConfirmation(BuildContext context) async {
    if (Platform.isIOS) {
      // iOS: Save to Photos and show instructions
      await _saveToPhotosForWallpaper();
    } else {
      // Android: Show wallpaper location picker
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Set as Wallpaper'),
          icon: const Icon(Icons.wallpaper, color: Colors.blue, size: 40),
          content: const Text('Where would you like to set this image?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'home'),
              child: const Text('Home Screen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'lock'),
              child: const Text('Lock Screen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'both'),
              child: const Text('Both'),
            ),
          ],
        ),
      );

      if (result != null) {
        await _setWallpaperAndroid(result);
      }
    }
  }

  Future<void> _saveToPhotosForWallpaper() async {
    File? tempFile;
    try {
      setState(() {
        _settingWallpaper = true;
      });

      // Check for permission
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          throw Exception('Permission denied to save to Photos');
        }
      }

      // Download the image
      tempFile = await _downloadImageToTempFile();

      // Save to Photos library
      await Gal.putImage(tempFile.path, album: 'TindArt');

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Saved to Photos'),
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
            content: const Text(
              'The image has been saved to your Photos library in the "TindArt" album.\n\n'
              'To set as wallpaper:\n'
              '1. Open the Photos app\n'
              '2. Find the image in the TindArt album\n'
              '3. Tap the share button\n'
              '4. Select "Use as Wallpaper"',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always clean up temp file
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
      setState(() {
        _settingWallpaper = false;
      });
    }
  }

  Future<void> _setWallpaperAndroid(String type) async {
    File? tempFile;
    try {
      setState(() {
        _settingWallpaper = true;
      });

      // Download the image to temporary file
      tempFile = await _downloadImageToTempFile();

      // Set wallpaper based on user choice
      final wallpaperLocation = switch (type) {
        'home' => WallpaperManagerPlus.homeScreen,
        'lock' => WallpaperManagerPlus.lockScreen,
        'both' => WallpaperManagerPlus.bothScreens,
        _ => throw Exception('Invalid wallpaper type: $type'),
      };

      await WallpaperManagerPlus().setWallpaper(
        tempFile,
        wallpaperLocation,
      );

      // Show success (throws on failure)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallpaper set successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always clean up temp file
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
      setState(() {
        _settingWallpaper = false;
      });
    }
  }

  Future<void> _showWebDetectionResults() async {
    final imageUrl = '$_storageBaseUrl/${widget.fileName}';
    setState(() {
      _searchingWeb = true;
    });

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('detectWeb')
          .call({'imageUrl': imageUrl});

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
                    _showWallpaperConfirmation(context);
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
