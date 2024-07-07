import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:example/models/post.dart';
import 'package:example/services/post_service.dart';
import 'package:example/services/user_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress_plus/video_compress_plus.dart';
import 'package:example/utils/audio_options.dart';
import 'package:example/view/screens/mainscreen.dart';


class PostsViewModel extends ChangeNotifier {
  UserService userService = UserService();
  PostService postService = PostService();

  GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool loading = false;
  String? username;
  File? mediaUrl;
  final picker = ImagePicker();
  String? musicName;
  String? artistName;
  String musicUrl = '';
  String? description;
  String? imgLink;
  String? prevLink;
  File? previewImage;
  bool? edit = false;
  String? id;
  AudioOption _audioOption = AudioOption.original;

  setEdit(bool val) {
    edit = val;
    notifyListeners();
  }

  setPost(PostModel post) {
    if (post != null) {
      description = post.description;
      imgLink = post.mediaUrl;
      musicName = post.musicName;
      artistName = post.artistName;
      prevLink = post.previewImage;
      edit = true; // Do you need this line? It sets edit to true then immediately sets it to false.
      edit = false;
      notifyListeners();
    } else {
      edit = false;
      notifyListeners();
    }
  }

  setUsername(String val) {
    username = val;
    notifyListeners();
  }

  setDescription(String? val) {
    description = val;
    notifyListeners();
  }

  setMusicName(String? val) {
    musicName = val;
    notifyListeners();
  }

  void setMusicUrl(String? url) {
    musicUrl = url ?? '';
    notifyListeners();
  }

  void setArtistName(String? name) {
    artistName = name;
    notifyListeners();
  }

  void setAudioOption(AudioOption option) {
    _audioOption = option;
    notifyListeners();
  }

  pickVideo({bool camera = false}) async {
    loading = true;
    notifyListeners();
    try {
      XFile? pickedFile;
      pickedFile = await ImagePicker().pickVideo(
        source: camera ? ImageSource.camera : ImageSource.gallery,
      );
      mediaUrl = File(pickedFile!.path);
      // print("View Model Path: ${pickedFile!.path}");
      //data/user/0/com.example.example/cache/4446df41-3ded-4ce9-a4d2-23790185d547/1000024976.mp4
      //data/user/0/com.example.example/cache/740687bb-52e0-4d77-ac4a-651d23e3efe1/1000025499.mp4
      previewImage = await VideoCompress.getFileThumbnail(
        pickedFile.path,
      );
      loading = false;
      notifyListeners();
    } catch (e) {
      loading = false;
      notifyListeners();
    }
  }

  // Future<void> handleUpload(BuildContext context) async {
  //   try {
  //     loading = true;
  //     notifyListeners();
  //
  //     Uint8List audioBytes;
  //     if (_audioOption != AudioOption.original && musicUrl.isNotEmpty) {
  //       // Download music bytes from the selected URL
  //       audioBytes = await postService.downloadMusic(musicUrl);
  //     } else {
  //       // No music selected or using original audio, handle accordingly
  //       audioBytes = Uint8List(0); // Placeholder for no audio scenario
  //     }
  //
  //     await postService.uploadPostWithAudioOption(
  //       mediaUrl!,
  //       previewImage!,
  //       description ?? '',
  //       musicName ?? '',
  //       artistName ?? '',
  //       audioBytes,
  //       _audioOption,
  //     );
  //
  //     loading = false;
  //     resetPost();
  //     notifyListeners();
  //     showInSnackBar('Uploaded successfully!', context);
  //   } catch (e) {
  //     print(e);
  //     loading = false;
  //     resetPost();
  //     showInSnackBar('Upload failed. Please try again.', context);
  //     notifyListeners();
  //   }
  // }

  Future<void> handleUpload(BuildContext context, VoidCallback navigateToMePage) async {
    try {
      loading = true;
      notifyListeners();

      Uint8List audioBytes;
      if (_audioOption != AudioOption.original && musicUrl.isNotEmpty) {
        // Download music bytes from the selected URL
        audioBytes = await postService.downloadMusic(musicUrl);
      } else {
        // No music selected or using original audio, handle accordingly
        audioBytes = Uint8List(0); // Placeholder for no audio scenario
      }

      await postService.uploadPostWithAudioOption(
        mediaUrl!,
        previewImage!,
        description ?? '',
        musicName ?? '',
        artistName ?? '',
        audioBytes,
        _audioOption,
      );

      loading = false;
      resetPost();
      notifyListeners();
      showInSnackBar('Uploaded successfully!', context);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainScreen()), // Replace with your MainScreen widget
            (route) => false, // Removes all routes below the pushed route
      );
      // Navigate back to MainScreen and switch to the Me page
      // Navigator.popUntil(context, ModalRoute.withName('/'));
      // // You may need to replace '/me' with the actual route name of your Me page
      // Navigator.push(context, MaterialPageRoute(builder: (_) => Me(profileId: userService.currentUid())));
      // navigateToMePage();
      // Navigator.of(context).pushReplacement(
      //     CupertinoPageRoute(builder: (_) =>  Me(profileId: userService.currentUid(),)));
    } catch (e) {
      print(e);
      loading = false;
      resetPost();
      showInSnackBar('Upload failed. Please try again.', context);
      notifyListeners();
    }
  }

  resetPost() {
    mediaUrl = null;
    description = null;
    musicName = '';
    artistName = '';
    musicUrl = '';
    previewImage = null;
    edit = null;
    notifyListeners();
  }

  void showInSnackBar(String value, BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final snackBar = SnackBar(content: Text(value));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
