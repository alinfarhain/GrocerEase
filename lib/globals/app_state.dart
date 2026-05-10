import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'themes.dart';
import 'app_constants.dart';
import '../main.dart';

class AppState extends ChangeNotifier {
  AppState();

  factory AppState.of(BuildContext context, {bool listen = true}) {
    return Provider.of<AppState>(context, listen: listen);
  }

  ThemeData _theme = lightTheme;

  ThemeData get theme {
    return _theme;
  }

  bool get isFirstTime {
    return sharedPrefs.getBool(AppConstants.isFirstTimeKey) ?? true;
  }

  bool get isLoggedIn {
    return sharedPrefs.getBool(AppConstants.isLoggedInKey) ?? false;
  }

  int _currentTabIndex = 2; // Default to Grocery List tab index

  int get currentTabIndex {
    return _currentTabIndex;
  }

  void changeTheme(ThemeData theme) {
    _theme = theme;
    notifyListeners();
  }

  void setFirstTime(bool value) {
    sharedPrefs.setBool(AppConstants.isFirstTimeKey, value);
    notifyListeners();
  }

  void setLoggedIn(bool value) {
    sharedPrefs.setBool(AppConstants.isLoggedInKey, value);
    notifyListeners();
  }

  void logout() {
    sharedPrefs.setBool(AppConstants.isLoggedInKey, false);
    notifyListeners();
  }

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }
}
