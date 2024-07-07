import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esys_flutter_share_plus/esys_flutter_share_plus.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter/log.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:example/models/post.dart';
import 'package:example/models/user.dart';
import 'package:example/services/services.dart';
import 'package:example/utils/firebase/firebase.dart';
import 'package:uuid/uuid.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:example/utils/audio_options.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';

class PostService extends Service {
  UserModel? user;
  String postId = Uuid().v4();

  currentUserId() {
    return firebaseAuth.currentUser!.uid;
  }

  Future<void> uploadProfilePicture(File image, User user) async {
    // Future<void> uploadProfilePicture(File image, User user) async {
      try {
        String link = await uploadImage('profilePics/${user.uid}', image);
        var ref = usersRef.doc(user.uid);
        await ref.update({
          "photoUrl": link ?? 'https://images.app.goo.gl/NGh74PqviFBNwFV4A',
        });
      } catch (e) {
        print('Error uploading profile picture: $e');
        throw e; // Re-throwing the error for higher-level handling if needed
      }
    // }
  }

  Future<double> getVideoDuration(File videoFile) async {
    try {
      // Run FFprobe to get media information
      String command = '-v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 ${videoFile.path}';
      print("FFprobe command: $command");

      final session = await FFprobeKit.execute(command);
      final returnCode = await session.getReturnCode();
      print("Return code: $returnCode");

      // final logs = await session.getLogs();
      // print("Session logs:");
      // for (var log in logs) {
      //   print("${log.getLevel()}: ${log.getMessage()}");
      // }

      // final output = await session.getOutput();
      // print("Session output: $output");

      if (ReturnCode.isSuccess(returnCode)) {
        final output = await session.getOutput();
        print("FFprobe output: $output");

        if (output != null && output.isNotEmpty) {
          final duration = double.tryParse(output.trim());
          if (duration != null) {
            print("Parsed duration: $duration seconds");
            return duration;
          }
        }
      } else {
        print("Error executing FFprobe command. Return code: $returnCode");
        throw Exception('Error executing FFprobe command');
      }

      print("Failed to parse video duration");
      throw Exception('Failed to parse video duration');
    } catch (e) {
      print('Error getting video duration: $e');
      rethrow;
    }
  }

