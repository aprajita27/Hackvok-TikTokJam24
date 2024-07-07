import 'dart:io';

import 'package:flutter/material.dart';
import 'package:example/services/post_service.dart';
import 'package:example/utils/const.dart';
import 'package:example/utils/firebase/firebase.dart';
import 'package:example/view/screens/mainscreen.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ProfileViewModel extends ChangeNotifier {
  //Services
  PostService postService = PostService();

  //Keys
  GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  // GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  //Variables
  bool loading = false;
  File? mediaUrl;
  final picker = ImagePicker();
  File? userDp;
  String? imgLink;

  ImageCropper imageCropper = ImageCropper();

  //Functions
  pickImage(BuildContext context, {bool camera = false}) async {
    loading = true;
    notifyListeners();
    try {
      XFile? pickedFile = await picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
      );
      CroppedFile? croppedFile = await imageCropper.cropImage(
        sourcePath: pickedFile!.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1), //[
        //   CropAspectRatioPreset.square,
        //   CropAspectRatioPreset.ratio3x2,
        //   CropAspectRatioPreset.original,
        //   CropAspectRatioPreset.ratio4x3,
        //   CropAspectRatioPreset.ratio16x9
        // ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Constants.lightAccent,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
          ),
        ],
      );
      mediaUrl = File(croppedFile!.path);
      loading = false;
      notifyListeners();
    } catch (e) {
      loading = false;
      notifyListeners();
      showInSnackBar('Cancelled', context);
    }
  }

  uploadProfilePicture(BuildContext context) async {
    if (mediaUrl == null) {
      showInSnackBar('Please select an image', context);
    } else {
      try {
        loading = true;
        notifyListeners();
        await postService.uploadProfilePicture(
            mediaUrl!, firebaseAuth.currentUser!);
        loading = false;
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (_) => MainScreen()));
        notifyListeners();
      } catch (e) {
        print(e);
        loading = false;
        showInSnackBar('Uploaded successfully! $e', context);
        notifyListeners();
      }
    }
  }

  resetPost() {
    mediaUrl = null;
    notifyListeners();
  }

  void showInSnackBar(String value, BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final snackBar = SnackBar(content: Text(value));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // void showInSnackBar(String value) {
  //   scaffoldKey.currentState.removeCurrentSnackBar();
  //   scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(value)));
  // }
}
