import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tindart/auth/auth_service.dart'; // Assuming AuthService is correctly located
import 'package:tindart/users/users_service.dart';
import 'package:tindart/utils/locator.dart'; // Assuming locator is correctly set up
import 'package:go_router/go_router.dart'; // For navigation

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _initialUsername; // To store the username fetched from Firestore

  @override
  void initState() {
    super.initState();
    _loadCurrentUsername(); // Load the current username when the screen initializes
  }

  @override
  void dispose() {
    _usernameController
        .dispose(); // Dispose the controller to prevent memory leaks
    super.dispose();
  }

  // Function to load the current username from Firestore
  Future<void> _loadCurrentUsername() async {
    final userId = locate<AuthService>().currentUserId;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator while fetching
    });

    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('profiles')
              .doc(userId)
              .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        _initialUsername =
            data['name'] as String?; // Assuming 'name' field holds the username
        _usernameController.text =
            _initialUsername ?? ''; // Pre-fill the text field
      } else {
        _initialUsername = ''; // No existing profile or name
        _usernameController.text = '';
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load username: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  // Function to save the new username to Firestore
  Future<void> _saveUsername() async {
    final userId = locate<AuthService>().currentUserId;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not logged in. Cannot save username.'),
          ),
        );
      }
      return;
    }

    final newUsername = _usernameController.text.trim();

    if (newUsername.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username cannot be empty.')),
        );
      }
      return;
    }

    // Check if the username has actually changed
    if (newUsername == _initialUsername) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username is already up to date.')),
        );
        context.pop(); // Go back if no change
      }
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // Update the 'name' field in the 'profiles/{userId}' document
      await FirebaseFirestore.instance.collection('profiles').doc(userId).set({
        'name': newUsername,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully!')),
        );
        context.pop(); // Navigate back after successful save
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update username: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading indicator, re-enable button
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the save button should be enabled
    // It should be enabled if not loading AND the text field is not empty AND the text has changed from initial
    final bool isSaveButtonEnabled =
        !_isLoading &&
        _usernameController.text.trim().isNotEmpty &&
        _usernameController.text.trim() != _initialUsername;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter your new username:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'New Username',
                hintText: 'e.g., JaneDoe',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
                prefixIcon: Icon(Icons.person_outline),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
              ),
              keyboardType: TextInputType.text,
              onChanged: (text) {
                setState(() {
                  // Rebuild to update button state as text changes
                });
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isSaveButtonEnabled ? _saveUsername : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        'Save Username',
                        style: TextStyle(fontSize: 18),
                      ),
            ),
            const SizedBox(height: 30),
            FutureBuilder(
              future: locate<UsersService>().retrieveViewedImages(),
              builder: (context, snapshot) {
                String number = 'null';
                if (snapshot.hasData) {
                  number = snapshot.data!.toString();
                }
                return Text('You have swiped $number images.');
              },
            ),
          ],
        ),
      ),
    );
  }
}
