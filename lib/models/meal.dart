class Meal {
  final String title;
  final String mealType;
  final int servings;
  final int calories;
  final Map<String, dynamic>? originalData;

  Meal({
    required this.title,
    required this.mealType,
    required this.servings,
    required this.calories,
    this.originalData,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': title,
      'mealType': [mealType],
      'servings': servings,
      'caloriesPerServing': calories,
      ...?originalData,
    };
  }
}
