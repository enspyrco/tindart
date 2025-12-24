import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tindart/auth/auth_service.dart';
import 'package:tindart/users/users_service.dart';
import 'package:tindart/utils/locator.dart';
import 'package:go_router/go_router.dart';

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
      String initialUsername = await locate<UsersService>().getUserName();
      _usernameController.text = initialUsername; // Pre-fill the text field
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
    final bool isSaveButtonEnabled = !_isLoading &&
        _usernameController.text.trim().isNotEmpty &&
        _usernameController.text.trim() != _initialUsername;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
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
              child: _isLoading
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
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Linked Accounts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Link multiple sign-in methods to access your account from any device.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _LinkedAccountTile(
              provider: 'google.com',
              providerName: 'Google',
              icon: Icons.g_mobiledata,
              isLinked: locate<AuthService>().isGoogleLinked(),
              onLink: () => _linkProvider('google'),
              onUnlink: () => _unlinkProvider('google.com'),
            ),
            // Apple Sign-In on web requires Apple Services ID configuration
            if (!kIsWeb) ...[
              const SizedBox(height: 12),
              _LinkedAccountTile(
                provider: 'apple.com',
                providerName: 'Apple',
                icon: Icons.apple,
                isLinked: locate<AuthService>().isAppleLinked(),
                onLink: () => _linkProvider('apple'),
                onUnlink: () => _unlinkProvider('apple.com'),
              ),
            ],
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Danger Zone',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('Delete Account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _linkProvider(String provider) async {
    setState(() => _isLoading = true);

    try {
      if (provider == 'google') {
        await locate<AuthService>().linkWithGoogle();
      } else if (provider == 'apple') {
        await locate<AuthService>().linkWithApple();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${provider == 'google' ? 'Google' : 'Apple'} account linked successfully!')),
        );
        setState(() {}); // Refresh UI to show linked state
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Failed to link account';
        if (e.code == 'credential-already-in-use') {
          message = 'This account is already linked to another user';
        } else if (e.code == 'provider-already-linked') {
          message = 'This provider is already linked';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unlinkProvider(String providerId) async {
    final authService = locate<AuthService>();
    final linkedCount = authService.getLinkedProviders().length;

    if (linkedCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot unlink your only sign-in method')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await authService.unlinkProvider(providerId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account unlinked successfully')),
        );
        setState(() {}); // Refresh UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await locate<AuthService>().deleteAccount();
      if (mounted) {
        context.go('/signin');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}

class _LinkedAccountTile extends StatelessWidget {
  final String provider;
  final String providerName;
  final IconData icon;
  final bool isLinked;
  final VoidCallback onLink;
  final VoidCallback onUnlink;

  const _LinkedAccountTile({
    required this.provider,
    required this.providerName,
    required this.icon,
    required this.isLinked,
    required this.onLink,
    required this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  providerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  isLinked ? 'Connected' : 'Not connected',
                  style: TextStyle(
                    fontSize: 12,
                    color: isLinked ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (isLinked)
            TextButton(
              onPressed: onUnlink,
              child: const Text('Unlink'),
            )
          else
            ElevatedButton(
              onPressed: onLink,
              child: const Text('Link'),
            ),
        ],
      ),
    );
  }
}
