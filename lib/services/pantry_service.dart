import 'package:supabase_flutter/supabase_flutter.dart';

class PantryService {
  static final _supabase = Supabase.instance.client;

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Pantry tab  → storage_location IN ('pantry', 'counter')
  /// Fridge tab  → storage_location IN ('fridge', 'freezer')
  static Future<List<Map<String, dynamic>>> getItems(String tab) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final locations = tab == 'pantry'
        ? ['pantry', 'counter']
        : ['fridge', 'freezer'];

    final rows = await _supabase
        .from('pantry_items_view')      // use view so days_until_expiry is computed
        .select()
        .eq('user_id', userId)
        .eq('is_consumed', false)
        .inFilter('storage_location', locations)
        .order('expiry_date', ascending: true, nullsFirst: false);

    return (rows as List).map((r) => _fromRow(r)).toList();
  }

  // ── CREATE ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> addItem({
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
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final inserted = await _supabase
        .from('pantry_items')
        .insert({
      'user_id':          userId,
      'item_name':        itemName.trim(),
      'brand':            brand?.trim().isEmpty ?? true ? null : brand?.trim(),
      'category':         category,
      'quantity':         quantity,
      'unit':             unit,
      'usage_state':      usageState,
      'usage_percent':    usagePercent,
      'storage_location': storageLocation,
      'purchase_date':    purchaseDate != null ? _fmtDate(purchaseDate) : null,
      'expiry_date':      expiryDate != null ? _fmtDate(expiryDate) : null,
      'notes':            notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      'detection_source': 'manual',
      'is_consumed':      false,
    })
        .select()
        .single();

    return _fromRow(inserted);
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> updateItem({
    required String id,
    required String itemName,
    required double quantity,
    required String unit,
    String? brand,
    String? usageState,
    String? storageLocation,
    DateTime? expiryDate,
    String? notes,
  }) async {
    final updated = await _supabase
        .from('pantry_items')
        .update({
      'item_name':        itemName.trim(),
      'brand':            brand,
      'quantity':         quantity,
      'unit':             unit,
      'usage_state':      usageState ?? 'full',
      'usage_percent':    _stateToPercent(usageState ?? 'full'),
      'storage_location': storageLocation ?? 'pantry',
      'expiry_date':      expiryDate != null ? _fmtDate(expiryDate) : null,
      'notes':            notes,
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

  // ── MARK CONSUMED ─────────────────────────────────────────────────────────

  static Future<void> markConsumed(String id) async {
    await _supabase
        .from('pantry_items')
        .update({'is_consumed': true})
        .eq('id', id);
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  static Map<String, dynamic> _fromRow(Map<String, dynamic> row) {
    DateTime? expiry;
    DateTime? purchaseDate;

    if (row['expiry_date'] != null) {
      expiry = DateTime.tryParse(row['expiry_date'].toString());
    }
    if (row['purchase_date'] != null) {
      purchaseDate = DateTime.tryParse(row['purchase_date'].toString());
    }

    return {
      'id':               row['id'] as String,
      'item_name':        row['item_name'] as String? ?? '',
      'brand':            row['brand'] as String?,
      'category':         row['category'] as String? ?? 'other',
      'quantity':         (row['quantity'] as num?)?.toDouble() ?? 1.0,
      'unit':             row['unit'] as String? ?? 'pieces',
      'usage_state':      row['usage_state'] as String? ?? 'full',
      'usage_percent':    (row['usage_percent'] as num?)?.toInt() ?? 100,
      'storage_location': row['storage_location'] as String? ?? 'pantry',
      'storage_advice':   row['storage_advice'] as String?,
      'expiry':           expiry,
      'purchase_date':    purchaseDate,
      'days_until_expiry':(row['days_until_expiry'] as num?)?.toInt(),
      'detection_source': row['detection_source'] as String? ?? 'manual',
      'notes':            row['notes'] as String?,
      'is_consumed':      row['is_consumed'] as bool? ?? false,
    };
  }

  static int _stateToPercent(String state) => switch (state) {
    'full'         => 100,
    'half'         => 50,
    'quarter'      => 25,
    'almost_empty' => 10,
    _              => 100,
  };

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}