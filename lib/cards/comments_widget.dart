import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tindart/auth/auth_service.dart';
import 'package:tindart/utils/locator.dart';

class CommentsWidget extends StatefulWidget {
  const CommentsWidget({super.key});

  @override
  State<CommentsWidget> createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Get FirebaseAuth instance
  bool _isPostingComment = false; // To show loading indicator on post button

  // Function to add a new comment to Firestore
  Future<void> _addComment() async {
    final String commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment cannot be empty.')));
      return;
    }

    final String? userId =
        locate<AuthService>().currentUserId; // Get current user ID
    final String? userName =
        _auth.currentUser?.displayName ??
        'Anonymous'; // Get user's display name or default

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to post a comment.'),
        ),
      );
      return;
    }

    setState(() {
      _isPostingComment = true; // Show loading indicator
    });

    try {
      await _firestore.collection('comments').add({
        'userId': userId,
        'userName': userName, // Store user's display name
        'commentText': commentText,
        'timestamp':
            FieldValue.serverTimestamp(), // Use server timestamp for consistency
      });

      _commentController.clear(); // Clear the text field after posting
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted successfully!')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: ${e.message}')),
        );
      }
      print('Firebase Error posting comment: ${e.code} - ${e.message}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
      print('Generic Error posting comment: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPostingComment = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: const Text('Comments', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 20),
        Expanded(
          // StreamBuilder listens for real-time updates from Firestore
          child: StreamBuilder<QuerySnapshot>(
            stream:
                _firestore
                    .collection('comments')
                    .orderBy(
                      'timestamp',
                      descending: true,
                    ) // Order comments by most recent
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No comments yet. Be the first to comment!'),
                );
              }

              // Display comments in a ListView
              return ListView.builder(
                reverse: true, // Show most recent comments at the bottom
                padding: const EdgeInsets.all(16.0),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final DocumentSnapshot doc = snapshot.data!.docs[index];
                  final Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;

                  final String userName = data['userName'] ?? 'Anonymous';
                  final String commentText =
                      data['commentText'] ?? 'No comment text';
                  final Timestamp? timestamp = data['timestamp'] as Timestamp?;

                  // Format timestamp for display
                  String timeAgo = '';
                  if (timestamp != null) {
                    final DateTime dateTime = timestamp.toDate();
                    final Duration difference = DateTime.now().difference(
                      dateTime,
                    );
                    if (difference.inMinutes < 1) {
                      timeAgo = 'just now';
                    } else if (difference.inHours < 1) {
                      timeAgo = '${difference.inMinutes}m ago';
                    } else if (difference.inDays < 1) {
                      timeAgo = '${difference.inHours}h ago';
                    } else {
                      timeAgo = '${difference.inDays}d ago';
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 18,
                                color: Colors.blueGrey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                timeAgo,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            commentText,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Input area for new comments
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                  ),
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                ),
              ),
              const SizedBox(width: 10),
              _isPostingComment
                  ? const CircularProgressIndicator()
                  : FloatingActionButton(
                    onPressed: _addComment,
                    mini: true,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
