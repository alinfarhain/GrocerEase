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

  // ── Budget (global, shared between Profile and GroceryList) ───────────────
  double _budget = 400.0;

  ThemeData get theme => _theme;
  AppCurrency get currency => _currency;
  String get dietaryPreference => _dietaryPreference;
  double get budget => _budget;

  bool get isFirstTime {
    return sharedPrefs.getBool(AppConstants.isFirstTimeKey) ?? true;
  }

  bool get isLoggedIn {
    return sharedPrefs.getBool(AppConstants.isLoggedInKey) ?? false;
  }

  int _currentTabIndex = 0;

  int get currentTabIndex => _currentTabIndex;

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

  /// Full logout — clears Supabase flag + resets all in-memory state so the
  /// next user who logs in starts with a clean slate.
  void logout() {
    sharedPrefs.setBool(AppConstants.isLoggedInKey, false);
    _dietaryPreference = 'None';
    _currency = AppCurrency.supported.first;
    _budget = 400.0;
    _currentTabIndex = 0;
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

  /// Update budget globally so both Profile and GroceryList stay in sync
  /// without either screen needing to reload from the database.
  void setBudget(double value) {
    _budget = value;
    notifyListeners();
  }
}