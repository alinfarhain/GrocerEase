import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'themes.dart';
import 'app_constants.dart';
import '../main.dart';
import '../models/grocery_item.dart';

class AppState extends ChangeNotifier {
  AppState();

  factory AppState.of(BuildContext context, {bool listen = true}) {
    return Provider.of<AppState>(context, listen: listen);
  }

  ThemeData _theme = lightTheme;
  AppCurrency _currency = AppCurrency.supported.first;
  String _dietaryPreference = 'None';

  ThemeData get theme => _theme;
  AppCurrency get currency => _currency;
  String get dietaryPreference => _dietaryPreference;

  bool get isFirstTime {
    return sharedPrefs.getBool(AppConstants.isFirstTimeKey) ?? true;
  }

  bool get isLoggedIn {
    return sharedPrefs.getBool(AppConstants.isLoggedInKey) ?? false;
  }

  int _currentTabIndex = 0; // Default to Home tab index

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

  void setCurrency(AppCurrency currency) {
    _currency = currency;
    notifyListeners();
  }

  void setDietaryPreference(String preference) {
    _dietaryPreference = preference;
    notifyListeners();
  }
}
