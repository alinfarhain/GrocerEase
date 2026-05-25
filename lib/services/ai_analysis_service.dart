import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AIAnalysisService {
  static const String _functionUrl =
      'https://cgosdfzvwhelfexdovry.supabase.co/functions/v1/swift-action';

  static Future<Map<String, dynamic>> analyzeImage({
    required String base64Image,
    required String mode,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    final accessToken = session?.accessToken ?? '';

    if (accessToken.isEmpty) {
      throw Exception('Not logged in — no session token');
    }

    final prompt = mode == 'meal'
        ? '''You are a food recognition AI. Analyze this image and identify the meal.
Respond ONLY in this exact JSON format with no extra text or markdown.

IMPORTANT for ingredients array: always split into name, amount, and unit separately.
For unit use ONLY these exact values: "g", "kg", "ml", "l", "tsp", "tbsp", "pcs", "unit"
- pieces/each/whole → "pcs"
- gram/grams → "g"
- kilogram/kilograms → "kg"
- millilitre/milliliter/millilitres → "ml"
- litre/liter/litres → "l"
- teaspoon/teaspoons → "tsp"
- tablespoon/tablespoons → "tbsp"
- anything else (pinch, clove, slice, etc.) → "unit"

{
  "type": "meal",
  "name": "Meal Name",
  "confidence": 92,
  "description": "Brief description of the meal",
  "recipe": {
    "prepTime": "10 mins",
    "cookTime": "20 mins",
    "servings": 4,
    "caloriesPerServing": 450,
    "difficultyLevel": "Medium",
    "estimatedBudget": 15.00,
    "toolsRequired": ["Pan", "Knife"],
    "ingredients": [
      { "name": "Chicken", "amount": 4, "unit": "pcs" },
      { "name": "Garlic", "amount": 3, "unit": "pcs" },
      { "name": "Salt", "amount": 1, "unit": "tsp" },
      { "name": "Olive Oil", "amount": 2, "unit": "tbsp" },
      { "name": "Rice", "amount": 200, "unit": "g" }
    ],
    "steps": ["Step 1 description", "Step 2 description"]
  }
}'''
        : '''You are a food recognition AI. Identify all visible ingredients in this image.
Respond ONLY in this exact JSON format with no extra text or markdown.

IMPORTANT for ingredients array: always split into name, amount, and unit separately.
For unit use ONLY these exact values: "g", "kg", "ml", "l", "tsp", "tbsp", "pcs", "unit"
- pieces/each/whole → "pcs"
- gram/grams → "g"
- kilogram/kilograms → "kg"
- millilitre/milliliter/millilitres → "ml"
- litre/liter/litres → "l"
- teaspoon/teaspoons → "tsp"
- tablespoon/tablespoons → "tbsp"
- anything else (pinch, clove, slice, etc.) → "unit"

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
      "prepTime": "10 mins",
      "servings": 4,
      "caloriesPerServing": 320,
      "difficultyLevel": "Easy",
      "estimatedBudget": 8.00,
      "matchPercent": 95,
      "toolsRequired": ["Pot", "Blender"],
      "ingredients": [
        { "name": "Tomatoes", "amount": 4, "unit": "pcs" },
        { "name": "Onions", "amount": 1, "unit": "pcs" },
        { "name": "Garlic", "amount": 3, "unit": "pcs" },
        { "name": "Olive Oil", "amount": 2, "unit": "tbsp" }
      ],
      "steps": ["Step 1 description", "Step 2 description"]
    }
  ]
}''';

    final response = await http.post(
      Uri.parse(_functionUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'base64Image': base64Image,
        'mode': mode,
        'prompt': prompt,
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