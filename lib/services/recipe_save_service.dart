import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeSaveService {
  static final _client = Supabase.instance.client;

  /// Parses time strings like "30 mins", "1 hour 20 mins" → integer minutes.
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

  /// Normalises a unit string to match your app's dropdown values.
  static String _normaliseUnit(String? raw) {
    if (raw == null) return 'unit';
    switch (raw.toLowerCase().trim()) {
      case 'g':
      case 'gram':
      case 'grams':
        return 'g';
      case 'kg':
      case 'kilogram':
      case 'kilograms':
        return 'kg';
      case 'ml':
      case 'millilitre':
      case 'millilitres':
      case 'milliliter':
      case 'milliliters':
        return 'ml';
      case 'l':
      case 'litre':
      case 'litres':
      case 'liter':
      case 'liters':
        return 'l';
      case 'tsp':
      case 'teaspoon':
      case 'teaspoons':
        return 'tsp';
      case 'tbsp':
      case 'tablespoon':
      case 'tablespoons':
        return 'tbsp';
      case 'pcs':
      case 'pc':
      case 'piece':
      case 'pieces':
      case 'each':
      case 'whole':
        return 'pcs';
      default:
        return 'unit';
    }
  }

  /// Converts AI ingredient (object or plain string) into the structured
  /// map your recipe edit screen expects:
  /// { "name": "Chicken", "amount": 4, "unit": "pcs" }
  static Map<String, dynamic> _parseIngredient(dynamic raw) {
    // ── Case 1: AI returned a structured object ──────────────
    // e.g. { "name": "Chicken", "amount": 4, "unit": "pcs" }
    if (raw is Map<String, dynamic>) {
      return {
        'name': raw['name']?.toString().trim() ?? '',
        'amount': (raw['amount'] is num)
            ? (raw['amount'] as num).toDouble()
            : double.tryParse(raw['amount']?.toString() ?? '') ?? 0.0,
        'unit': _normaliseUnit(raw['unit']?.toString()),
      };
    }

    // ── Case 2: AI returned a plain string ───────────────────
    // e.g. "4 pieces of chicken" or "200g pasta"
    // Attempt to parse amount + unit + name from the string.
    final str = raw.toString().trim();

    // Pattern: optional number, optional unit word, then name
    // e.g. "200g pasta", "4 pcs chicken", "3 cloves garlic"
    final pattern = RegExp(
      r'^(\d+(?:\.\d+)?)\s*'         // leading number (optional decimal)
      r'(g|kg|ml|l|tsp|tbsp|pcs?|'
      r'piece[s]?|gram[s]?|kilogram[s]?|'
      r'millilitre[s]?|milliliter[s]?|'
      r'litre[s]?|liter[s]?|'
      r'teaspoon[s]?|tablespoon[s]?|'
      r'clove[s]?|slice[s]?|cup[s]?|'
      r'whole|each|unit)?\s*'         // unit word (optional)
      r'(?:of\s+)?'                   // optional "of"
      r'(.+)$',                       // ingredient name
      caseSensitive: false,
    );

    final match = pattern.firstMatch(str);
    if (match != null) {
      return {
        'name': _capitalise(match.group(3)?.trim() ?? str),
        'amount': double.tryParse(match.group(1) ?? '0') ?? 0.0,
        'unit': _normaliseUnit(match.group(2)),
      };
    }

    // Fallback: couldn't parse — return raw string as name, 0 amount
    return {
      'name': _capitalise(str),
      'amount': 0.0,
      'unit': 'unit',
    };
  }

  static String _capitalise(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Builds the final ingredients list for Supabase from raw AI output.
  static List<Map<String, dynamic>> _buildIngredients(List<dynamic> raw) {
    return raw.map((e) => _parseIngredient(e)).toList();
  }

  /// Saves a meal scan result directly.
  /// Called by "Add to Saved Recipes" on the meal result page.
  static Future<void> saveMealRecipe(Map<String, dynamic> scanResult) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final recipe = scanResult['recipe'] as Map<String, dynamic>? ?? {};
    final rawIngredients = recipe['ingredients'] as List<dynamic>? ?? [];
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
      // ↓ structured ingredients with name, amount, unit
      'ingredients': _buildIngredients(rawIngredients),
      'cooking_steps': steps.map((e) => e.toString()).toList(),
      'is_favourite': false,
    });
  }

  /// Saves a specific recipe from the detail bottom sheet or suggestion card.
  static Future<void> saveRecipeSuggestion({
    required Map<String, dynamic> recipe,
    String? overrideName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final rawIngredients = recipe['ingredients'] as List<dynamic>? ?? [];
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
      // ↓ structured ingredients with name, amount, unit
      'ingredients': _buildIngredients(rawIngredients),
      'cooking_steps': steps.map((e) => e.toString()).toList(),
      'is_favourite': false,
    });
  }
}