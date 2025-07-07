import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tindart/auth/auth_service.dart';
import 'package:tindart/utils/locator.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Firestore interaction

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isChecked = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add a listener to the name text field to rebuild the widget
    // and re-evaluate the button's enabled state when text changes.
    _nameController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _nameController.removeListener(
      _updateButtonState,
    ); // Remove listener to prevent memory leaks
    _nameController
        .dispose(); // Dispose the controller when the widget is removed
    super.dispose();
  }

  // This method is called when the name text field's content changes.
  // It triggers a rebuild of the widget, which re-evaluates the `onPressed` condition for the button.
  void _updateButtonState() {
    setState(() {});
  }

  // Function to save the user's name to Firestore
  // Now returns a boolean indicating success or failure.
  Future<bool> _saveProfile(BuildContext context) async {
    // Get the current user's ID from AuthService
    final userId = locate<AuthService>().currentUserId;

    if (userId == null) {
      // If user ID is null, it means the user is not authenticated.
      // Show an error message and stop the process.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not logged in. Cannot save profile.'),
        ),
      );
      return false; // Indicate failure
    }

    final name =
        _nameController.text.trim(); // Get the trimmed text from the name field

    try {
      await FirebaseFirestore.instance.collection('profiles').doc(userId).set({
        'name': name,
      }, SetOptions(merge: true));

      if (!context.mounted) return false;

      return true; // Indicate success
    } on FirebaseException catch (e) {
      // Catch specific Firebase exceptions for better error handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: ${e.message}')),
      );
      return false; // Indicate failure
    } catch (e) {
      // Catch any other general exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
      return false; // Indicate failure
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the "Done" button should be enabled
    final bool isButtonEnabled =
        _isChecked && _nameController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to TindArt')),
      body: SafeArea(
        child: Stack(
          children: [
            // Top section with checkbox and text with link
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Swipe left on art you like less and right on art you like more.\n\n'
                    'The recommendation algorithm will provide art that other users with similar tastes have liked.\n\n'
                    'Double tap to get metadata and account options.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30), // Adjusted spacing
                  // New Name Text Field
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      hintText: 'Enter your full name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 16.0,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                    ),
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 30), // Spacing after name field

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _isChecked,
                        onChanged: (value) {
                          setState(() {
                            _isChecked = value ?? false;
                            // No need to call _updateButtonState explicitly here,
                            // as setState will trigger a rebuild anyway.
                          });
                        },
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                fontSize: 16.0,
                              ),
                              children: [
                                const TextSpan(text: 'I agree to TindArt\'s '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer:
                                      TapGestureRecognizer()
                                        ..onTap = () {
                                          context.push('/privacy-policy');
                                        },
                                ),
                                const TextSpan(
                                  text: ' and confirm that I have read it.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Done Button in bottom right
            Positioned(
              right: 24.0,
              bottom: 24.0,
              child: ElevatedButton(
                // Button is enabled only if _isChecked is true AND _nameController is not empty
                onPressed:
                    isButtonEnabled
                        ? () async {
                          // Attempt to save the profile name to Firestore
                          final bool saveSuccess = await _saveProfile(context);

                          // Only proceed with onboarding completion and navigation if save was successful
                          if (saveSuccess) {
                            SharedPreferences.getInstance().then((prefs) {
                              prefs.setBool('onboarded', true);
                            });

                            if (!context.mounted) return;

                            if (locate<AuthService>().currentUserId == null) {
                              context.go('/signin');
                            } else {
                              context.go('/');
                            }
                          }
                          // If saveSuccess is false, _saveProfile already showed an error message,
                          // so no further action is needed here, and navigation will not occur.
                        }
                        : null, // Button is disabled if conditions are not met
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
