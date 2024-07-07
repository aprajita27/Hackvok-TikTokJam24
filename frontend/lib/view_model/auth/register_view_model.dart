import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:example/services/auth_service.dart';
import 'package:example/view/auth/profile_picture.dart';

class RegisterViewModel extends ChangeNotifier {
  Map<String, String> languageCodes = {
    'English': 'en',
    'Spanish': 'es',
    'Chinese': 'zh-cn',
    // Add more languages and their codes as needed
  };

  // GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool validate = false;
  bool loading = false;
  String? username, email, country, password, cPassword, preferredLanguage;
  List<String> knownLanguages = [];
  FocusNode usernameFN = FocusNode();
  FocusNode emailFN = FocusNode();
  FocusNode countryFN = FocusNode();
  FocusNode passFN = FocusNode();
  FocusNode cPassFN = FocusNode();
  FocusNode preferredLanguageFN = FocusNode();
  FocusNode knownLanguagesFN = FocusNode();
  AuthService auth = AuthService();

  void register(BuildContext context) async {
    FormState? form = formKey.currentState;
    form!.save();
    if (!form.validate()) {
      validate = true;
      notifyListeners();
      showInSnackBar(
          'Please fix the errors in red before submitting.', context);
    } else {
      if (password == cPassword) {
        loading = true;
        notifyListeners();
        try {

          // Mapping the selected language to its code
          String preferredLanguageCode = languageCodes[preferredLanguage!]!;
          List<String> knownLanguagesCodes = knownLanguages.map((lang) => languageCodes[lang]!).toList();

          bool success = await auth.createUser(
            name: username!,
            email: email!,
            password: password!,
            country: country!,
            preferredLanguage: preferredLanguageCode,
            knownLanguages: knownLanguagesCodes,
          );
          print(success);
          if (success) {
            Navigator.of(context).pushReplacement(
                CupertinoPageRoute(builder: (_) => UploadDP()));
          }
        } catch (e) {
          loading = false;
          notifyListeners();
          print(e);
          showInSnackBar(
              '${auth.handleFirebaseAuthError(e.toString())}', context);
        }
        loading = false;
        notifyListeners();
      } else {
        showInSnackBar('The passwords does not match', context);
      }
    }
  }

  setEmail(val) {
    print(val);
    email = val;
    notifyListeners();
  }

  setPassword(val) {
    print(val);
    password = val;
    notifyListeners();
  }

  setName(val) {
    print(val);
    username = val;
    notifyListeners();
  }

  setConfirmPass(val) {
    print(val);
    cPassword = val;
    notifyListeners();
  }

  setCountry(val) {
    print(val);
    country = val;
    notifyListeners();
  }

  setPreferredLanguage(val) {
    print(val);
    preferredLanguage = val;
    notifyListeners();
  }

  setKnownLanguages(List<String> val) {
    print(val);
    knownLanguages = val;
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
