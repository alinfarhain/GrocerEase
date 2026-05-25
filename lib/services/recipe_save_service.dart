import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeSaveService {
  static final _client = Supabase.instance.client;

  /// Parses a time string like "30 mins", "1 hour", "1 hr 20 mins"
  /// into total integer minutes for the cooking_duration column.
  static int _parseMinutes(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;

    final str = value.toString().toLowerCase();
    int total = 0;

    final hourMatch = RegExp(r'(\d+)\s*h').firstMatch(str);
    if (hourMatch != null) {
      total += int.parse(hourMatch.group(1)!) * 60;
    }

    final minMatch = RegExp(r'(\d+)\s*m').firstMatch(str);
    if (minMatch != null) {
      total += int.parse(minMatch.group(1)!);
    }

    if (total == 0) {
      final numMatch = RegExp(r'(\d+)').firstMatch(str);
      if (numMatch != null) total = int.parse(numMatch.group(1)!);
    }

    return total;
  }

  /// Saves a meal scan result directly.
  /// Called by "Add to Saved Recipes" on the meal result page.
  static Future<void> saveMealRecipe(Map<String, dynamic> scanResult) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final recipe = scanResult['recipe'] as Map<String, dynamic>? ?? {};
    final ingredients = recipe['ingredients'] as List<dynamic>? ?? [];
    final steps = recipe['steps'] as List<dynamic>? ?? [];

    final prepMins = _parseMinutes(recipe['prepTime']);
    final cookMins = _parseMinutes(recipe['cookTime']);
    final totalMins = prepMins + cookMins;

    await _client.from('recipes').insert({
      'user_id': user.id,
      'recipe_name': scanResult['name'] ?? 'Scanned Meal',
      'image_url': null,
      'cooking_duration': totalMins,
      'estimated_budget': recipe['estimatedBudget'] is num
          ? (recipe['estimatedBudget'] as num).toDouble()
          : double.tryParse(recipe['estimatedBudget']?.toString() ?? ''),
      'servings': recipe['servings'] is int
          ? recipe['servings']
          : int.tryParse(recipe['servings']?.toString() ?? '') ?? 1,
      'calories_per_serving': recipe['caloriesPerServing'] is int
          ? recipe['caloriesPerServing']
          : int.tryParse(recipe['caloriesPerServing']?.toString() ?? ''),
      'difficulty_level': recipe['difficultyLevel']?.toString(),
      'tools_required': (recipe['toolsRequired'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      'ingredients': ingredients.map((e) => e.toString()).toList(),
      'cooking_steps': steps.map((e) => e.toString()).toList(),
      'is_favourite': false,
    });
  }

  /// Saves a specific recipe from the detail bottom sheet or suggestion card.
  /// Used for both meal (View Full Recipe → Save) and ingredients modes.
  static Future<void> saveRecipeSuggestion({
    required Map<String, dynamic> recipe,
    String? overrideName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final ingredients = recipe['ingredients'] as List<dynamic>? ?? [];
    final steps = recipe['steps'] as List<dynamic>? ?? [];

    final prepMins = _parseMinutes(recipe['prepTime']);
    final cookMins = _parseMinutes(recipe['cookTime']);
    final totalMins = prepMins + cookMins;

    await _client.from('recipes').insert({
      'user_id': user.id,
      'recipe_name': overrideName ?? recipe['name'] ?? 'Scanned Recipe',
      'image_url': null,
      'cooking_duration': totalMins,
      'estimated_budget': recipe['estimatedBudget'] is num
          ? (recipe['estimatedBudget'] as num).toDouble()
          : double.tryParse(recipe['estimatedBudget']?.toString() ?? ''),
      'servings': recipe['servings'] is int
          ? recipe['servings']
          : int.tryParse(recipe['servings']?.toString() ?? '') ?? 1,
      'calories_per_serving': recipe['caloriesPerServing'] is int
          ? recipe['caloriesPerServing']
          : int.tryParse(recipe['caloriesPerServing']?.toString() ?? ''),
      'difficulty_level': recipe['difficultyLevel']?.toString(),
      'tools_required': (recipe['toolsRequired'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      'ingredients': ingredients.map((e) => e.toString()).toList(),
      'cooking_steps': steps.map((e) => e.toString()).toList(),
      'is_favourite': false,
    });
  }
}