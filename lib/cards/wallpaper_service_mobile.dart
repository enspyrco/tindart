import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';

const _storageBaseUrl =
    'https://storage.googleapis.com/tindart-8c83b.firebasestorage.app';

class WallpaperService {
  static bool get isSupported => true;

  static Future<File> _downloadImageToTempFile(String fileName) async {
    final imageUrl = '$_storageBaseUrl/$fileName';
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

  static Future<void> showWallpaperDialog(
    BuildContext context,
    String fileName,
  ) async {
    if (Platform.isIOS) {
      await _saveToPhotosForWallpaper(context, fileName);
    } else {
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

      if (result != null && context.mounted) {
        await _setWallpaperAndroid(context, fileName, result);
      }
    }
  }

  static Future<void> _saveToPhotosForWallpaper(
    BuildContext context,
    String fileName,
  ) async {
    File? tempFile;
    try {
      // Check for permission
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          throw Exception('Permission denied to save to Photos');
        }
      }

      // Download the image
      tempFile = await _downloadImageToTempFile(fileName);

      // Save to Photos library
      await Gal.putImage(tempFile.path, album: 'TindArt');

      if (context.mounted) {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  static Future<void> _setWallpaperAndroid(
    BuildContext context,
    String fileName,
    String type,
  ) async {
    File? tempFile;
    try {
      // Download the image to temporary file
      tempFile = await _downloadImageToTempFile(fileName);

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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallpaper set successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }
}
