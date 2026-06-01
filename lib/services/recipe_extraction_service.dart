// lib/services/recipe_extraction_service.dart
//
// Handles two recipe input methods:
//   1. extractFromImage  → Supabase Edge Function (swift-action, mode: recipe_scan)
//   2. extractFromUrl    → Spoonacular /recipes/extract (reliable for all major sites)

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'recipe_service.dart'; // for RecipeService.spoonacularApiKey

class ExtractedRecipe {
  final String? title;
  final String? description;
  final List<Map<String, dynamic>>? ingredients;
  final List<String>? instructions;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final int? servings;
  final String? sourceType;
  final String? sourceUrl;

  const ExtractedRecipe({
    this.title,
    this.description,
    this.ingredients,
    this.instructions,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.servings,
    this.sourceType,
    this.sourceUrl,
  });

  Map<String, dynamic> toSupabaseMap(String userId) {
    final map = <String, dynamic>{
      'user_id': userId,
      'recipe_name': title ?? 'Untitled Recipe',
      'cooking_duration': cookTimeMinutes ?? 0,
      'estimated_budget': 0.0,
      'calories_per_serving': 0,
      'difficulty_level': 'Easy',
      'tools_required': <String>[],
    };

    if (ingredients != null) map['ingredients'] = ingredients;
    if (instructions != null) map['cooking_steps'] = instructions;
    if (servings != null) map['servings'] = servings;
    if (sourceType != null) map['source_type'] = sourceType;
    if (sourceUrl != null) map['source_url'] = sourceUrl;

    return map;
  }
}

class RecipeExtractionService {
  static const String _functionUrl =
      'https://cgosdfzvwhelfexdovry.supabase.co/functions/v1/swift-action';

  final _supabase = Supabase.instance.client;

  String get _accessToken =>
      _supabase.auth.currentSession?.accessToken ?? '';

