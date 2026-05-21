import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

/// Central service for all recipe data operations.
/// Handles both Supabase (user's saved recipes) and Spoonacular (search).
///
/// KEY INSIGHT — Spoonacular requires 2 API calls:
///   1. complexSearch  → basic card info (name, image, time)
///   2. /recipes/{id}/information → FULL details (steps, tools, nutrition)
///
/// The complexSearch endpoint does NOT reliably return analyzedInstructions
/// or nutrition data, which is why steps/tools/calories were showing empty.

class RecipeService {
  static final _supabase = Supabase.instance.client;

  // ── Put your Spoonacular API key here (same key as in search_recipes.dart)
  static const String spoonacularApiKey = 'e6772569c1144f8283b6fd9e92e13e07';

  // ─────────────────────────────────────────────────────────────────────────
  // SPOONACULAR — Fetch full recipe details
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetches COMPLETE recipe details from Spoonacular using the recipe ID.
  /// This is the call that returns steps, tools/equipment, and calories.
  /// Called when the user opens a search result in RecipeView.
  static Future<Map<String, dynamic>?> fetchSpoonacularRecipe(
      String spoonacularId,
      ) async {
    try {
      final uri = Uri.parse(
        'https://api.spoonacular.com/recipes/$spoonacularId/information'
            '?apiKey=$spoonacularApiKey'
            '&includeNutrition=true',
      );
      final response =
      await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return mapFullSpoonacularRecipe(data);
      }
    } catch (_) {}
    return null;
  }

  /// Maps the FULL /recipes/{id}/information response → local recipe format.
  /// This endpoint reliably returns steps, equipment, and nutrition.
  static Map<String, dynamic> mapFullSpoonacularRecipe(
      Map<String, dynamic> meal,
      ) {
    // 1. Extract cooking steps AND tools from analyzedInstructions
    final toolsSet = <String>{};
    final instructions = <String>[];

    for (final group in (meal['analyzedInstructions'] as List? ?? [])) {
      if (group is! Map) continue;
      for (final step in (group['steps'] as List? ?? [])) {
        if (step is! Map) continue;

        final text = step['step']?.toString().trim() ?? '';
        if (text.isNotEmpty) instructions.add(text);

        // Equipment = kitchen tools (pan, pot, oven, etc.)
        for (final eq in (step['equipment'] as List? ?? [])) {
          if (eq is! Map) continue;
          final name = eq['name']?.toString().trim() ?? '';
          if (name.isNotEmpty) toolsSet.add(capitalizeWords(name));
        }
      }
    }

    // Fallback: parse plain-text 'instructions' field if steps are empty
    if (instructions.isEmpty) {
      final plain = (meal['instructions'] as String? ?? '')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();
      if (plain.isNotEmpty) {
        final parts = plain
            .split(RegExp(r'\r?\n+'))
            .map((s) => s.trim())
            .where((s) => s.length > 8)
            .toList();
        instructions.addAll(parts.isEmpty ? [plain] : parts);
      }
    }

    // 2. Map ingredients with unit conversion
    final ingredients = _mapIngredients(meal['extendedIngredients']);

    // 3. Extract calories per serving from nutrition block
    int caloriesPerServing = 0;
    final nutrition = meal['nutrition'];
    if (nutrition is Map) {
      for (final n in (nutrition['nutrients'] as List? ?? [])) {
        if (n is Map &&
            (n['name'] as String? ?? '').toLowerCase() == 'calories') {
          caloriesPerServing =
              ((n['amount'] as num?)?.toDouble() ?? 0).round();
          break;
        }
      }
    }

    // 4. Difficulty from readyInMinutes
    final readyInMinutes = (meal['readyInMinutes'] as int?) ?? 30;
    String difficulty = 'Medium';
    if (readyInMinutes <= 20) difficulty = 'Easy';
    if (readyInMinutes > 60) difficulty = 'Hard';

    // 5. Estimated budget in RM (pricePerServing is USD cents)
    final servings = (meal['servings'] as int?) ?? 4;
    final priceCents = (meal['pricePerServing'] as num?)?.toDouble() ?? 0;
    final budgetRM = (priceCents / 100) * 4.7 * servings;

    return {
      'id': meal['id']?.toString(),
      'name': meal['title'] ?? '',
      'image': meal['image'],
      'cookTimeMinutes': readyInMinutes,
      'prepTimeMinutes': 0,
      'servings': servings,
      'caloriesPerServing': caloriesPerServing,
      'difficulty': difficulty,
      'tools': toolsSet.toList(),
      'ingredients': ingredients,
      'instructions': instructions,
      'mealType':
      List<String>.from((meal['dishTypes'] as List? ?? []).take(2)),
      'budget': budgetRM > 0 ? budgetRM.toStringAsFixed(2) : '0',
      'isFromSearch': true,
      // ✅ Tells RecipeView to skip an extra API call — data is already complete
      'isFullyLoaded': true,
    };
  }

  /// Maps the complexSearch result → local format for search preview cards.
  /// With addRecipeInformation=true + addNutritionInformation=true, the search
  /// endpoint DOES return analyzedInstructions (equipment/tools) and nutrition
  /// (calories). We extract both here so the card shows correct data immediately.
  static Map<String, dynamic> mapSpoonacularSearchResult(
      Map<String, dynamic> meal,
      ) {
    // ✅ Extract tools from analyzedInstructions — available in search results
    final toolsSet = <String>{};
    for (final group in (meal['analyzedInstructions'] as List? ?? [])) {
      if (group is! Map) continue;
      for (final step in (group['steps'] as List? ?? [])) {
        if (step is! Map) continue;
        for (final eq in (step['equipment'] as List? ?? [])) {
          if (eq is! Map) continue;
          final name = eq['name']?.toString().trim() ?? '';
          if (name.isNotEmpty) toolsSet.add(capitalizeWords(name));
        }
      }
    }

    // ✅ Extract calories from nutrition block
    // Requires addNutritionInformation=true in the complexSearch call
    int caloriesPerServing = 0;
    final nutrition = meal['nutrition'];
    if (nutrition is Map) {
      for (final n in (nutrition['nutrients'] as List? ?? [])) {
        if (n is Map &&
            (n['name'] as String? ?? '').toLowerCase() == 'calories') {
          caloriesPerServing =
              ((n['amount'] as num?)?.toDouble() ?? 0).round();
          break;
        }
      }
    }

    final readyInMinutes = (meal['readyInMinutes'] as int?) ?? 30;
    String difficulty = 'Medium';
    if (readyInMinutes <= 20) difficulty = 'Easy';
    if (readyInMinutes > 60) difficulty = 'Hard';

    final servings = (meal['servings'] as int?) ?? 4;
    final priceCents = (meal['pricePerServing'] as num?)?.toDouble() ?? 0;
    final budgetRM = (priceCents / 100) * 4.7 * servings;

    return {
      'id': meal['id']?.toString(),
      'name': meal['title'] ?? '',
      'image': meal['image'],
      'cookTimeMinutes': readyInMinutes,
      'prepTimeMinutes': 0,
      'servings': servings,
      'caloriesPerServing': caloriesPerServing,  // ✅ now populated
      'difficulty': difficulty,
      'tools': toolsSet.toList(),                // ✅ now populated
      'ingredients': _mapIngredients(meal['extendedIngredients']),
      'instructions': <String>[],  // fetched in RecipeView for full steps
      'mealType':
      List<String>.from((meal['dishTypes'] as List? ?? []).take(2)),
      'budget': budgetRM > 0 ? budgetRM.toStringAsFixed(2) : '0',
      'isFromSearch': true,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUPABASE — Field name mapping
  // ─────────────────────────────────────────────────────────────────────────

  /// Converts a raw Supabase row → local app field names.
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
      'isFavourite': row['is_favourite'] ?? false,
      'mealType': [],
    };
  }

  /// Normalizes any recipe map so RecipeView works regardless of source.
  /// Handles both Supabase field names and local app field names.
  static Map<String, dynamic> normalize(Map<String, dynamic> recipe) {
    if (recipe.containsKey('recipe_name')) return fromSupabase(recipe);
    return Map<String, dynamic>.from(recipe);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUPABASE — CRUD operations
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getUserRecipes() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await _supabase
        .from('recipes')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((r) => fromSupabase(Map<String, dynamic>.from(r)))
        .toList();
  }

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

  static Future<void> deleteRecipe(String id) async {
    await _supabase.from('recipes').delete().eq('id', id);
  }

  /// Saves a Spoonacular search result to the user's Supabase recipes table.
  static Future<void> saveSearchedRecipe(Map<String, dynamic> recipe) async {
    final userId = _supabase.auth.currentUser?.id;
    await _supabase.from('recipes').insert({
      'user_id': userId,
      'recipe_name': recipe['name'],
      'image_url': recipe['image'],
      'cooking_duration': recipe['cookTimeMinutes'] ?? 0,
      'estimated_budget': double.tryParse(
          recipe['budget']?.toString() ?? '0') ??
          0.0,
      'servings': recipe['servings'] ?? 4,
      'calories_per_serving': recipe['caloriesPerServing'] ?? 0,
      'difficulty_level': recipe['difficulty'] ?? 'Medium',
      'tools_required': recipe['tools'] ?? [],
      'ingredients': recipe['ingredients'] ?? [],
      'cooking_steps': recipe['instructions'] ?? [],
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UNIT CONVERSION HELPERS (static — shared by all callers)
  // ─────────────────────────────────────────────────────────────────────────

  /// Maps an extendedIngredients list → local ingredient maps.
  static List<Map<String, dynamic>> _mapIngredients(dynamic rawList) {
    final result = <Map<String, dynamic>>[];
    for (final ing in (rawList as List? ?? [])) {
      if (ing is! Map) continue;

      double amount;
      String unit;

      // Prefer Spoonacular's pre-converted metric measure
      final metric = ing['measures']?['metric'];
      if (metric != null && metric['amount'] != null) {
        amount = (metric['amount'] as num).toDouble();
        unit = metric['unitShort']?.toString() ?? '';
      } else {
        amount = (ing['amount'] as num?)?.toDouble() ?? 0;
        unit = ing['unit']?.toString() ?? '';
      }

      final converted = convertToMetric(amount, unit);
      amount = converted['amount'] as double;
      unit = normalizeUnit(converted['unit'] as String);

      result.add({
        'name': ing['name']?.toString() ?? '',
        'amount': formatIngredientAmount(amount, unit),
        'unit': unit,
      });
    }
    return result;
  }

  /// Converts US imperial units to metric.
  static Map<String, dynamic> convertToMetric(double amount, String unit) {
    switch (unit.toLowerCase().trim()) {
    // Weight
      case 'oz':
      case 'ounce':
      case 'ounces':
        return {'amount': _round(amount * 28.3495), 'unit': 'g'};
      case 'lb':
      case 'lbs':
      case 'pound':
      case 'pounds':
        final g = amount * 453.592;
        if (g >= 1000) return {'amount': _round(amount * 0.453592, dp: 2), 'unit': 'kg'};
        return {'amount': _round(g), 'unit': 'g'};
      case 'st':
      case 'stone':
        return {'amount': _round(amount * 6.35029, dp: 2), 'unit': 'kg'};

    // Volume
      case 'fl oz':
      case 'fluid ounce':
      case 'fluid ounces':
        return {'amount': _round(amount * 29.5735), 'unit': 'ml'};
      case 'pt':
      case 'pint':
      case 'pints':
        final ml = amount * 473.176;
        if (ml >= 1000) return {'amount': _round(amount * 0.473176, dp: 2), 'unit': 'l'};
        return {'amount': _round(ml), 'unit': 'ml'};
      case 'qt':
      case 'quart':
      case 'quarts':
        final mlQt = amount * 946.353;
        if (mlQt >= 1000) return {'amount': _round(amount * 0.946353, dp: 2), 'unit': 'l'};
        return {'amount': _round(mlQt), 'unit': 'ml'};
      case 'gal':
      case 'gallon':
      case 'gallons':
        return {'amount': _round(amount * 3.78541, dp: 2), 'unit': 'l'};

    // Temperature
      case 'f':
      case '°f':
      case 'fahrenheit':
        return {'amount': _round((amount - 32) * 5 / 9, dp: 1), 'unit': '°C'};

      default:
        return {'amount': amount, 'unit': unit};
    }
  }

  /// Normalizes unit display names (cups→cup, tablespoon→tbsp, etc.)
  static String normalizeUnit(String unit) {
    switch (unit.toLowerCase().trim()) {
      case 'cups':        return 'cup';
      case 'tablespoon':
      case 'tablespoons':
      case 'tbsps':
      case 'tbs':         return 'tbsp';
      case 'teaspoon':
      case 'teaspoons':
      case 'tsps':        return 'tsp';
      case 'servings':    return 'serving';
      case 'grams':       return 'g';
      case 'kilograms':   return 'kg';
      case 'milligrams':  return 'mg';
      case 'milliliters':
      case 'millilitres': return 'ml';
      case 'liters':
      case 'litres':      return 'l';
      default:            return unit;
    }
  }

  /// Formats a number: decimals for metric units, fractions for everything else.
  static String formatIngredientAmount(double amount, String unit) {
    if (amount <= 0) return '0';
    const metricUnits = {'g', 'kg', 'mg', 'ml', 'l', 'cl', '°c'};
    if (metricUnits.contains(unit.toLowerCase())) {
      if (amount == amount.floorToDouble()) return amount.toInt().toString();
      return amount.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '');
    }
    return toFraction(amount);
  }

  /// Converts a decimal to a fraction string, e.g. 1.5 → "1 1/2".
  static String toFraction(double amount) {
    if (amount <= 0) return '0';
    final int whole = amount.floor();
    final double frac = amount - whole;
    if (frac < 0.01) return whole.toString();

    final fractionMap = {
      0.125: '1/8', 0.25: '1/4', 0.333: '1/3',
      0.375: '3/8', 0.5: '1/2', 0.625: '5/8',
      0.667: '2/3', 0.75: '3/4', 0.875: '7/8',
    };

    String fracStr = '';
    for (final entry in fractionMap.entries) {
      if ((frac - entry.key).abs() < 0.025) {
        fracStr = entry.value;
        break;
      }
    }
    if (fracStr.isEmpty) {
      final e = ['', '1/8', '1/4', '3/8', '1/2', '5/8', '3/4', '7/8'];
      final eighths = (frac * 8).round().clamp(1, 7);
      fracStr = e[eighths];
    }
    return whole > 0 ? '$whole $fracStr' : fracStr;
  }

  /// Capitalizes each word (e.g. "frying pan" → "Frying Pan").
  static String capitalizeWords(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  static double _round(double value, {int dp = 1}) {
    final factor = math.pow(10, dp).toDouble();
    return (value * factor).round() / factor;
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value.map((e) => e.toString()));
    return [];
  }

  static List<Map<String, dynamic>> _toIngredientList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return List<Map<String, dynamic>>.from(
        value.map((e) => e is Map
            ? Map<String, dynamic>.from(e)
            : {'name': e.toString(), 'amount': '', 'unit': ''}),
      );
    }
    return [];
  }

  static Future<void> toggleFavourite(String id, bool isFavourite) async {
    await _supabase
        .from('recipes')
        .update({'is_favourite': isFavourite})
        .eq('id', id);
  }

}