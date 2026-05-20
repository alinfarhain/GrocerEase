class RecipeModel {
  final String? id;
  final String recipeName;
  final String? imageUrl;
  final int cookingDuration;
  final double estimatedBudget;
  final int servings;
  final int caloriesPerServing;
  final String difficultyLevel;
  final List<String> toolsRequired;
  final List<Map<String, dynamic>> ingredients;
  final List<String> cookingSteps;

  RecipeModel({
    this.id,
    required this.recipeName,
    this.imageUrl,
    required this.cookingDuration,
    required this.estimatedBudget,
    required this.servings,
    required this.caloriesPerServing,
    required this.difficultyLevel,
    required this.toolsRequired,
    required this.ingredients,
    required this.cookingSteps,
  });

  // Convert model → Map to send to Supabase
  Map<String, dynamic> toMap() {
    return {
      'recipe_name': recipeName,
      'image_url': imageUrl,
      'cooking_duration': cookingDuration,
      'estimated_budget': estimatedBudget,
      'servings': servings,
      'calories_per_serving': caloriesPerServing,
      'difficulty_level': difficultyLevel,
      'tools_required': toolsRequired,
      'ingredients': ingredients,
      'cooking_steps': cookingSteps,
    };
  }

  // Convert Supabase response → Model
  factory RecipeModel.fromMap(Map<String, dynamic> map) {
    return RecipeModel(
      id: map['id'],
      recipeName: map['recipe_name'],
      imageUrl: map['image_url'],
      cookingDuration: map['cooking_duration'],
      estimatedBudget: (map['estimated_budget'] as num).toDouble(),
      servings: map['servings'],
      caloriesPerServing: map['calories_per_serving'],
      difficultyLevel: map['difficulty_level'],
      toolsRequired: List<String>.from(map['tools_required']),
      ingredients: List<Map<String, dynamic>>.from(map['ingredients']),
      cookingSteps: List<String>.from(map['cooking_steps']),
    );
  }
}