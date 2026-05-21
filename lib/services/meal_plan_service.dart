import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/meal.dart';

/// Handles all Supabase operations for the meal_plans table.
class MealPlanService {
  static final _supabase = Supabase.instance.client;

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Fetches all meal plans for the current user within [startDate]..[endDate].
  /// Returns a map keyed by 'yyyy-MM-dd' date strings.
  static Future<Map<String, List<Meal>>> getMealPlansForRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return {};

    final start = _fmt(startDate);
    final end   = _fmt(endDate);

    final rows = await _supabase
        .from('meal_plans')
        .select()
        .eq('user_id', userId)
        .gte('planned_date', start)
        .lte('planned_date', end)
        .order('created_at', ascending: true);

    final result = <String, List<Meal>>{};
    for (final row in (rows as List)) {
      final dateKey = row['planned_date'] as String; // already 'yyyy-MM-dd'
      result.putIfAbsent(dateKey, () => []).add(_fromRow(row));
    }
    return result;
  }

  // ── CREATE ────────────────────────────────────────────────────────────────

  /// Inserts a new meal plan entry and returns the created [Meal] with its id.
  static Future<Meal> addMealPlan({
    required DateTime plannedDate,
    required String mealCategory,
    String? customCategoryName,
    required Map<String, dynamic> recipe,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final payload = {
      'user_id'              : userId,
      'planned_date'         : _fmt(plannedDate),
      'meal_category'        : mealCategory,
      'custom_category_name' : customCategoryName,
      'recipe_id'            : recipe['id'],
      'recipe_name'          : recipe['name'] ?? 'Untitled Recipe',
      'servings'             : recipe['servings'] ?? 1,
      'calories_per_serving' : recipe['caloriesPerServing'] ?? 0,
      'cooking_duration'     : recipe['cookTimeMinutes'] ?? 0,
      'difficulty'           : recipe['difficulty'],
    };

    final inserted = await _supabase
        .from('meal_plans')
        .insert(payload)
        .select()
        .single();

    return _fromRow(inserted);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  /// Deletes a meal plan entry by its [id].
  static Future<void> deleteMealPlan(String id) async {
    await _supabase.from('meal_plans').delete().eq('id', id);
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Meal _fromRow(Map<String, dynamic> row) {
    final category     = row['meal_category'] as String;
    final customName   = row['custom_category_name'] as String?;
    final displayLabel = category == 'Custom' && customName != null && customName.isNotEmpty
        ? customName
        : category;

    return Meal(
      id                 : row['id'] as String,
      title              : row['recipe_name'] as String,
      mealType           : displayLabel,
      servings           : (row['servings'] as int?) ?? 1,
      calories           : (row['calories_per_serving'] as int?) ?? 0,
      customCategoryName : customName,
      originalData       : {
        'id'                 : row['recipe_id'],
        'name'               : row['recipe_name'],
        'cookTimeMinutes'    : row['cooking_duration'] ?? 0,
        'caloriesPerServing' : row['calories_per_serving'] ?? 0,
        'difficulty'         : row['difficulty'] ?? 'Medium',
        'servings'           : row['servings'] ?? 1,
      },
    );
  }
}