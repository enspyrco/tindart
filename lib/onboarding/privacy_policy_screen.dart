import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  Future<void> _launchMailClient() async {
    try {
      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: 'contact@enspyr.co',
        queryParameters: {'subject': 'TindArt Privacy Policy', 'body': ''},
      );
      await launchUrl(emailLaunchUri);
    } catch (e) {
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: 09/05/25',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Section 1
            const Text(
              '1. Information We Collect',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our app collects minimal user data to enhance your experience. Specifically, we store:',
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• A unique user identifier (User ID)'),
                  Text(
                    '• Your likes and dislikes associated with that User ID',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We do not collect personally identifiable information (such as name, email, or location).',
            ),
            const SizedBox(height: 24),

            // Section 2
            const Text(
              '2. How We Use Your Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('The data we collect is used solely to:'),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Personalize your in-app experience'),
                  Text('• Improve app functionality'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your data is never shared with or sold to third parties.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Section 3
            const Text(
              '3. Data Retention & Deletion',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your data is retained only as long as your account exists. When you delete your account, all associated data (User ID, likes, and dislikes) is permanently removed from our systems.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Section 4
            const Text(
              '4. Security',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We implement industry-standard measures to protect your data from unauthorized access or misuse.',
            ),
            const SizedBox(height: 24),

            // Section 5
            const Text(
              '5. Changes to This Policy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We may update this policy occasionally. You will be notified of significant changes within the app.',
            ),
            const SizedBox(height: 24),

            // Section 6
            const Text(
              '6. Contact Us',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'For questions about this policy or your data, contact us at:',
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                _launchMailClient();
              },
              child: Text(
                'contact@enspyr.co',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
