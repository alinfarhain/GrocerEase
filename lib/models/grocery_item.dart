// ─────────────────────────────────────────────
//  grocery_item.dart  (updated)
//  Changes:
//   • Added `recipe` field so items can be grouped by recipe
//   • Added `unit` field (e.g. "kg", "pcs") for price-per-unit display
//   • Added `dietaryTags` so the UI can warn when an item conflicts
//     with the user's dietary preference
// ─────────────────────────────────────────────

class GroceryItem {
  final String id;
  final String name;
  final String quantity;

  /// Numeric amount of the quantity (e.g. 2 for "2 kg")
  final double? quantityAmount;

  /// Unit string (e.g. "kg", "pcs", "L", "g"). Null means no unit.
  final String? unit;

  final double price;
  final String category;

  /// Which recipe this item belongs to. Null = not linked to any recipe.
  final String? recipe;

  /// Dietary labels that apply to this item, e.g. ['Vegan', 'Halal'].
  /// Used to surface a warning when it conflicts with user preferences.
  final List<String> dietaryTags;

  bool isChecked;

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
  });

  /// Price per unit string, e.g. "RM 3.50 / kg".
  /// Returns null when there is not enough information.
  String? pricePerUnit(String currencySymbol) {
    if (unit == null || quantityAmount == null || quantityAmount! <= 0) {
      return null;
    }
    final ppu = price / quantityAmount!;
    return '${currencySymbol}${ppu.toStringAsFixed(2)} / $unit';
  }

  /// Returns true when this item's dietary tags are incompatible with
  /// [userPreference]. Rules:
  ///   • Vegetarian → warn if item contains 'Meat' or 'Seafood'
  ///   • Vegan      → warn if item contains 'Meat', 'Seafood', or 'Dairy'
  ///   • Halal      → warn if item contains 'Non-Halal'
  ///   • Pescatarian→ warn if item contains 'Meat'
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

  GroceryCategory({
    required this.name,
    required this.items,
  });
}

// ─── Recipe grouping (NEW) ───────────────────
class GroceryRecipe {
  final String name;
  final List<GroceryItem> items;

  GroceryRecipe({
    required this.name,
    required this.items,
  });
}

// ─── Currency (NEW) ─────────────────────────
class AppCurrency {
  final String code;   // e.g. "MYR"
  final String symbol; // e.g. "RM "
  final String label;  // e.g. "Malaysian Ringgit (RM)"

  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.label,
  });

  static const List<AppCurrency> supported = [
    AppCurrency(code: 'MYR', symbol: 'RM ', label: 'Malaysian Ringgit (RM)'),
    AppCurrency(code: 'USD', symbol: '\$ ',  label: 'US Dollar (\$)'),
    AppCurrency(code: 'SGD', symbol: 'S\$ ', label: 'Singapore Dollar (S\$)'),
    AppCurrency(code: 'EUR', symbol: '€ ',  label: 'Euro (€)'),
    AppCurrency(code: 'GBP', symbol: '£ ',  label: 'British Pound (£)'),
  ];
}
