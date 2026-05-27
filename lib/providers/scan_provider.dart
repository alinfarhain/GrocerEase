import 'package:flutter/material.dart';
import '../../models/detected_pantry_item.dart';

class ScanProvider extends ChangeNotifier {
  List<DetectedPantryItem> _lastDetectedItems = [];
  bool _isScanning = false;

  List<DetectedPantryItem> get lastDetectedItems => _lastDetectedItems;
  bool get isScanning => _isScanning;

  void setScanning(bool value) {
    _isScanning = value;
    notifyListeners();
  }

  void setDetectedItems(List<DetectedPantryItem> items) {
    _lastDetectedItems = items;
    notifyListeners();
  }

  void clear() {
    _lastDetectedItems = [];
    notifyListeners();
  }
}