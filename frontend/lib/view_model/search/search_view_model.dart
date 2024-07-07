import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:example/utils/firebase/firebase.dart';

class SearchViewModel extends ChangeNotifier {
  List<DocumentSnapshot> users = []; //List();
  List<dynamic> filteredUsers = []; //List();
  bool loading = true;

  getUsers() async {
    QuerySnapshot snap = await usersRef.get();
    List<DocumentSnapshot> docs = snap.docs;
    users = docs;
    filteredUsers = docs;
    loading = false;
    notifyListeners();
  }

  search(String query) {
    if (query == "") {
      filteredUsers = users;
    } else {
      List userSearch = users.where((userSnap) {
        final user = userSnap.data();
        String userName = user.toString(); //['username'];
        return userName.toLowerCase().contains(query.toLowerCase());
      }).toList();
      filteredUsers = userSearch;
    }
    notifyListeners();
  }

  removeFromList(index) {
    filteredUsers.removeAt(index);
    notifyListeners();
  }
}
