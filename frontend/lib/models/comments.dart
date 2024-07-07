import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  late String username;
  late String comment;
  late Timestamp timestamp;
  late String userDp;
  late String userId;

  CommentModel({
    required this.username,
    required this.comment,
    required this.timestamp,
    required this.userDp,
    required this.userId,
  });

  CommentModel.fromJson(Map<String, dynamic> json) {
    username = json['username'];
    comment = json['comment'];
    timestamp = json['timestamp'];
    userDp = json['userDp'];
    userId = json['userId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['username'] = this.username;
    data['comment'] = this.comment;
    data['timestamp'] = this.timestamp;
    data['userDp'] = this.userDp;
    data['userId'] = this.userId;
    return data;
  }
}
