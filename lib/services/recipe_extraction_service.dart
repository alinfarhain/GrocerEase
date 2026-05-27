import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

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
      // Required defaults for fields your table expects
      'recipe_name': title ?? 'Untitled Recipe',
      'cooking_duration': cookTimeMinutes ?? 0,
      'estimated_budget': 0.0,
      'calories_per_serving': 0,
      'difficulty_level': 'Easy',
      'tools_required': <String>[],
    };

    // Only add optional fields if they were actually extracted
    if (ingredients != null) map['ingredients'] = ingredients;
    if (instructions != null) map['cooking_steps'] = instructions;
    if (servings != null) map['servings'] = servings;
    if (sourceType != null) map['source_type'] = sourceType;
    if (sourceUrl != null) map['source_url'] = sourceUrl;
    if (prepTimeMinutes != null) map['prep_time'] = prepTimeMinutes;

    return map;
  }
}

class RecipeExtractionService {
  // ── Same edge function your scan meal feature already uses ──────────────
  static const String _functionUrl =
      'https://cgosdfzvwhelfexdovry.supabase.co/functions/v1/swift-action';

  final _supabase = Supabase.instance.client;

  String get _accessToken =>
      _supabase.auth.currentSession?.accessToken ?? '';

  // ── FEATURE 1: Extract from image (camera / gallery) ───────────────────
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
    // Edge function returns { result: { ... } } — same as scan meal
    final result = data['result'] as Map<String, dynamic>;
    return _parseResult(result, sourceType: 'scan_written');
  }

  // ── FEATURE 2: Extract from URL ─────────────────────────────────────────
  Future<ExtractedRecipe> extractFromUrl(String url) async {
    if (_accessToken.isEmpty) throw Exception('Not logged in — no session token');

    // Send the URL directly to the edge function — let the server fetch it
    // (server-side fetches are not blocked by recipe websites unlike mobile)
    final response = await http.post(
      Uri.parse(_functionUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode({
        'mode': 'recipe_url',
        'url': url,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Edge function call failed');
    }

    final data = jsonDecode(response.body);
    final result = data['result'] as Map<String, dynamic>;
    return _parseResult(result, sourceType: 'url_extract', sourceUrl: url);
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

  // ── Helpers ─────────────────────────────────────────────────────────────
  ExtractedRecipe _parseResult(
      Map<String, dynamic> json, {
        required String sourceType,
        String? sourceUrl,
      }) {
    // Treat string "null" as actual null
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

  String _stripHtml(String html) {
    var text = html
        .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?<\/script>',
        caseSensitive: false), '')
        .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>',
        caseSensitive: false), '');
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