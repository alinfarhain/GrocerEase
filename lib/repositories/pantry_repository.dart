import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/detected_pantry_item.dart';

class PantryRepository {
  final _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

  Future<void> addDetectedItems(List<DetectedPantryItem> items) async {
    final rows = items
        .where((item) => item.isSelected)
        .map((item) => item.toSupabaseRow(_userId))
        .toList();

    if (rows.isEmpty) return;

    await _supabase.from('pantry_items').insert(rows);
  }

  // Check for duplicates before inserting
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