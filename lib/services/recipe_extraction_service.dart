import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Holds raw extracted data — only fields that were actually found.
/// All fields are nullable; the app must NOT fill blanks.
class ExtractedRecipe {
  final String? title;
  final String? description;
  final List<Map<String, dynamic>>? ingredients; // [{name, quantity, unit}]
  final List<String>? instructions;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final int? servings;
  final String? sourceType; // 'scan_written' | 'url_extract'
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

  /// Adapt column names here if yours differ.
  Map<String, dynamic> toSupabaseMap(String userId) => {
    'user_id': userId,
    'name': title,
    'description': description,
    'ingredients': ingredients,
    'instructions': instructions,
    'prep_time': prepTimeMinutes,
    'cook_time': cookTimeMinutes,
    'servings': servings,
    'source_type': sourceType,
    'source_url': sourceUrl,
    'is_saved': true,
    'extracted_at': DateTime.now().toIso8601String(),
  };
}

class RecipeExtractionService {
  final _supabase = Supabase.instance.client;

  Future<String> _getApiKey() async {
    final response = await _supabase
        .from('app_settings') // ← change to your actual settings table name
        .select('value')
        .eq('key', 'openai_api_key')
        .single();
    return response['value'] as String;
  }

  // ── FEATURE 1: Extract from image (camera / gallery) ──────────────────
  Future<ExtractedRecipe> extractFromImage(File imageFile) async {
    final apiKey = await _getApiKey();
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

    const systemPrompt = '''
You are a recipe extraction assistant. Extract recipe information ONLY from what is 
visible in the image. Do NOT infer, guess, or fill in any information that is not 
explicitly shown. Return a JSON object with these fields (use null for any field 
not found):
{
  "title": string | null,
  "description": string | null,
  "ingredients": [{"name": string, "quantity": string | null, "unit": string | null}] | null,
  "instructions": [string] | null,
  "prep_time_minutes": number | null,
  "cook_time_minutes": number | null,
  "servings": number | null
}
Return ONLY the raw JSON object. No markdown, no explanation.
''';

    final body = jsonEncode({
      'model': 'gpt-4o',
      'max_tokens': 2000,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,$base64Image'},
            },
            {
              'type': 'text',
              'text': 'Extract the recipe from this image. Only extract what you can see.',
            },
          ],
        },
      ],
    });

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI error: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'] as String;
    return _parseResponse(content, sourceType: 'scan_written');
  }

  // ── FEATURE 2: Extract from URL ───────────────────────────────────────
  Future<ExtractedRecipe> extractFromUrl(String url) async {
    final pageResponse = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'Mozilla/5.0 (compatible; RecipeBot/1.0)'},
    ).timeout(const Duration(seconds: 15));

    if (pageResponse.statusCode != 200) {
      throw Exception('Could not fetch URL: ${pageResponse.statusCode}');
    }

    final cleanText = _stripHtml(pageResponse.body);
    final truncated = cleanText.length > 12000
        ? cleanText.substring(0, 12000)
        : cleanText;

    final apiKey = await _getApiKey();

    const systemPrompt = '''
You are a recipe extraction assistant. Extract recipe information ONLY from the 
provided webpage text. Do NOT infer, guess, or fill in any information not explicitly 
present in the text. Return a JSON object with these fields (use null for any field 
not found in the text):
{
  "title": string | null,
  "description": string | null,
  "ingredients": [{"name": string, "quantity": string | null, "unit": string | null}] | null,
  "instructions": [string] | null,
  "prep_time_minutes": number | null,
  "cook_time_minutes": number | null,
  "servings": number | null
}
Return ONLY the raw JSON object. No markdown, no explanation.
''';

    final body = jsonEncode({
      'model': 'gpt-4o',
      'max_tokens': 2000,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content': 'Extract the recipe from this webpage text:\n\n$truncated',
        },
      ],
    });

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI error: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'] as String;
    return _parseResponse(content, sourceType: 'url_extract', sourceUrl: url);
  }

  // ── Save to Supabase ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> saveToDatabase(ExtractedRecipe recipe) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _supabase
        .from('recipes') // ← your table name
        .insert(recipe.toSupabaseMap(userId))
        .select()
        .single();

    return response;
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  ExtractedRecipe _parseResponse(
      String content, {
        required String sourceType,
        String? sourceUrl,
      }) {
    final clean = content
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final Map<String, dynamic> json = jsonDecode(clean);

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
        .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false), '');
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