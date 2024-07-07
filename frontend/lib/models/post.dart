import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  late String id;
  late String postId;
  late String ownerId;
  late String username;
  late String description;
  late String mediaUrl;
  late String musicName;
  late String artistName;
  late String previewImage;
  late String originalAudioUrl; // Field for original audio URL
  late String selectedAudioUrl; // Field for selected audio URL
  late String original_audio_key; // Field for original audio key
  late List<Map<String, String>>
      translatedAudioUrl; // Array of maps (key-value pairs)

  late Timestamp timestamp;

  PostModel({
    required this.id,
    required this.postId,
    required this.ownerId,
    required this.description,
    required this.mediaUrl,
    required this.musicName,
    required this.artistName,
    required this.previewImage,
    required this.originalAudioUrl, // Include originalAudioUrl in constructor
    required this.selectedAudioUrl, // Include selectedAudioUrl in constructor
    required this.original_audio_key, // Include originalAudioKey in constructor
    required this.translatedAudioUrl, // Include translatedAudioUrls in constructor
    required this.username,
    required this.timestamp,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      postId: json['postId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      username: json['username'] ?? '',
      description: json['description'] ?? '',
      mediaUrl: json['mediaUrl'] ?? '',
      musicName: json['musicName'] ?? '',
      artistName: json['artistName'] ?? '',
      previewImage: json['previewImage'] ?? '',
      originalAudioUrl:
          json['originalAudioUrl'] ?? '', // Handle originalAudioUrl from JSON
      selectedAudioUrl:
          json['selectedAudioUrl'] ?? '', // Handle selectedAudioUrl from JSON
      original_audio_key:
          json['original_audio_key'] ?? '', // Handle originalAudioKey from JSON
      translatedAudioUrl: (json['translatedAudioUrl'] as List<dynamic>?)
          ?.map((item) => Map<String, String>.from(item as Map))
          .toList() ??
          [],
      timestamp: json['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'postId': postId,
      'ownerId': ownerId,
      'username': username,
      'description': description,
      'mediaUrl': mediaUrl,
      'musicName': musicName,
      'artistName': artistName,
      'previewImage': previewImage,
      'originalAudioUrl': originalAudioUrl,
      'selectedAudioUrl': selectedAudioUrl,
      'original_audio_key': original_audio_key,
      'translatedAudioUrl': translatedAudioUrl
          .map((item) => Map<String, String>.from(item))
          .toList(),
      'timestamp': timestamp,
    };
    return data;
  }
}
