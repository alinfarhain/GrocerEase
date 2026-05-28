// lib/models/grocery_item.dart
// Changes vs previous version:
//   • Added suggestedPurchaseUnit  — e.g. "500g chicken tray"
//   • Added priceSource            — "AI Malaysian Estimate" | "Estimated" | "User"
//   • Added pantryShortageAmount   — how much was still needed after pantry check

class GroceryItem {
  final String id;

  // Mutable — changed via the Edit sheet
  String name;
  String quantity;
  double? quantityAmount;
  String? unit;
  double price;

  final String category;
  final String? recipe;
  final List<String> dietaryTags;
  bool isChecked;

  // ── Smart pricing fields (nullable for backward compat with old rows) ──────
  /// Retail product description, e.g. "500g chicken tray" or "300ml bottle".
  final String? suggestedPurchaseUnit;

  /// Where the price came from: "AI Malaysian Estimate" | "Estimated" | "User".
  final String? priceSource;

  /// How much of this ingredient was still needed after subtracting pantry stock.
  /// Used for display ("Needed: 300g after pantry").
  final double? pantryShortageAmount;

  GroceryItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.quantityAmount,
    this.unit,
    required this.price,
    required this.category,
    this.recipe,
    this.dietaryTags = const [],
    this.isChecked = false,
    this.suggestedPurchaseUnit,
    this.priceSource,
    this.pantryShortageAmount,
  });

  /// Price per unit string e.g. "RM 2.00 / kg".
  /// Returns null when there is not enough information.
  String? pricePerUnit(String currencySymbol) {
    if (unit == null || quantityAmount == null || quantityAmount! <= 0) {
      return null;
    }
    final ppu = price / quantityAmount!;
    return '$currencySymbol${ppu.toStringAsFixed(2)} / $unit';
  }

  /// Returns true when this item's dietary tags conflict with [userPreference].
  bool hasDietaryWarningFor(String userPreference) {
    final tags = dietaryTags.map((t) => t.toLowerCase()).toSet();
    switch (userPreference) {
      case 'Vegetarian':
        return tags.contains('meat') || tags.contains('seafood');
      case 'Vegan':
        return tags.contains('meat') ||
            tags.contains('seafood') ||
            tags.contains('dairy');
      case 'Halal':
        return tags.contains('non-halal');
      case 'Pescatarian':
        return tags.contains('meat');
      default:
        return false;
    }
  }
}

// ─── Category grouping ───────────────────────
class GroceryCategory {
  final String name;
  final List<GroceryItem> items;
  GroceryCategory({required this.name, required this.items});
}

// ─── Recipe grouping ─────────────────────────
class GroceryRecipe {
  final String name;
  final List<GroceryItem> items;
  GroceryRecipe({required this.name, required this.items});
}

// ─── Currency ────────────────────────────────
class AppCurrency {
  final String code;
  final String symbol;
  final String label;

  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.label,
  });

  static const List<AppCurrency> supported = [
    AppCurrency(code: 'MYR', symbol: 'RM ', label: 'Malaysian Ringgit (RM)'),
    AppCurrency(code: 'USD', symbol: '\$ ', label: 'US Dollar (\$)'),
    AppCurrency(code: 'SGD', symbol: 'S\$ ', label: 'Singapore Dollar (S\$)'),
    AppCurrency(code: 'EUR', symbol: '€ ', label: 'Euro (€)'),
    AppCurrency(code: 'GBP', symbol: '£ ', label: 'British Pound (£)'),
  ];
}