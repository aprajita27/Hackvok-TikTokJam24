import 'package:flutter/material.dart';

class Constants {
  //App related strings
  static String appName = "Flutter TikTok";

  //Colors for theme

  static MaterialColor lightPrimary = MaterialColor(0xfff3f4f9, {});
  static MaterialColor darkPrimary = MaterialColor(0xff2B2B2B, {});

  static Color lightAccent = Colors.red;

  static Color darkAccent = Colors.red;

  static Color lightBG = Color(0xfff3f4f9);
  static Color darkBG = Color(0xff2B2B2B);

  static ThemeData lightTheme = ThemeData(
    // backgroundColor: lightBG,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: lightPrimary, // Replace with your desired primary color
      backgroundColor: lightBG, // Replace with your desired background color
      accentColor: lightAccent, // Replace with your desired accent color
    ),
    // primaryColor: lightPrimary,
    // accentColor: lightAccent,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: lightAccent, // Use textSelectionTheme.cursorColor
    ),
    scaffoldBackgroundColor: lightBG,
    bottomAppBarTheme: BottomAppBarTheme(
      elevation: 0,
      color: lightBG,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSwatch(
      brightness: Brightness.dark,
      primarySwatch: darkPrimary, // Replace with your desired primary color
      backgroundColor: darkBG, // Replace with your desired background color
      accentColor: darkAccent, // Replace with your desired accent color
    ),
    // backgroundColor: darkBG,
    // primaryColor: darkPrimary,
    // accentColor: darkAccent,
    scaffoldBackgroundColor: darkBG,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: darkAccent, // Use textSelectionTheme.cursorColor
    ),
    bottomAppBarTheme: BottomAppBarTheme(
      elevation: 0,
      color: darkBG,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      titleTextStyle: TextStyle(
        color: lightBG,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }
}
