import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/detected_pantry_item.dart';

// Match your main.dart values
const _supabaseUrl = 'https://cgosdfzvwhelfexdovry.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnb3NkZnp2d2hlbGZleGRvdnJ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4OTU4OTgsImV4cCI6MjA5MzQ3MTg5OH0.FXcbpyTn4KqalmYe-00ibCHBYM1l5A6zZIvvWudSTsc';

class PantryAiService {
  final _supabase = Supabase.instance.client;
  final _httpClient = http.Client();

  Future<List<DetectedPantryItem>> detectItemsFromImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    final response = await _httpClient.post(
      Uri.parse('$_supabaseUrl/functions/v1/detect_pantry_items'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
        'apikey': _supabaseAnonKey,
      },
      body: jsonEncode({
        'image_base64': base64Image,
        'mode': 'scan_item',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Detection failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data['error'] != null) throw Exception(data['error']);

    final List<dynamic> items = data['items'] ?? [];
    return items
        .map((json) => DetectedPantryItem.fromJson(json))
        .where((item) => item.detectionConfidence >= 0.5)
        .toList();
  }

  // Expose httpClient for barcode lookups in scan screen
  http.Client get httpClient => _httpClient;

  void dispose() => _httpClient.close();
}