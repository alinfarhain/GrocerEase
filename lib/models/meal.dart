/// Represents a single planned meal entry, backed by the meal_plans Supabase table.
class Meal {
  /// Supabase row UUID — null for locally-constructed meals not yet saved.
  final String? id;

  final String title;

  /// One of: 'Breakfast' | 'Lunch' | 'Dinner' | 'High Tea' | 'Custom'.
  /// When 'Custom', [customCategoryName] holds the user's typed label.
  final String mealType;

  /// Only populated when [mealType] == 'Custom'.
  final String? customCategoryName;

  final int servings;
  final int calories;

  /// Full recipe data map (for navigation to RecipeView).
  final Map<String, dynamic>? originalData;

  const Meal({
    this.id,
    required this.title,
    required this.mealType,
    this.customCategoryName,
    required this.servings,
    required this.calories,
    this.originalData,
  });

  /// The label displayed in the UI for the meal category.
  String get categoryLabel {
    if (mealType == 'Custom' &&
        customCategoryName != null &&
        customCategoryName!.isNotEmpty) {
      return customCategoryName!;
    }
    return mealType;
  }

  Map<String, dynamic> toMap() {
    return {
      'name'               : title,
      'mealType'           : [mealType],
      'servings'           : servings,
      'caloriesPerServing' : calories,
      ...?originalData,
    };
  }
}