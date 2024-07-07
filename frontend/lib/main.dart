// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:example/view/screens/mainscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in_dartio/google_sign_in_dartio.dart';

import 'package:example/view/auth/auth_chooser.dart';
import 'package:provider/provider.dart';
import 'package:example/utils/config.dart';
import 'package:example/utils/const.dart';
import 'package:example/utils/provider/provider.dart';
// import 'auth.dart';
import 'firebase_options.dart';

/// Requires that a Firebase local emulator is running locally.
/// See https://firebase.flutter.dev/docs/auth/start/#optional-prototype-and-test-with-firebase-local-emulator-suite
bool shouldUseFirebaseEmulator = false;

late final FirebaseApp app;
late final FirebaseAuth auth;

// Requires that the Firebase Auth emulator is running locally
// e.g via `melos run firebase:emulator`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // We're using the manual installation on non-web platforms since Google sign in plugin doesn't yet support Dart initialization.
  // See related issue: https://github.com/flutter/flutter/issues/96391

  // We store the app and auth to make testing with a named instance easier.
  app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  auth = FirebaseAuth.instanceFor(app: app);

  if (shouldUseFirebaseEmulator) {
    await auth.useAuthEmulator('localhost', 9099);
  }

  if (!kIsWeb && Platform.isWindows) {
    await GoogleSignInDart.register(
      clientId:
          '406099696497-g5o9l0blii9970bgmfcfv14pioj90djd.apps.googleusercontent.com',
    );
  }

  runApp(MyApp());
}

/// The entry point of the application.
///
/// Returns a [MaterialApp].
///
class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: Constants.appName,
        theme: Constants.darkTheme,
        home: AuthExampleApp(),
      ),
    );
  }
}

class AuthExampleApp extends StatelessWidget {
  const AuthExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Example App',
      theme: ThemeData(primarySwatch: Colors.amber),
      home: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                // Visibility(
                //   visible: constraints.maxWidth >= 1200,
                //   child: Expanded(
                //     child: Container(
                //       height: double.infinity,
                //       color: Theme.of(context).colorScheme.primary,
                //       child: Center(
                //         child: Column(
                //           mainAxisAlignment: MainAxisAlignment.center,
                //           children: [
                //             Text(
                //               'Firebase Auth Desktop',
                //               style: Theme.of(context).textTheme.headlineMedium,
                //             ),
                //           ],
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                SizedBox(
                  width: constraints.maxWidth >= 1200
                      ? constraints.maxWidth / 2
                      : constraints.maxWidth,
                  child: StreamBuilder<User?>(
                    stream: auth.authStateChanges(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return MainScreen();
                      }
                      return AuthChooser();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
