// lib/services/ingredient_pricing_service.dart
//
// Handles:
//   1. AI-powered Malaysian grocery price estimation via Supabase edge function
//   2. Pantry shortage calculation (how much of an ingredient is still needed)
//   3. Unit conversion helpers (g, kg, ml, cup, tbsp, etc.)
//   4. Heuristic fallback pricing when AI is unavailable

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result returned by [IngredientPricingService.estimatePrice].
class PricingResult {
  /// Human-readable retail product description, e.g. "500g chicken tray".
  final String suggestedPurchaseUnit;

  /// Estimated retail price in Malaysian Ringgit.
  final double estimatedPriceMyr;

  /// Label shown in the grocery tile: "AI Malaysian Estimate" | "Estimated".
  final String priceSource;

  const PricingResult({
    required this.suggestedPurchaseUnit,
    required this.estimatedPriceMyr,
    required this.priceSource,
  });
}

/// Pantry coverage status for a single ingredient.
enum PantryStatus {
  /// Pantry has enough — do NOT add to grocery list.
  covered,

  /// Pantry has some but not enough — add the shortage amount.
  partial,

  /// Not found in pantry at all — add full needed amount.
  missing,
}

/// Result of pantry cross-check for one ingredient.
class PantryCheckResult {
  final PantryStatus status;

  /// Amount still needed after accounting for pantry stock.
  /// 0.0 when [status] == covered.
  final double shortageAmount;

  /// Original needed amount (before pantry deduction).
  final double neededAmount;

  const PantryCheckResult({
    required this.status,
    required this.shortageAmount,
    required this.neededAmount,
  });
}

class IngredientPricingService {
  static final _supabase = Supabase.instance.client;
  static const _projectRef = 'cgosdfzvwhelfexdovry';

  // ── AI Price Estimation ───────────────────────────────────────────────────

  /// Estimates the retail purchase price for [name] in the Malaysian market.
  /// Reuses the existing `analyze-image` edge function with mode
  /// `estimate_grocery_price` — no separate function deployment needed.
  /// Falls back to heuristic pricing if the network call fails.
  static Future<PricingResult> estimatePrice({
    required String name,
    required double amount,
    required String unit,
  }) async {
    try {
      final accessToken =
          _supabase.auth.currentSession?.accessToken ?? '';
      // Reuses the existing analyze-image function — just a new mode
      final url =
          'https://$_projectRef.supabase.co/functions/v1/analyze-image';

      final response = await http
          .post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'mode': 'estimate_grocery_price',
          'ingredient_name': name,
          'recipe_amount': amount,
          'recipe_unit': unit,
        }),
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final purchaseUnit =
            data['suggested_purchase_unit']?.toString().trim() ?? '';
        final price =
            (data['estimated_price_myr'] as num?)?.toDouble() ?? 0.0;

