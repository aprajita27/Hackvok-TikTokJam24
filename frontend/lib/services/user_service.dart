import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:example/models/user.dart';
import 'package:example/services/services.dart';
import 'package:example/utils/firebase/firebase.dart';

class UserService extends Service {
  String currentUid() {
    return firebaseAuth.currentUser!.uid;
  }


  setUserStatus(bool isOnline) {
    var user = firebaseAuth.currentUser;
    if (user != null) {
      usersRef
          .doc(user.uid)
          .update({'isOnline': isOnline, 'lastSeen': Timestamp.now()});
    }
  }

  Future<UserModel?> getUserData() async {
    try {
      String? uid = currentUid();
      if (uid == null) {
        throw Exception("User not logged in");
      }

      var doc = await usersRef.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        throw Exception("User not found");
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }


  Future<bool> updateProfile({File? image, String? username, String? bio}) async {
    try {
      var doc = await usersRef.doc(currentUid()).get();
      var user = UserModel.fromJson(doc.data() as Map<String, dynamic>);

      if (username != null) {
        user!.username = username;
      }

      if (bio != null) {
        user!.bio = bio;
      }

      if (image != null) {
        user!.photoUrl = await uploadImage('profilePic', image);
      }

      await usersRef.doc(currentUid()).update({
        'username': user!.username,
        'bio': user!.bio,
        'photoUrl': user!.photoUrl ?? '',
      });

      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
}
