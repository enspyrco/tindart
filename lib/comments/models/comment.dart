import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  Comment(this.userName, this.commentText, this.timestamp);

  final String userName;
  final String commentText;
  final Timestamp? timestamp;
}
