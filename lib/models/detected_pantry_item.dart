import 'package:uuid/uuid.dart';

class DetectedPantryItem {
  final String tempId;
  final String itemName;
  final String? brand;
  final String category;
  double quantity;
  String unit;
  String usageState;
  int usagePercent;
  String storageLocation;
  final String? storageAdvice;
  final int? shelfLifeDays;
  final double detectionConfidence;
  bool isSelected;

  // User-editable expiry (computed from shelfLifeDays by default)
  DateTime? expiryDate;

  DetectedPantryItem({
    String? tempId,
    required this.itemName,
    this.brand,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.usageState,
    required this.usagePercent,
    required this.storageLocation,
    this.storageAdvice,
    this.shelfLifeDays,
    required this.detectionConfidence,
    this.isSelected = true,
    this.expiryDate,
  }) : tempId = tempId ?? const Uuid().v4() {
    // Auto-compute expiry from shelf life
    if (expiryDate == null && shelfLifeDays != null) {
      expiryDate = DateTime.now().add(Duration(days: shelfLifeDays!));
    }
  }

  factory DetectedPantryItem.fromJson(Map<String, dynamic> json) {
    return DetectedPantryItem(
      itemName: json['item_name'] ?? 'Unknown Item',
      brand: json['brand'],
      category: json['category'] ?? 'other',
      quantity: (json['quantity'] ?? 1).toDouble(),
      unit: json['unit'] ?? 'pieces',
      usageState: json['usage_state'] ?? 'full',
      usagePercent: (json['usage_percent'] ?? 100).toInt(),
      storageLocation: json['storage_location'] ?? 'pantry',
      storageAdvice: json['storage_advice'],
      shelfLifeDays: json['shelf_life_days'],
      detectionConfidence: (json['detection_confidence'] ?? 0.8).toDouble(),
    );
  }

  Map<String, dynamic> toSupabaseRow(String userId) {
    return {
      'user_id': userId,
      'item_name': itemName,
      'brand': brand,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'usage_state': usageState,
      'usage_percent': usagePercent,
      'storage_location': storageLocation,
      'storage_advice': storageAdvice,
      'shelf_life_days': shelfLifeDays,
      'expiry_date': expiryDate?.toIso8601String().split('T').first,
      'detection_source': 'camera_scan',
      'detection_confidence': detectionConfidence,
      'is_consumed': false,
    };
  }
}