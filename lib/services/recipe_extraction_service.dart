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
You are a recipe extraction assistant. Extract recipe information ONLY from what is 
visible in the image. Do NOT infer, guess, or fill in any information not explicitly shown.
Respond ONLY in this exact JSON format with no extra text or markdown:
{
  "title": "string or null",
  "description": "string or null",
  "ingredients": [{"name": "string", "quantity": "string or null", "unit": "string or null"}],
  "instructions": ["step 1", "step 2"],
  "prep_time_minutes": null,
  "cook_time_minutes": null,
  "servings": null
}
Use null for any field not visible in the image. Return ONLY the JSON object.
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

    // Step 1: Fetch the web page content
    final pageResponse = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'Mozilla/5.0 (compatible; RecipeBot/1.0)'},
    ).timeout(const Duration(seconds: 15));

    if (pageResponse.statusCode != 200) {
      throw Exception('Could not fetch URL (${pageResponse.statusCode})');
    }

    // Step 2: Strip HTML to plain text
    final cleanText = _stripHtml(pageResponse.body);
    final truncated =
    cleanText.length > 10000 ? cleanText.substring(0, 10000) : cleanText;

    // Step 3: Build a text-only prompt embedding the page content
    final prompt = '''
You are a recipe extraction assistant. Extract recipe information ONLY from the 
webpage text below. Do NOT infer, guess, or fill in any information not explicitly 
present in the text.
Respond ONLY in this exact JSON format with no extra text or markdown:
{
  "title": "string or null",
  "description": "string or null",
  "ingredients": [{"name": "string", "quantity": "string or null", "unit": "string or null"}],
  "instructions": ["step 1", "step 2"],
  "prep_time_minutes": null,
  "cook_time_minutes": null,
  "servings": null
}
Use null for any field not found. Return ONLY the JSON object.

WEBPAGE TEXT:
$truncated
''';

    // Step 4: Call the same edge function — no image for URL mode
    final response = await http.post(
      Uri.parse(_functionUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode({
        'mode': 'recipe_url',
        'prompt': prompt,
        // No base64Image — text is embedded in the prompt
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
    List<Map<String, dynamic>>? ingredients;
    if (json['ingredients'] != null) {
      ingredients = (json['ingredients'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    List<String>? instructions;
    if (json['instructions'] != null) {
      instructions =
          (json['instructions'] as List).map((e) => e.toString()).toList();
    }

    return ExtractedRecipe(
      title: json['title'] as String?,
      description: json['description'] as String?,
      ingredients: ingredients,
      instructions: instructions,
      prepTimeMinutes: json['prep_time_minutes'] as int?,
      cookTimeMinutes: json['cook_time_minutes'] as int?,
      servings: json['servings'] as int?,
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