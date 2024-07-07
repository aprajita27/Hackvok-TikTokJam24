import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:example/utils/file_utils.dart';
import 'package:example/utils/firebase/firebase.dart';
import 'package:uuid/uuid.dart';

abstract class Service {
  final uuid = Uuid();

  Future<String> uploadImage(String folderName, File file) async {
    try {
      String ext = FileUtils.getFileExtension(file);
      Reference ref = FirebaseStorage.instance.ref().child('$folderName/${uuid.v4()}.$ext');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      String downloadURL = await snapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow; // Rethrow the exception for higher-level error handling
    }
  }
}
