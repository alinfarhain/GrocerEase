import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all Supabase recipe operations and maps Supabase field names
/// to the local field names used throughout the app UI.
///
/// Supabase column   →   Local app field
/// ─────────────────────────────────────
/// recipe_name       →   name
/// image_url         →   image
/// cooking_duration  →   cookTimeMinutes
/// estimated_budget  →   budget
/// calories_per_serving → caloriesPerServing
/// difficulty_level  →   difficulty
/// tools_required    →   tools
/// cooking_steps     →   instructions
/// ingredients       →   ingredients  (same structure)

class RecipeService {
  static final _supabase = Supabase.instance.client;

  // ─────────────────────────────────────────────────────────
  // FIELD MAPPING
  // ─────────────────────────────────────────────────────────

  /// Converts a raw Supabase row into the local map format used in the UI.
  static Map<String, dynamic> fromSupabase(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'name': row['recipe_name'] ?? '',
      'image': row['image_url'],
      'cookTimeMinutes': row['cooking_duration'] ?? 0,
      'prepTimeMinutes': 0,
      'budget': (row['estimated_budget'] ?? 0).toString(),
      'servings': row['servings'] ?? 4,
      'caloriesPerServing': row['calories_per_serving'] ?? 0,
      'difficulty': row['difficulty_level'] ?? 'Easy',
      'tools': _toStringList(row['tools_required']),
      'ingredients': _toIngredientList(row['ingredients']),
      'instructions': _toStringList(row['cooking_steps']),
      'isFavourite': false,
      'mealType': [],
    };
  }

  /// Normalizes any recipe map — handles both Supabase field names
  /// and the local field names already used in the app.
  /// Call this in RecipeView.initState() so the view always works.
  static Map<String, dynamic> normalize(Map<String, dynamic> recipe) {
    // If the map has Supabase-style fields, convert them
    if (recipe.containsKey('recipe_name')) {
      return fromSupabase(recipe);
    }
    // Already in local format — return as-is
    return Map<String, dynamic>.from(recipe);
  }

  // ─────────────────────────────────────────────────────────
  // SUPABASE OPERATIONS
  // ─────────────────────────────────────────────────────────

  /// Fetches all recipes belonging to the currently logged-in user.
  /// Returns a list of locally-mapped recipe maps.
  static Future<List<Map<String, dynamic>>> getUserRecipes() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('recipes')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => fromSupabase(Map<String, dynamic>.from(row)))
        .toList();
  }

  /// Fetches a single recipe by its UUID.
  /// Returns null if not found.
  static Future<Map<String, dynamic>?> getRecipeById(String id) async {
    try {
      final response = await _supabase
          .from('recipes')
          .select()
          .eq('id', id)
          .single();
      return fromSupabase(Map<String, dynamic>.from(response));
    } catch (_) {
      return null;
    }
  }

  /// Deletes a recipe by its UUID.
  static Future<void> deleteRecipe(String id) async {
    await _supabase.from('recipes').delete().eq('id', id);
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return List<String>.from(value.map((e) => e.toString()));
    }
    return [];
  }

  static List<Map<String, dynamic>> _toIngredientList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return List<Map<String, dynamic>>.from(
        value.map(
              (e) => e is Map
              ? Map<String, dynamic>.from(e)
              : {'name': e.toString(), 'amount': '', 'unit': ''},
        ),
      );
    }
    return [];
  }

  static Future<void> saveSearchedRecipe(Map<String, dynamic> recipe) async {
    final userId = _supabase.auth.currentUser?.id;
    await _supabase.from('recipes').insert({
      'user_id': userId,
      'recipe_name': recipe['name'],
      'image_url': recipe['image'],
      'cooking_duration': recipe['cookTimeMinutes'] ?? 0,
      'estimated_budget': 0.0,
      'servings': recipe['servings'] ?? 4,
      'calories_per_serving': recipe['caloriesPerServing'] ?? 0,
      'difficulty_level': recipe['difficulty'] ?? 'Medium',
      'tools_required': [],
      'ingredients': recipe['ingredients'] ?? [],
      'cooking_steps': recipe['instructions'] ?? [],
    });
  }

}