        if (purchaseUnit.isNotEmpty && price > 0) {
          return PricingResult(
            suggestedPurchaseUnit: purchaseUnit,
            estimatedPriceMyr: price,
            priceSource: 'AI Malaysian Estimate',
          );
        }
      }
    } catch (_) {
      // Network / timeout — fall through to heuristic
    }

    // ── Heuristic fallback ──────────────────────────────────────────────────
    return PricingResult(
      suggestedPurchaseUnit: _heuristicPurchaseUnit(name),
      estimatedPriceMyr: _heuristicPrice(name),
      priceSource: 'Estimated',
    );
  }

  // ── Pantry Cross-Check ────────────────────────────────────────────────────

  /// Checks [ingredientName] against [pantryItems] and returns how much is
  /// still needed after subtracting available pantry stock.
  ///
  /// [neededAmount] and [neededUnit] come from the recipe (scaled to servings).
  /// [pantryItems] is the combined list from PantryService (pantry + fridge).
  static PantryCheckResult checkPantry({
    required String ingredientName,
    required double neededAmount,
    required String neededUnit,
    required List<Map<String, dynamic>> pantryItems,
  }) {
    if (neededAmount <= 0) {
      return PantryCheckResult(
          status: PantryStatus.covered, shortageAmount: 0, neededAmount: 0);
    }

    final nameLower = ingredientName.toLowerCase().trim();

    // Fuzzy name match: pantry item name contains ingredient or vice versa
    final matches = pantryItems.where((item) {
      final itemName =
      (item['item_name'] as String? ?? '').toLowerCase().trim();
      return itemName.contains(nameLower) ||
          nameLower.contains(itemName) ||
          _tokenMatch(nameLower, itemName);
    }).toList();

    if (matches.isEmpty) {
      return PantryCheckResult(
          status: PantryStatus.missing,
          shortageAmount: neededAmount,
          neededAmount: neededAmount);
    }

    // Sum available pantry quantity, accounting for usage_percent
    double totalAvailableBase = 0;
    for (final match in matches) {
      final qty = (match['quantity'] as num?)?.toDouble() ?? 0;
      final unit = (match['unit'] as String? ?? '').toLowerCase().trim();
      final usagePct = (match['usage_percent'] as num?)?.toDouble() ?? 100.0;
      final effective = qty * (usagePct / 100.0);
      totalAvailableBase += _toBaseUnit(effective, unit);
    }

    final neededBase = _toBaseUnit(neededAmount, neededUnit.toLowerCase().trim());

    if (neededBase <= 0) {
      return PantryCheckResult(
          status: PantryStatus.covered, shortageAmount: 0, neededAmount: neededAmount);
    }

    final shortageBase = neededBase - totalAvailableBase;

    if (shortageBase <= 0) {
      // Fully covered
      return PantryCheckResult(
          status: PantryStatus.covered, shortageAmount: 0, neededAmount: neededAmount);
    }

    // Convert shortage back to original unit
    final shortageInUnit =
    _fromBaseUnit(shortageBase, neededUnit.toLowerCase().trim());

    final status = totalAvailableBase > 0
        ? PantryStatus.partial
        : PantryStatus.missing;

    return PantryCheckResult(
        status: status,
        shortageAmount: shortageInUnit,
        neededAmount: neededAmount);
  }

  // ── Unit Conversion ───────────────────────────────────────────────────────

  /// Converts [amount] of [unit] → a common base unit for comparison.
  /// Weight → grams. Volume → millilitres. Count → arbitrary 100 units.
  static double _toBaseUnit(double amount, String unit) {
    switch (unit) {
    // Weight
      case 'kg':
        return amount * 1000;
      case 'g':
      case 'gram':
      case 'grams':
        return amount;
      case 'oz':
        return amount * 28.35;
      case 'lb':
      case 'lbs':
        return amount * 453.6;
    // Volume
      case 'l':
      case 'litre':
      case 'liter':
      case 'liters':
      case 'litres':
        return amount * 1000;
      case 'ml':
      case 'milliliter':
      case 'millilitre':
        return amount;
      case 'cup':
      case 'cups':
        return amount * 240;
      case 'tbsp':
      case 'tablespoon':
      case 'tablespoons':
        return amount * 15;
      case 'tsp':
      case 'teaspoon':
      case 'teaspoons':
        return amount * 5;
      case 'fl oz':
      case 'floz':
        return amount * 29.57;
    // Small measures
      case 'pinch':
      case 'pinches':
        return amount * 0.5;
      case 'dash':
        return amount * 0.6;
      case 'clove':
      case 'cloves':
        return amount * 5;
    // Count
      case 'piece':
      case 'pieces':
      case 'pcs':
      case 'unit':
      case 'units':
      case 'whole':
      case 'item':
        return amount * 100;
      case 'bunch':
      case 'bunches':
        return amount * 150;
      default:
        return amount; // Unknown unit — compare as-is
    }
  }

  static double _fromBaseUnit(double baseAmount, String targetUnit) {
    switch (targetUnit) {
      case 'kg':
        return baseAmount / 1000;
      case 'g':
      case 'gram':
      case 'grams':
        return baseAmount;
      case 'l':
      case 'litre':
      case 'liter':
        return baseAmount / 1000;
      case 'ml':
        return baseAmount;
      case 'cup':
      case 'cups':
        return baseAmount / 240;
      case 'tbsp':
      case 'tablespoon':
        return baseAmount / 15;
      case 'tsp':
      case 'teaspoon':
        return baseAmount / 5;
      case 'piece':
      case 'pieces':
      case 'pcs':
      case 'unit':
        return baseAmount / 100;
      case 'pinch':
      case 'pinches':
        return baseAmount / 0.5;
      default:
        return baseAmount;
    }
  }

  // ── Heuristic helpers ─────────────────────────────────────────────────────

  static String _heuristicPurchaseUnit(String name) {
    final n = name.toLowerCase();
    if (_matchAny(n, ['chicken', 'beef', 'pork', 'lamb', 'mutton'])) {
      return '500g pack';
    }
    if (_matchAny(n, ['fish', 'prawn', 'shrimp', 'squid', 'crab'])) {
      return '500g fresh';
    }
    if (_matchAny(n, ['egg', 'eggs'])) return '10-pack eggs';
    if (_matchAny(n, ['milk', 'fresh milk'])) return '1L carton';
    if (_matchAny(n, ['cream', 'heavy cream', 'whipping cream'])) {
      return '250ml carton';
    }
    if (_matchAny(n, ['butter'])) return '250g block';
    if (_matchAny(n, ['cheese', 'cheddar', 'mozzarella'])) {
      return '200g pack';
    }
    if (_matchAny(n, ['salt'])) return '500g pack';
    if (_matchAny(n, ['sugar', 'brown sugar'])) return '1kg bag';
    if (_matchAny(n, ['flour', 'wheat flour'])) return '1kg bag';
    if (_matchAny(n, ['rice'])) return '5kg bag';
    if (_matchAny(n, ['oil', 'cooking oil', 'olive oil', 'vegetable oil'])) {
      return '1L bottle';
    }
    if (_matchAny(n, ['soy sauce', 'oyster sauce', 'fish sauce'])) {
      return '300ml bottle';
    }
    if (_matchAny(n, ['bread', 'toast', 'bun'])) return '1 loaf';
    if (_matchAny(n, ['bread crumb', 'breadcrumb', 'panko'])) {
      return '400g pack';
    }
    if (_matchAny(n, ['onion', 'shallot'])) return '500g bag';
    if (_matchAny(n, ['garlic'])) return '1 head';
    if (_matchAny(n, ['ginger'])) return '200g pack';
    if (_matchAny(n, ['tomato', 'cherry tomato'])) return '500g pack';
    if (_matchAny(n, ['potato', 'sweet potato'])) return '500g bag';
    if (_matchAny(n, ['noodle', 'pasta', 'spaghetti'])) return '400g pack';
    if (_matchAny(n, ['pepper', 'black pepper', 'white pepper'])) {
      return '50g bottle';
    }
    if (_matchAny(n, ['chili', 'chilli', 'cili'])) return '200g pack';
    if (_matchAny(n, ['lemon', 'lime'])) return '3-pack';
    return '1 pack';
  }

  static double _heuristicPrice(String name) {
    final n = name.toLowerCase();
    if (_matchAny(n, ['chicken', 'beef', 'pork', 'lamb', 'mutton'])) {
      return 8.00;
    }
    if (_matchAny(n, ['fish', 'salmon', 'tuna'])) return 12.00;
    if (_matchAny(n, ['prawn', 'shrimp', 'squid'])) return 14.00;
    if (_matchAny(n, ['egg', 'eggs'])) return 6.50;
    if (_matchAny(n, ['milk'])) return 5.90;
    if (_matchAny(n, ['cream'])) return 7.50;
    if (_matchAny(n, ['butter'])) return 8.90;
    if (_matchAny(n, ['cheese', 'cheddar', 'mozzarella'])) return 9.90;
    if (_matchAny(n, ['rice'])) return 13.90;
    if (_matchAny(n, ['flour'])) return 3.80;
    if (_matchAny(n, ['sugar'])) return 3.20;
    if (_matchAny(n, ['salt'])) return 2.50;
    if (_matchAny(n, ['oil', 'cooking oil'])) return 7.50;
    if (_matchAny(n, ['olive oil'])) return 16.90;
    if (_matchAny(n, ['soy sauce', 'oyster sauce', 'fish sauce'])) return 4.50;
    if (_matchAny(n, ['bread'])) return 4.20;
    if (_matchAny(n, ['bread crumb', 'breadcrumb', 'panko'])) return 5.50;
    if (_matchAny(n, ['noodle', 'pasta', 'spaghetti'])) return 3.50;
    if (_matchAny(n, ['onion', 'shallot'])) return 2.50;
    if (_matchAny(n, ['garlic'])) return 1.90;
    if (_matchAny(n, ['ginger'])) return 2.50;
    if (_matchAny(n, ['tomato'])) return 3.50;
    if (_matchAny(n, ['potato'])) return 4.00;
    if (_matchAny(n, ['pepper', 'black pepper', 'white pepper'])) return 3.00;
    if (_matchAny(n, ['chili', 'chilli'])) return 2.80;
    if (_matchAny(n, ['lemon', 'lime'])) return 2.50;
    if (_matchAny(n, ['cream cheese'])) return 8.50;
    if (_matchAny(n, ['yogurt', 'yoghurt'])) return 5.50;
    return 4.50; // Generic fallback
  }

  // ── String helpers ────────────────────────────────────────────────────────

  static bool _matchAny(String name, List<String> keywords) =>
      keywords.any((k) => name.contains(k));

  /// Token-level match: at least one word in common between two names.
  static bool _tokenMatch(String a, String b) {
    final tokensA = a.split(RegExp(r'\s+')).where((t) => t.length > 2).toSet();
    final tokensB = b.split(RegExp(r'\s+')).where((t) => t.length > 2).toSet();
    return tokensA.intersection(tokensB).isNotEmpty;
  }

  /// Formats a shortage amount for display, e.g. 0.3 kg → "300 g".
  static String formatShortage(double amount, String unit) {
    if (amount <= 0) return '';
    final u = unit.toLowerCase().trim();

    // Auto-scale small kg values to grams for readability
    if (u == 'kg' && amount < 1.0) {
      return '${(amount * 1000).round()} g';
    }
    // Auto-scale large ml values to litres
    if (u == 'ml' && amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)} L';
    }

    final display = amount == amount.truncateToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(1);
    return unit.isNotEmpty ? '$display $unit' : display;
  }
}