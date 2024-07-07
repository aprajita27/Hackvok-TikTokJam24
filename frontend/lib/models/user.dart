import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  late String username;
  late String email;
  late String photoUrl;
  late String country;
  late String bio;
  late String id;
  late Timestamp signedUpAt;
  late Timestamp lastSeen;
  late bool isOnline;
  late List<String> known; // Array of known languages
  late String preferred; // Preferred language

  UserModel({
    required this.username,
    required this.email,
    required this.id,
    required this.photoUrl,
    required this.signedUpAt,
    required this.isOnline,
    required this.lastSeen,
    required this.bio,
    required this.country,
    required this.known,
    required this.preferred,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    username = json['username'] ?? '';
    email = json['email'] ?? '';
    country = json['country'] ?? '';
    photoUrl = json['photoUrl'] ?? '';
    signedUpAt = json['signedUpAt'] != null
        ? (json['signedUpAt'] as Timestamp)
        : Timestamp.now();
    isOnline = json['isOnline'] ?? false;
    lastSeen = json['lastSeen'] != null
        ? (json['lastSeen'] as Timestamp)
        : Timestamp.now();
    bio = json['bio'] ?? '';
    id = json['id'] ?? '';
    known = List<String>.from(json['known'] ?? []);
    preferred = json['preferred'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'username': this.username,
      'country': this.country,
      'email': this.email,
      'photoUrl': this.photoUrl,
      'bio': this.bio,
      'signedUpAt': this.signedUpAt,
      'isOnline': this.isOnline,
      'lastSeen': this.lastSeen,
      'id': this.id,
      'known': this.known,
      'preferred': this.preferred,
    };
    return data;
  }
}
