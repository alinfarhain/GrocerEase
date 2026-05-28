// lib/services/grocery_service.dart
// Changes vs previous version:
//   • addItem() now accepts suggestedPurchaseUnit, priceSource, pantryShortageAmount
//   • _fromRow() maps the three new Supabase columns
//   • updateItem() accepts optional priceSource (for user overrides)
//
// ⚠️  Run the SQL migration in supabase_migration.sql BEFORE deploying this version.

import 'package:supabase_flutter/supabase_flutter.dart';

/// All Supabase CRUD for the grocery_items table.
class GroceryService {
  static final _db = Supabase.instance.client;

  static String? get _userId => _db.auth.currentUser?.id;

  // ── READ ──────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getItems() async {
    if (_userId == null) return [];
    final rows = await _db
        .from('grocery_items')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: true);
    return (rows as List).map((r) => _fromRow(r)).toList();
  }

  // ── CREATE ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> addItem({
    required String name,
    required String quantity,
    double? quantityAmount,
    String? unit,
    double price = 0,
    String category = 'Other',
    String? recipe,
    List<String> dietaryTags = const [],
    // ── New smart-pricing fields ────────────────────────────────────────────
    String? suggestedPurchaseUnit,
    String? priceSource,
    double? pantryShortageAmount,
  }) async {
    if (_userId == null) throw Exception('Not authenticated');
    final inserted = await _db
        .from('grocery_items')
        .insert({
      'user_id': _userId,
      'name': name.trim(),
      'quantity': quantity.trim(),
      'quantity_amount': quantityAmount,
      'unit': unit?.trim(),
      'price': price,
      'category': category.trim(),
      'recipe': recipe?.trim(),
      'dietary_tags': dietaryTags,
      'is_checked': false,
      // New columns (nullable — safe if column doesn't exist yet)
      if (suggestedPurchaseUnit != null)
        'suggested_purchase_unit': suggestedPurchaseUnit.trim(),
      if (priceSource != null) 'price_source': priceSource.trim(),
      if (pantryShortageAmount != null)
        'pantry_shortage_amount': pantryShortageAmount,
    })
        .select()
        .single();
    return _fromRow(inserted);
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> updateItem({
    required String id,
    String? name,
    String? quantity,
    double? quantityAmount,
    String? unit,
    double? price,
    bool? isChecked,
    String? priceSource, // Set to "User" when the user manually overrides price
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name.trim();
    if (quantity != null) payload['quantity'] = quantity.trim();
    if (quantityAmount != null) payload['quantity_amount'] = quantityAmount;
    if (unit != null) payload['unit'] = unit.trim();
    if (price != null) payload['price'] = price;
    if (isChecked != null) payload['is_checked'] = isChecked;
    if (priceSource != null) payload['price_source'] = priceSource.trim();

    final updated = await _db
        .from('grocery_items')
        .update(payload)
        .eq('id', id)
        .select()
        .single();
    return _fromRow(updated);
  }

  static Future<void> toggleChecked(String id, bool isChecked) async {
    await _db
        .from('grocery_items')
        .update({'is_checked': isChecked})
        .eq('id', id);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  static Future<void> deleteItem(String id) async {
    await _db.from('grocery_items').delete().eq('id', id);
  }

  static Future<void> clearChecked() async {
    if (_userId == null) return;
    await _db
        .from('grocery_items')
        .delete()
        .eq('user_id', _userId!)
        .eq('is_checked', true);
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  static Map<String, dynamic> _fromRow(Map<String, dynamic> row) {
    return {
      'id': row['id'] as String,
      'name': row['name'] as String,
      'quantity': row['quantity'] as String? ?? '',
      'quantityAmount': (row['quantity_amount'] as num?)?.toDouble(),
      'unit': row['unit'] as String?,
      'price': (row['price'] as num?)?.toDouble() ?? 0.0,
      'category': row['category'] as String? ?? 'Other',
      'recipe': row['recipe'] as String?,
      'dietaryTags': List<String>.from(row['dietary_tags'] ?? []),
      'isChecked': row['is_checked'] as bool? ?? false,
      // New smart-pricing fields (null-safe for old rows without these columns)
      'suggestedPurchaseUnit': row['suggested_purchase_unit'] as String?,
      'priceSource': row['price_source'] as String?,
      'pantryShortageAmount':
      (row['pantry_shortage_amount'] as num?)?.toDouble(),
    };
  }
}