  // ── FEATURE 1: Extract from image (camera / gallery) ───────────────────
  // Sends the image to the Edge Function (swift-action, mode: recipe_scan).
  Future<ExtractedRecipe> extractFromImage(File imageFile) async {
    if (_accessToken.isEmpty) throw Exception('Not logged in — no session token');

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    const prompt = '''
You are a recipe data extraction assistant.

Extract the recipe from the image. Return a single JSON object.
Rules:
- Extract ONLY what is explicitly visible in the image
- For missing fields use JSON null (not the string "null")
- Do not add, guess or infer any data
- Return raw JSON only — no markdown, no code fences, no explanation

JSON schema:
{
  "title": <string or null>,
  "description": <string or null>,
  "ingredients": <array of {name: string, quantity: string or null, unit: string or null} or null>,
  "instructions": <array of strings or null>,
  "prep_time_minutes": <integer or null>,
  "cook_time_minutes": <integer or null>,
  "servings": <integer or null>
}
''';

    final response = await http.post(
      Uri.parse(_functionUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode({
        'base64Image': base64Image,
        'mode': 'recipe_scan',
        'prompt': prompt,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Edge function call failed');
    }

    final data = jsonDecode(response.body);
    final result = data['result'] as Map<String, dynamic>;
    return _parseEdgeResult(result, sourceType: 'scan_written');
  }

  // ── FEATURE 2: Extract from URL ─────────────────────────────────────────
  // Uses Spoonacular's /recipes/extract endpoint — handles all major recipe
  // sites (allrecipes, Food Network, Tasty, BBC Good Food, etc.) reliably.
  // Costs 2 Spoonacular API points per call.
  Future<ExtractedRecipe> extractFromUrl(String url) async {
    final uri = Uri.parse(
      'https://api.spoonacular.com/recipes/extract'
          '?url=${Uri.encodeComponent(url)}'
          '&forceExtraction=true'
          '&apiKey=${RecipeService.spoonacularApiKey}',
    );

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 402) {
      throw Exception(
        'Daily Spoonacular API limit reached. Please try again tomorrow.',
      );
    }
    if (response.statusCode == 401) {
      throw Exception('Invalid Spoonacular API key.');
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Could not extract recipe (HTTP ${response.statusCode}). '
            'Make sure the URL links directly to a recipe page.',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseSpoonacularExtract(data, sourceUrl: url);
  }

  // ── Save to Supabase ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> saveToDatabase(ExtractedRecipe recipe) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _supabase
        .from('recipes')
        .insert(recipe.toSupabaseMap(userId))
        .select()
        .single();

    return response;
  }

  // ── Parse Spoonacular /recipes/extract response ─────────────────────────
  ExtractedRecipe _parseSpoonacularExtract(
      Map<String, dynamic> data, {
        required String sourceUrl,
      }) {
    // ── Title ─────────────────────────────────────────────────────────────
    final title = data['title']?.toString();

    // ── Ingredients from extendedIngredients ──────────────────────────────
    List<Map<String, dynamic>>? ingredients;
    final rawIngredients = data['extendedIngredients'];
    if (rawIngredients is List && rawIngredients.isNotEmpty) {
      ingredients = rawIngredients.map((ing) {
        if (ing is! Map) return {'name': ing.toString(), 'quantity': null, 'unit': null};

        // Prefer metric measures when available
        double amount;
        String unit;
        final metric = ing['measures']?['metric'];
        if (metric != null && metric['amount'] != null) {
          amount = (metric['amount'] as num).toDouble();
          unit = metric['unitShort']?.toString() ?? '';
        } else {
          amount = (ing['amount'] as num?)?.toDouble() ?? 0;
          unit = ing['unit']?.toString() ?? '';
        }

        // Format the quantity nicely (remove trailing zeros)
        String quantity;
        if (amount == amount.truncateToDouble()) {
          quantity = amount.toInt().toString();
        } else {
          quantity = amount.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');
        }

        return {
          'name': ing['name']?.toString() ?? '',
          'quantity': quantity,
          'unit': unit.isEmpty ? null : unit,
        };
      }).toList().cast<Map<String, dynamic>>();
    }

    // ── Instructions from analyzedInstructions ────────────────────────────
    List<String>? instructions;
    final rawInstructions = data['analyzedInstructions'];
    if (rawInstructions is List && rawInstructions.isNotEmpty) {
      final steps = <String>[];
      for (final group in rawInstructions) {
        if (group is! Map) continue;
        for (final step in (group['steps'] as List? ?? [])) {
          if (step is! Map) continue;
          final text = step['step']?.toString().trim() ?? '';
          if (text.isNotEmpty) steps.add(text);
        }
      }
      if (steps.isNotEmpty) instructions = steps;
    }

    // ── Times & servings ──────────────────────────────────────────────────
    final readyInMinutes = data['readyInMinutes'] as int?;
    final prepTime = data['preparationMinutes'] as int?;
    final cookTime = data['cookingMinutes'] as int?;

    // readyInMinutes is always present; use it as cook_time if split not given
    final cookTimeMinutes = cookTime ??
        (prepTime != null && readyInMinutes != null
            ? readyInMinutes - prepTime
            : readyInMinutes);

    return ExtractedRecipe(
      title: title,
      description: data['summary'] != null
          ? _stripHtml(data['summary'].toString())
          : null,
      ingredients: ingredients,
      instructions: instructions,
      prepTimeMinutes: prepTime,
      cookTimeMinutes: cookTimeMinutes,
      servings: data['servings'] as int?,
      sourceType: 'url_extract',
      sourceUrl: sourceUrl,
    );
  }

  // ── Parse Edge Function result (used by extractFromImage) ───────────────
  ExtractedRecipe _parseEdgeResult(
      Map<String, dynamic> json, {
        required String sourceType,
        String? sourceUrl,
      }) {
    String? str(dynamic v) {
      if (v == null || v.toString().toLowerCase() == 'null') return null;
      return v.toString();
    }

    List<Map<String, dynamic>>? ingredients;
    if (json['ingredients'] != null && json['ingredients'] is List) {
      ingredients = (json['ingredients'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    List<String>? instructions;
    if (json['instructions'] != null && json['instructions'] is List) {
      instructions =
          (json['instructions'] as List).map((e) => e.toString()).toList();
    }

    return ExtractedRecipe(
      title: str(json['title']),
      description: str(json['description']),
      ingredients: ingredients,
      instructions: instructions,
      prepTimeMinutes: json['prep_time_minutes'] is int
          ? json['prep_time_minutes'] as int
          : int.tryParse(json['prep_time_minutes']?.toString() ?? ''),
      cookTimeMinutes: json['cook_time_minutes'] is int
          ? json['cook_time_minutes'] as int
          : int.tryParse(json['cook_time_minutes']?.toString() ?? ''),
      servings: json['servings'] is int
          ? json['servings'] as int
          : int.tryParse(json['servings']?.toString() ?? ''),
      sourceType: sourceType,
      sourceUrl: sourceUrl,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  String _stripHtml(String html) {
    var text = html
        .replaceAll(
        RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false),
        '')
        .replaceAll(
        RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false),
        '');
    text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}