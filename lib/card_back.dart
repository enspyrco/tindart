import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tindart/auth/auth_service.dart';
import 'package:tindart/utils/locator.dart';

class CardBack extends StatefulWidget {
  const CardBack({super.key});

  @override
  State<CardBack> createState() => _CardBackState();
}

class _CardBackState extends State<CardBack> {
  bool _deleting = false;

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap a button to close
      builder:
          (context) => AlertDialog(
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
      // Perform the deletion
      _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _deleting = true;
    });
    await locate<AuthService>().deleteAccount();
    setState(() {
      _deleting = false;
    });
    if (mounted) {
      context.go('/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TindArt'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'Delete' && !_deleting) {
                _showDeleteConfirmation(context);
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'Delete',
                    child: Text('Delete Account'),
                  ),
                  // const PopupMenuItem<String>(
                  //   value: 'Help',
                  //   child: Text('Help'),
                  // ),
                  // const PopupMenuItem<String>(
                  //   value: 'About',
                  //   child: Text('About'),
                  // ),
                ],
          ),
        ],
      ),
      body: Center(
        child:
            _deleting
                ? CircularProgressIndicator()
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: const Text(
                        'Select the menu button to manage your account.',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
