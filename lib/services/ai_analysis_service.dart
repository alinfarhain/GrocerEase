import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AIAnalysisService {
  // ↓ CHANGED: points to your Supabase function instead of OpenAI directly
  static const String _functionUrl =
      'https://cgosdfzvwhelfexdovry.supabase.co/functions/v1/swift-action';

  static Future<Map<String, dynamic>> analyzeImage({
    required String base64Image,
    required String mode,
  }) async {
    // ↓ CHANGED: uses Supabase session token instead of OpenAI API key
    final session = Supabase.instance.client.auth.currentSession;
    final accessToken = session?.accessToken ?? '';

    // Prompts are exactly the same as before — no changes here
    final prompt = mode == 'meal'
        ? '''You are a food recognition AI. Analyze this image and identify the meal.
Respond ONLY in this exact JSON format with no extra text or markdown:
{
  "type": "meal",
  "name": "Meal Name",
  "confidence": 92,
  "description": "Brief description",
  "recipe": {
    "prepTime": "10 mins",
    "cookTime": "20 mins",
    "servings": 4,
    "ingredients": ["200g pasta", "2 cloves garlic"],
    "steps": ["Step 1", "Step 2"]
  }
}'''
        : '''You are a food recognition AI. Identify all visible ingredients in this image.
Respond ONLY in this exact JSON format with no extra text or markdown:
{
  "type": "ingredients",
  "ingredients": [
    { "name": "Tomatoes", "confidence": 95 },
    { "name": "Onions", "confidence": 92 }
  ],
  "recipeSuggestions": [
    {
      "name": "Classic Tomato Soup",
      "cookTime": "30 mins",
      "matchPercent": 95,
      "ingredients": ["Tomatoes", "Onions", "Garlic"],
      "steps": ["Step 1", "Step 2"]
    }
  ]
}''';

    // ↓ CHANGED: sends to Supabase function, not OpenAI
    final response = await http.post(
      Uri.parse(_functionUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken', // ← Supabase session token
      },
      body: jsonEncode({
        'base64Image': base64Image, // ← function handles the OpenAI call
        'mode': mode,
        'prompt': prompt,           // ← pass prompt so function uses it
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Function call failed');
    }

    final data = jsonDecode(response.body);
    return data['result'] as Map<String, dynamic>;
  }
}