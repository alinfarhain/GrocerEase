import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all Supabase operations for the pantry_items table.
class PantryService {
  static final _supabase = Supabase.instance.client;

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Returns all pantry OR fridge items for the current user,
  /// ordered by expiry date ascending (soonest first, nulls last).
  static Future<List<Map<String, dynamic>>> getItems(String storageType) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _supabase
        .from('pantry_items')
        .select()
        .eq('user_id', userId)
        .eq('storage_type', storageType)
        .order('expiry_date', ascending: true, nullsFirst: false);

    return (rows as List).map((r) => _fromRow(r)).toList();
  }

  // ── CREATE ────────────────────────────────────────────────────────────────

  /// Inserts a new pantry item and returns the created row as a local map.
  static Future<Map<String, dynamic>> addItem({
    required String name,
    required String quantity,
    DateTime? expiryDate,
    required String storageType,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final payload = {
      'user_id'     : userId,
      'name'        : name.trim(),
      'quantity'    : quantity.trim(),
      'expiry_date' : expiryDate != null ? _fmtDate(expiryDate) : null,
      'storage_type': storageType,
    };

    final inserted = await _supabase
        .from('pantry_items')
        .insert(payload)
        .select()
        .single();

    return _fromRow(inserted);
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────

  /// Updates name, quantity, and expiry for an existing item.
  static Future<Map<String, dynamic>> updateItem({
    required String id,
    required String name,
    required String quantity,
    DateTime? expiryDate,
  }) async {
    final updated = await _supabase
        .from('pantry_items')
        .update({
      'name'        : name.trim(),
      'quantity'    : quantity.trim(),
      'expiry_date' : expiryDate != null ? _fmtDate(expiryDate) : null,
    })
        .eq('id', id)
        .select()
        .single();

    return _fromRow(updated);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  static Future<void> deleteItem(String id) async {
    await _supabase.from('pantry_items').delete().eq('id', id);
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  /// Converts a Supabase row → the local map shape used by the UI.
  static Map<String, dynamic> _fromRow(Map<String, dynamic> row) {
    DateTime? expiry;
    if (row['expiry_date'] != null) {
      expiry = DateTime.tryParse(row['expiry_date'].toString());
    }
    return {
      'id'          : row['id'] as String,
      'name'        : row['name'] as String,
      'quantity'    : row['quantity'] as String,
      'expiry'      : expiry,           // DateTime? — null if no expiry set
      'storage_type': row['storage_type'] as String,
    };
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}