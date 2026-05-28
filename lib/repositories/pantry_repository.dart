import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/detected_pantry_item.dart';

class PantryRepository {
  final _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

  // ── AI scan insert ────────────────────────────────────────────────────────

  Future<void> addDetectedItems(List<DetectedPantryItem> items) async {
    final rows = items
        .where((item) => item.isSelected)
        .map((item) => item.toSupabaseRow(_userId))
        .toList();

    if (rows.isEmpty) return;
    await _supabase.from('pantry_items').insert(rows);
  }

  // ── Manual form insert ────────────────────────────────────────────────────

  Future<void> addManualItem({
    required String itemName,
    String? brand,
    required String category,
    required double quantity,
    required String unit,
    required String usageState,
    required int usagePercent,
    required String storageLocation,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? notes,
  }) async {
    await _supabase.from('pantry_items').insert({
      'user_id':          _userId,
      'item_name':        itemName,
      'brand':            brand,
      'category':         category,
      'quantity':         quantity,
      'unit':             unit,
      'usage_state':      usageState,
      'usage_percent':    usagePercent,
      'storage_location': storageLocation,
      'purchase_date':    purchaseDate?.toIso8601String().split('T').first,
      'expiry_date':      expiryDate?.toIso8601String().split('T').first,
      'notes':            notes,
      'detection_source': 'manual',
      'is_consumed':      false,
    });
  }

  // ── Duplicate check ───────────────────────────────────────────────────────

  Future<List<String>> findExistingItems(List<String> itemNames) async {
    final response = await _supabase
        .from('pantry_items')
        .select('item_name')
        .eq('user_id', _userId)
        .eq('is_consumed', false)
        .inFilter('item_name', itemNames);

    return (response as List)
        .map((row) => row['item_name'] as String)
        .toList();
  }
}