  Future<void> callTranscribeApi(String postId) async {
    print("calling transcribe");
    final url = 'http://192.168.1.88:5002/transcribe';
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'post_id': postId});

    try {
      print("in try");
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        print('API call successful: ${response.body}');
      } else {
        print('Failed to call API: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling API: $e');
    }
  }

  Future<void> uploadPostWithAudioOption(
      File videoFile,
      File previewImage,
      String description,
      String musicName,
      String artistName,
      Uint8List audioBytes,
      AudioOption audioOption,
      ) async {
    try {
      try {
        // Clean up temporary files before starting a new task
        await _cleanupTempFiles();

        // Other upload logic
        // ...
      } catch (e) {
        print('Error uploading post with audio option: $e');
        rethrow;
      }
      // Fetch current user details
      DocumentSnapshot doc = await usersRef.doc(firebaseAuth.currentUser!.uid).get();
      user = UserModel.fromJson(doc.data() as Map<String, dynamic>);

      // Temporary directory for processing files
      final dir = await getTemporaryDirectory();

      // Upload video file to Firebase Storage
      String videoUrl = await uploadVideo(videoFile);

      // Variables for storing audio URLs
      String originalAudioUrl = '';
      String selectedAudioUrl = '';

      print("Audio option: $audioOption");

      // Handle different audio options
      switch (audioOption) {
        case AudioOption.original:
        // Extract audio from original video
          originalAudioUrl = await extractAudioFromVideo(videoFile, dir);
          break;
        case AudioOption.selected:
        // Upload selected music file after trimming to match video length
          File selectedAudioFile = await writeAudioBytesToFile(audioBytes, dir);
          selectedAudioUrl = await trimAudioToVideoLength(selectedAudioFile, videoFile, dir);
          break;
        case AudioOption.both:
        // Extract audio from original video and upload selected music file after trimming
          originalAudioUrl = await extractAudioFromVideo(videoFile, dir);
          File selectedAudioFile = await writeAudioBytesToFile(audioBytes, dir);
          selectedAudioUrl = await trimAudioToVideoLength(selectedAudioFile, videoFile, dir);
          break;
        case AudioOption.none:
        // No audio upload needed
          break;
      }

      // Upload post details to Firestore
      var ref = postRef.doc();
      await ref.set({
        "id": ref.id,
        "postId": ref.id,
        "username": user!.username ?? "",
        "ownerId": firebaseAuth.currentUser!.uid,
        "mediaUrl": videoUrl,
        "originalAudioUrl": originalAudioUrl,
        "selectedAudioUrl": selectedAudioUrl,
        "musicName": musicName,
        "artistName": artistName,
        "description": description,
        "previewImage": await uploadImage('prevImage', previewImage),
        "timestamp": Timestamp.now(),
      }).catchError((e) {
        print(e);
      });
      // Call API after post is successfully uploaded
      await callTranscribeApi(ref.id);
    } catch (e) {
      print('Error uploading post with audio option: $e');
      rethrow;
    }
  }

  Future<void> _cleanupTempFiles() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      List<FileSystemEntity> files = tempDir.listSync(recursive: false);
      for (var file in files) {
        await file.delete();
        print('Deleted temporary file: ${file.path}');
      }
    } catch (e) {
      print('Error cleaning up temporary files: $e');
    }
  }

  Future<String> trimAudioToVideoLength(File audioFile, File videoFile, Directory tempDir) async {
    try {
      // Get video duration
      final videoDuration = await getVideoDuration(videoFile);

      // Define output trimmed audio path
      final trimmedAudioPath = '${tempDir.path}/${Uuid().v4()}_trimmed_audio.mp3';

      // Execute FFmpeg command to trim audio to video length
      print("selected audio path: ${audioFile.path}");
      String ffmpegCommand = '-i ${audioFile.path} -t $videoDuration -c copy $trimmedAudioPath';
      await FFmpegKit.execute(ffmpegCommand);

      // Check if trimmed audio file exists
      File trimmedAudioFile = File(trimmedAudioPath);
      if (!await trimmedAudioFile.exists()) {
        throw Exception('Trimmed audio file does not exist: $trimmedAudioPath');
      }

      // Upload trimmed audio to Firebase Storage
      String audioUrl = await uploadAudioFile(trimmedAudioFile, 'audios');
      return audioUrl;
    } catch (e) {
      print('Error trimming audio to video length: $e');
      rethrow;
    }
  }

  Future<File> writeAudioBytesToFile(Uint8List audioBytes, Directory tempDir) async {
    try {
      final audioPath = '${tempDir.path}/${Uuid().v4()}_selected_audio.mp3';
      final audioFile = File(audioPath);
      await audioFile.writeAsBytes(audioBytes);
      return audioFile;
    } catch (e) {
      print('Error writing audio bytes to file: $e');
      rethrow;
    }
  }

  Future<String> extractAudioFromVideo(File videoFile, Directory tempDir) async {
    try {
      // Define output paths
      final finalAudioPath = '${tempDir.path}/${Uuid().v4()}_original_audio.aac';

      // Check if input video file exists
      if (!videoFile.existsSync()) {
        throw Exception('Input video file does not exist: ${videoFile.path}');
      }

      // Extract audio in AAC format
      String extractCommand = '-i ${videoFile.path} -vn -acodec aac -b:a 128k $finalAudioPath';
      print('Executing FFmpeg extract command: $extractCommand');
      FFmpegSession extractSession = await FFmpegKit.execute('-loglevel verbose $extractCommand');
      List<Log> logs = await extractSession.getLogs();
      print('FFmpeg extract session logs:');
      for (var log in logs) {
        print('${log.getLevel()}: ${log.getMessage()}');
      }

      // Check if the final AAC file exists and has a non-zero size
      File extractedAudioFile = File(finalAudioPath);
      if (!extractedAudioFile.existsSync()) {
        throw Exception('Extracted audio file does not exist: $finalAudioPath');
      }
      if (await extractedAudioFile.length() == 0) {
        throw Exception('Extracted audio file is empty: $finalAudioPath');
      }

      // Upload extracted audio to Firebase Storage
      String audioUrl = await uploadAudioFile(extractedAudioFile, 'audios');
      return audioUrl;
    } catch (e) {
      print('Error extracting audio from video: $e');
      rethrow;
    }
  }


  Future<String> mixAudioWithBackground(String originalAudioUrl, String selectedAudioUrl, Directory tempDir) async {
    try {
      // Download original audio and selected audio
      Uint8List originalAudioBytes = await downloadAudioBytes(originalAudioUrl);
      Uint8List selectedAudioBytes = await downloadAudioBytes(selectedAudioUrl);

      // Write both audios to temporary files
      final originalAudioPath = '${tempDir.path}/_original_audio.mp3';
      final selectedAudioPath = '${tempDir.path}/_selected_audio.mp3';
      await File(originalAudioPath).writeAsBytes(originalAudioBytes);
      await File(selectedAudioPath).writeAsBytes(selectedAudioBytes);

      // Define output mixed audio path
      final mixedAudioPath = '${tempDir.path}/mixed_audio.mp3';

      // Execute FFmpeg command to mix both audios
      String ffmpegCommand = '-i $originalAudioPath -i $selectedAudioPath -filter_complex amix=inputs=2:duration=first:dropout_transition=2 -c:a aac -b:a 192k -f mp4 -y $mixedAudioPath';
      // try{
      await FFmpegKit.execute(ffmpegCommand);
      // print('Mixing Executing FFmpeg command: $ffmpegCommand');

      // Run FFmpeg command with verbose logging
      FFmpegSession session = await FFmpegKit.execute('-loglevel verbose $ffmpegCommand');

      // Get the full output including any error messages
      // String? output = await session.getOutput();
      // print('FFmpeg full output:');
      // print(output);

      // Check the return code of the FFmpeg command
      // ReturnCode? returnCode = await session.getReturnCode();
      // if (ReturnCode.isSuccess(returnCode)) {
      //   print('FFmpeg command succeeded');
      // } else {
      //   print('FFmpeg command failed with return code: $returnCode');
      //
      //   // Get session logs for more detailed information
      //   List<Log> logs = await session.getLogs();
      //   print('FFmpeg session logs:');
      //   for (var log in logs) {
      //     print('${log.getLevel()}: ${log.getMessage()}');
      //   }
      //
      //   throw Exception('FFmpeg command failed. Check logs for details.');
      // }

      // Check if mixed audio file exists
      File mixedAudioFile = File(mixedAudioPath);
      if (!await mixedAudioFile.exists()) {
        throw Exception('Mixed audio file does not exist: $mixedAudioPath');
      }

      // Upload mixed audio to Firebase Storage
      String audioUrl = await uploadAudioFile(mixedAudioFile, 'audios');
      return audioUrl;
    } catch (e) {
      print('Error mixing audio: $e');
      rethrow;
    }
  }

  Future<String> uploadVideo(File videoFile) async {
    try {
      // Define output video path (stripped of audio)
      final tempDir = await getTemporaryDirectory();
      final strippedVideoPath = '${tempDir.path}/${Uuid().v4()}_stripped_video.mp4';

      // Execute FFmpeg command to strip audio from video
      // final FlutterFFmpeg ffmpeg = FlutterFFmpeg();
      // print("Upload Video Path ${videoFile.path}");
      String ffmpegCommand = '-i ${videoFile.path} -an -c:v copy $strippedVideoPath';
      await FFmpegKit.execute(ffmpegCommand);
      // print("Stripped Video Path: ${strippedVideoPath}");

      // Upload stripped video to Firebase Storage
      String videoFileName = Uuid().v4(); // Unique file name for storage
      Reference ref = FirebaseStorage.instance.ref().child('videos/$videoFileName.mp4');
      UploadTask uploadTask = ref.putFile(File(strippedVideoPath));
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      String downloadURL = await snapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading video: $e');
      rethrow;
    }
  }

  Future<String> uploadAudioBytes(Uint8List audioBytes, String folderName) async {
    try {
      String audioFileName = Uuid().v4(); // Unique file name for storage
      Reference ref = FirebaseStorage.instance.ref().child('$folderName/$audioFileName.mp3');
      UploadTask uploadTask = ref.putData(audioBytes);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      String downloadURL = await snapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading audio: $e');
      rethrow;
    }
  }

  Future<String> uploadImage(String folderName, File imageFile) async {
    try {
      String imageName = Uuid().v4(); // Unique file name for storage
      Reference ref = FirebaseStorage.instance.ref().child('$folderName/$imageName.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      String downloadURL = await snapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  Future<String> uploadAudioFile(File audioFile, String folderName) async {
    try {
      print("Audio File Path Upload: ${audioFile.path}");
      String audioFileName = Uuid().v4(); // Unique file name for storage
      Reference ref = FirebaseStorage.instance.ref().child('$folderName/$audioFileName.mp3');
      UploadTask uploadTask = ref.putFile(audioFile);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      String downloadURL = await snapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading audio file: $e');
      rethrow;
    }
  }

  Future<Uint8List> downloadAudioBytes(String audioUrl) async {
    try {
      final http.Response response = await http.get(Uri.parse(audioUrl));
      return response.bodyBytes;
    } catch (e) {
      print('Error downloading audio: $e');
      rethrow;
    }
  }

  Future<void> addComments(
      PostModel video,
      String comment,
      Timestamp timestamp,
      ) async {
    DocumentSnapshot doc = await usersRef.doc(currentUserId()).get();
    user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
    commentRef.doc(video.postId).collection("comments").add({
      "username": user!.username ?? "",
      "comment": comment,
      "timestamp": timestamp,
      "userDp": user!.photoUrl,
      "userId": user!.id,
    });
  }

  Future<void> shareVideo(String videoUrl, String postId, String id) async {
    var request = await HttpClient().getUrl(Uri.parse(videoUrl));
    var response = await request.close();
    Uint8List bytes = await consolidateHttpClientResponseBytes(response);
    await Share.file('FlutterTikTok', 'Video.mp4', bytes, 'video/mp4');
    shareRef.add({
      'userId': currentUserId(),
      'postId': postId,
      'dateCreated': Timestamp.now(),
    });
  }

  Future<Uint8List> downloadMusic(String musicUrl) async {
    try {
      var response = await http.get(Uri.parse(musicUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download music: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading music: $e');
      rethrow;
    }
  }

  Future<File> generatePreviewImage(File videoFile) async {
    try {
      final dir = await getTemporaryDirectory();
      final previewImagePath = '${dir.path}/preview_image.jpg';
      print("Preview Video Path: ${videoFile.path}");
      print("Preview Image Path: ${previewImagePath}");
      String ffmpegCommand = '-i ${videoFile.path} -ss 00:00:01 -vframes 1 $previewImagePath';
      await FFmpegKit.execute(ffmpegCommand);
      File previewImageFile = File(previewImagePath);
      if (await previewImageFile.exists()) {
        return previewImageFile;
      } else {
        throw Exception('Failed to generate preview image.');
      }
    } catch (e) {
      print('Error generating preview image: $e');
      rethrow;
    }
  }
}
