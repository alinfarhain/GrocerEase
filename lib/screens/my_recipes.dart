import 'package:flutter/material.dart';
import '../globals/app_state.dart';
import 'package:go_router/go_router.dart';

class MyRecipes extends StatefulWidget {
  const MyRecipes({super.key, this.initialEditMode = false});

  final bool initialEditMode;

  @override
  State<MyRecipes> createState() {
    return _MyRecipesState();
  }
}

class _MyRecipesState extends State<MyRecipes> {
  bool isSavedRecipesSelected = true;

  String searchQuery = '';

  bool showFilters = false;

  double? minBudget;

  double? maxBudget;

  int? maxDuration;

  int? maxServings;

  int? maxCalories;

  String? selectedDifficulty;

  final TextEditingController _minBudgetController = TextEditingController();

  final TextEditingController _maxBudgetController = TextEditingController();

  final TextEditingController _durationController = TextEditingController();

  final TextEditingController _servingsController = TextEditingController();

  final TextEditingController _caloriesController = TextEditingController();

  final List<Map<String, dynamic>> _recipes = [
    {
      'id': 1,
      'name': 'Classic Margherita Pizza',
      'ingredients': [
        'Pizza dough',
        'Tomato sauce',
        'Fresh mozzarella cheese',
        'Fresh basil leaves',
        'Olive oil',
        'Salt and pepper to taste',
      ],
      'instructions': [
        'Preheat the oven to 475°F (245°C).',
        'Roll out the pizza dough and spread tomato sauce evenly.',
        'Top with slices of fresh mozzarella and fresh basil leaves.',
        'Drizzle with olive oil and season with salt and pepper.',
        'Bake in the preheated oven for 12-15 minutes or until the crust is golden brown.',
        'Slice and serve hot.',
      ],
      'prepTimeMinutes': 20,
      'cookTimeMinutes': 15,
      'servings': 4,
      'difficulty': 'Easy',
      'cuisine': 'Italian',
      'caloriesPerServing': 300,
      'tags': ['Pizza', 'Italian'],
      'userId': 166,
      'image': 'https://cdn.dummyjson.com/recipe-images/1.webp',
      'rating': 4.6,
      'reviewCount': 98,
      'mealType': ['Dinner'],
      'isFavourite': true,
      'price': 'RM15',
    },
    {
      'id': 2,
      'name': 'Vegetarian Stir-Fry',
      'ingredients': [
        'Tofu, cubed',
        'Broccoli florets',
        'Carrots, sliced',
        'Bell peppers, sliced',
        'Soy sauce',
        'Ginger, minced',
        'Garlic, minced',
        'Sesame oil',
        'Cooked rice for serving',
      ],
      'instructions': [
        'In a wok, heat sesame oil over medium-high heat.',
        'Add minced ginger and garlic, sauté until fragrant.',
        'Add cubed tofu and stir-fry until golden brown.',
        'Add broccoli, carrots, and bell peppers. Cook until vegetables are tender-crisp.',
        'Pour soy sauce over the stir-fry and toss to combine.',
        'Serve over cooked rice.',
      ],
      'prepTimeMinutes': 15,
      'cookTimeMinutes': 20,
      'servings': 3,
      'difficulty': 'Medium',
      'cuisine': 'Asian',
      'caloriesPerServing': 250,
      'tags': ['Vegetarian', 'Stir-fry', 'Asian'],
      'userId': 143,
      'image': 'https://cdn.dummyjson.com/recipe-images/2.webp',
      'rating': 4.7,
      'reviewCount': 26,
      'mealType': ['Lunch'],
      'isFavourite': false,
      'price': 'RM18',
    },
    {
      'id': 3,
      'name': 'Chocolate Chip Cookies',
      'ingredients': [
        'All-purpose flour',
        'Butter, softened',
        'Brown sugar',
        'White sugar',
        'Eggs',
        'Vanilla extract',
        'Baking soda',
        'Salt',
        'Chocolate chips',
      ],
      'instructions': [
        'Preheat the oven to 350°F (175°C).',
        'In a bowl, cream together softened butter, brown sugar, and white sugar.',
        'Beat in eggs one at a time, then stir in vanilla extract.',
        'Combine flour, baking soda, and salt. Gradually add to the wet ingredients.',
        'Fold in chocolate chips.',
        'Drop rounded tablespoons of dough onto ungreased baking sheets.',
        'Bake for 10-12 minutes or until edges are golden brown.',
        'Allow cookies to cool on the baking sheet for a few minutes before transferring to a wire rack.',
      ],
      'prepTimeMinutes': 15,
      'cookTimeMinutes': 10,
      'servings': 24,
      'difficulty': 'Easy',
      'cuisine': 'American',
      'caloriesPerServing': 150,
      'tags': ['Cookies', 'Dessert', 'Baking'],
      'userId': 34,
      'image': 'https://cdn.dummyjson.com/recipe-images/3.webp',
      'rating': 4.9,
      'reviewCount': 13,
      'mealType': ['Snack', 'Dessert'],
      'isFavourite': true,
      'price': 'RM12',
    },
    {
      'id': 4,
      'name': 'Chicken Alfredo Pasta',
      'ingredients': [
        'Fettuccine pasta',
        'Chicken breast, sliced',
        'Heavy cream',
        'Parmesan cheese, grated',
        'Garlic, minced',
        'Butter',
        'Salt and pepper to taste',
        'Fresh parsley for garnish',
      ],
      'instructions': [
        'Cook fettuccine pasta according to package instructions.',
        'In a pan, sauté sliced chicken in butter until fully cooked.',
        'Add minced garlic and cook until fragrant.',
        'Pour in heavy cream and grated Parmesan cheese. Stir until the cheese is melted.',
        'Season with salt and pepper to taste.',
        'Combine the Alfredo sauce with cooked pasta.',
        'Garnish with fresh parsley before serving.',
      ],
      'prepTimeMinutes': 15,
      'cookTimeMinutes': 20,
      'servings': 4,
      'difficulty': 'Medium',
      'cuisine': 'Italian',
      'caloriesPerServing': 500,
      'tags': ['Pasta', 'Chicken'],
      'userId': 136,
      'image': 'https://cdn.dummyjson.com/recipe-images/4.webp',
      'rating': 4.9,
      'reviewCount': 82,
      'mealType': ['Lunch', 'Dinner'],
      'isFavourite': false,
      'price': 'RM22',
    },
    {
      'id': 5,
      'name': 'Mango Salsa Chicken',
      'ingredients': [
        'Chicken thighs',
        'Mango, diced',
        'Red onion, finely chopped',
        'Cilantro, chopped',
        'Lime juice',
        'Jalapeño, minced',
        'Salt and pepper to taste',
        'Cooked rice for serving',
      ],
      'instructions': [
        'Season chicken thighs with salt and pepper.',
        'Grill or bake chicken until fully cooked.',
        'In a bowl, combine diced mango, chopped red onion, cilantro, minced jalapeño, and lime juice.',
        'Dice the cooked chicken and mix it with the mango salsa.',
        'Serve over cooked rice.',
      ],
      'prepTimeMinutes': 15,
      'cookTimeMinutes': 25,
      'servings': 3,
      'difficulty': 'Easy',
      'cuisine': 'Mexican',
      'caloriesPerServing': 380,
      'tags': ['Chicken', 'Salsa'],
      'userId': 26,
      'image': 'https://cdn.dummyjson.com/recipe-images/5.webp',
      'rating': 4.9,
      'reviewCount': 63,
      'mealType': ['Dinner'],
      'isFavourite': true,
      'price': 'RM20',
    },
    {
      'id': 6,
      'name': 'Quinoa Salad with Avocado',
      'ingredients': [
        'Quinoa, cooked',
        'Avocado, diced',
        'Cherry tomatoes, halved',
        'Cucumber, diced',
        'Red bell pepper, diced',
        'Feta cheese, crumbled',
        'Lemon vinaigrette dressing',
        'Salt and pepper to taste',
      ],
      'instructions': [
        'In a large bowl, combine cooked quinoa, diced avocado, halved cherry tomatoes, diced cucumber, diced red bell pepper, and crumbled feta cheese.',
        'Drizzle with lemon vinaigrette dressing and toss to combine.',
        'Season with salt and pepper to taste.',
        'Chill in the refrigerator before serving.',
      ],
      'prepTimeMinutes': 20,
      'cookTimeMinutes': 15,
      'servings': 4,
      'difficulty': 'Easy',
      'cuisine': 'Mediterranean',
      'caloriesPerServing': 280,
      'tags': ['Salad', 'Quinoa'],
      'userId': 197,
      'image': 'https://cdn.dummyjson.com/recipe-images/6.webp',
      'rating': 4.4,
      'reviewCount': 59,
      'mealType': ['Lunch', 'Side Dish'],
      'isFavourite': false,
      'price': 'RM16',
    },
    {
      'id': 7,
      'name': 'Tomato Basil Bruschetta',
      'ingredients': [
        'Baguette, sliced',
        'Tomatoes, diced',
        'Fresh basil, chopped',
        'Garlic cloves, minced',
        'Balsamic glaze',
        'Olive oil',
        'Salt and pepper to taste',
      ],
      'instructions': [
        'Preheat the oven to 375°F (190°C).',
        'Place baguette slices on a baking sheet and toast in the oven until golden brown.',
        'In a bowl, combine diced tomatoes, chopped fresh basil, minced garlic, and a drizzle of olive oil.',
        'Season with salt and pepper to taste.',
        'Top each toasted baguette slice with the tomato-basil mixture.',
        'Drizzle with balsamic glaze before serving.',
      ],
      'prepTimeMinutes': 15,
      'cookTimeMinutes': 10,
      'servings': 6,
      'difficulty': 'Easy',
      'cuisine': 'Italian',
      'caloriesPerServing': 120,
      'tags': ['Bruschetta', 'Italian'],
      'userId': 137,
      'image': 'https://cdn.dummyjson.com/recipe-images/7.webp',
      'rating': 4.7,
      'reviewCount': 95,
      'mealType': ['Appetizer'],
      'isFavourite': false,
      'price': 'RM10',
    },
    {
      'id': 8,
      'name': 'Beef and Broccoli Stir-Fry',
      'ingredients': [
        'Beef sirloin, thinly sliced',
        'Broccoli florets',
        'Soy sauce',
        'Oyster sauce',
        'Sesame oil',
        'Garlic, minced',
        'Ginger, minced',
        'Cornstarch',
        'Cooked white rice for serving',
      ],
      'instructions': [
        'In a bowl, mix soy sauce, oyster sauce, sesame oil, and cornstarch to create the sauce.',
        'In a wok, stir-fry thinly sliced beef until browned. Remove from the wok.',
        'Stir-fry broccoli florets, minced garlic, and minced ginger in the same wok.',
        'Add the cooked beef back to the wok and pour the sauce over the mixture.',
        'Stir until everything is coated and heated through.',
        'Serve over cooked white rice.',
      ],
      'prepTimeMinutes': 20,
      'cookTimeMinutes': 15,
      'servings': 4,
      'difficulty': 'Medium',
      'cuisine': 'Asian',
      'caloriesPerServing': 380,
      'tags': ['Beef', 'Stir-fry', 'Asian'],
      'userId': 18,
      'image': 'https://cdn.dummyjson.com/recipe-images/8.webp',
      'rating': 4.7,
      'reviewCount': 58,
      'mealType': ['Dinner'],
      'isFavourite': true,
      'price': 'RM25',
    },
    {
      'id': 9,
      'name': 'Caprese Salad',
      'ingredients': [
        'Tomatoes, sliced',
        'Fresh mozzarella cheese, sliced',
        'Fresh basil leaves',
        'Balsamic glaze',
        'Extra virgin olive oil',
        'Salt and pepper to taste',
      ],
      'instructions': [
        'Arrange alternating slices of tomatoes and fresh mozzarella on a serving platter.',
        'Tuck fresh basil leaves between the slices.',
        'Drizzle with balsamic glaze and extra virgin olive oil.',
        'Season with salt and pepper to taste.',
        'Serve immediately as a refreshing salad.',
      ],
      'prepTimeMinutes': 10,
      'cookTimeMinutes': 0,
      'servings': 2,
      'difficulty': 'Easy',
      'cuisine': 'Italian',
      'caloriesPerServing': 200,
      'tags': ['Salad', 'Caprese'],
      'userId': 128,
      'image': 'https://cdn.dummyjson.com/recipe-images/9.webp',
      'rating': 4.6,
      'reviewCount': 82,
      'mealType': ['Lunch'],
      'isFavourite': false,
      'price': 'RM14',
    },
    {
      'id': 10,
      'name': 'Shrimp Scampi Pasta',
      'ingredients': [
        'Linguine pasta',
        'Shrimp, peeled and deveined',
        'Garlic, minced',
        'White wine',
        'Lemon juice',
        'Red pepper flakes',
        'Fresh parsley, chopped',
        'Salt and pepper to taste',
      ],
      'instructions': [
        'Cook linguine pasta according to package instructions.',
        'In a skillet, sauté minced garlic in olive oil until fragrant.',
        'Add shrimp and cook until pink and opaque.',
        'Pour in white wine and lemon juice. Simmer until the sauce slightly thickens.',
        'Season with red pepper flakes, salt, and pepper.',
        'Toss cooked linguine in the shrimp scampi sauce.',
        'Garnish with chopped fresh parsley before serving.',
      ],
      'prepTimeMinutes': 15,
      'cookTimeMinutes': 20,
      'servings': 3,
      'difficulty': 'Medium',
      'cuisine': 'Italian',
      'caloriesPerServing': 400,
      'tags': ['Pasta', 'Shrimp'],
      'userId': 114,
      'image': 'https://cdn.dummyjson.com/recipe-images/10.webp',
      'rating': 4.3,
      'reviewCount': 5,
      'mealType': ['Dinner'],
      'isFavourite': false,
      'price': 'RM28',
    },
    {
      'id': 11,
      'name': 'Chicken Biryani',
      'ingredients': [
        'Basmati rice',
        'Chicken, cut into pieces',
        'Onions, thinly sliced',
        'Tomatoes, chopped',
        'Yogurt',
        'Ginger-garlic paste',
        'Biryani masala',
        'Green chilies, sliced',
        'Fresh coriander leaves',
        'Mint leaves',
        'Ghee',
        'Salt to taste',
      ],
      'instructions': [
        'Marinate chicken with yogurt, ginger-garlic paste, biryani masala, and salt.',
        'In a pot, sauté sliced onions until golden brown. Remove half for later use.',
        'Layer marinated chicken, chopped tomatoes, half of the fried onions, and rice in the pot.',
        'Top with ghee, green chilies, fresh coriander leaves, mint leaves, and the remaining fried onions.',
        'Cover and cook on low heat until the rice is fully cooked and aromatic.',
        'Serve hot, garnished with additional coriander and mint leaves.',
      ],
      'prepTimeMinutes': 30,
      'cookTimeMinutes': 45,
      'servings': 6,
      'difficulty': 'Medium',
      'cuisine': 'Pakistani',
      'caloriesPerServing': 550,
      'tags': [
        'Biryani',
        'Chicken',
        'Main course',
        'Indian',
        'Pakistani',
        'Asian',
      ],
      'userId': 133,
      'image': 'https://cdn.dummyjson.com/recipe-images/11.webp',
      'rating': 5,
      'reviewCount': 32,
      'mealType': ['Lunch', 'Dinner'],
      'isFavourite': true,
      'price': 'RM30',
    },
    {
      'id': 12,
      'name': 'Chicken Karahi',
      'ingredients': [
        'Chicken, cut into pieces',
        'Tomatoes, chopped',
        'Green chilies, sliced',
        'Ginger, julienned',
        'Garlic, minced',
        'Coriander powder',
        'Cumin powder',
        'Red chili powder',
        'Garam masala',
        'Cooking oil',
        'Fresh coriander leaves',
        'Salt to taste',
      ],
      'instructions': [
        'In a wok (karahi), heat cooking oil and sauté minced garlic until golden brown.',
        'Add chicken pieces and cook until browned on all sides.',
        'Add chopped tomatoes, green chilies, ginger, and spices. Cook until tomatoes are soft.',
        'Cover and simmer until the chicken is tender and the oil separates from the masala.',
        'Garnish with fresh coriander leaves and serve hot with naan or rice.',
      ],
      'prepTimeMinutes': 20,
      'cookTimeMinutes': 30,
      'servings': 4,
      'difficulty': 'Easy',
      'cuisine': 'Pakistani',
      'caloriesPerServing': 420,
      'tags': [
        'Chicken',
        'Karahi',
        'Main course',
        'Indian',
        'Pakistani',
        'Asian',
      ],
      'userId': 49,
      'image': 'https://cdn.dummyjson.com/recipe-images/12.webp',
      'rating': 4.8,
      'reviewCount': 68,
      'mealType': ['Lunch', 'Dinner'],
      'isFavourite': false,
      'price': 'RM24',
    },
    {
      'id': 13,
      'name': 'Aloo Keema',
      'ingredients': [
        'Ground beef',
        'Potatoes, peeled and diced',
        'Onions, finely chopped',
        'Tomatoes, chopped',
        'Ginger-garlic paste',
        'Cumin powder',
        'Coriander powder',
        'Turmeric powder',
        'Red chili powder',
        'Cooking oil',
        'Fresh coriander leaves',
        'Salt to taste',
      ],
      'instructions': [
        'In a pan, heat cooking oil and sauté chopped onions until golden brown.',
        'Add ginger-garlic paste and sauté until fragrant.',
        'Add ground beef and cook until browned. Drain excess oil if needed.',
        'Add diced potatoes, chopped tomatoes, and spices. Mix well.',
        'Cover and simmer until the potatoes are tender and the masala is well-cooked.',
        'Garnish with fresh coriander leaves and serve hot with naan or rice.',
      ],
      'prepTimeMinutes': 25,
      'cookTimeMinutes': 35,
      'servings': 5,
      'difficulty': 'Medium',
      'cuisine': 'Pakistani',
      'caloriesPerServing': 380,
      'tags': ['Keema', 'Potatoes', 'Main course', 'Pakistani', 'Asian'],
      'userId': 152,
      'image': 'https://cdn.dummyjson.com/recipe-images/13.webp',
      'rating': 4.6,
      'reviewCount': 53,
      'mealType': ['Lunch', 'Dinner'],
      'isFavourite': false,
      'price': 'RM18',
    },
    {
      'id': 14,
      'name': 'Chapli Kebabs',
      'ingredients': [
        'Ground beef',
        'Onions, finely chopped',
        'Tomatoes, finely chopped',
        'Green chilies, chopped',
        'Coriander leaves, chopped',
        'Pomegranate seeds',
        'Ginger-garlic paste',
        'Cumin powder',
        'Coriander powder',
        'Red chili powder',
        'Egg',
        'Cooking oil',
        'Salt to taste',
      ],
      'instructions': [
        'In a large bowl, mix ground beef, chopped onions, tomatoes, green chilies, coriander leaves, and pomegranate seeds.',
        'Add ginger-garlic paste, cumin powder, coriander powder, red chili powder, and salt. Mix well.',
        'Add an egg to bind the mixture and form into round flat kebabs.',
        'Heat cooking oil in a pan and shallow fry the kebabs until browned on both sides.',
        'Serve hot with naan or mint chutney.',
      ],
      'prepTimeMinutes': 30,
      'cookTimeMinutes': 20,
      'servings': 4,
      'difficulty': 'Medium',
      'cuisine': 'Pakistani',
      'caloriesPerServing': 320,
      'tags': ['Kebabs', 'Beef', 'Indian', 'Pakistani', 'Asian'],
      'userId': 152,
      'image': 'https://cdn.dummyjson.com/recipe-images/14.webp',
      'rating': 4.7,
      'reviewCount': 98,
      'mealType': ['Lunch', 'Dinner', 'Snacks'],
      'isFavourite': true,
      'price': 'RM20',
    },
    {
      'id': 15,
      'name': 'Saag (Spinach) with Makki di Roti',
      'ingredients': [
        'Mustard greens, washed and chopped',
        'Spinach, washed and chopped',
        'Cornmeal (makki ka atta)',
        'Onions, finely chopped',
        'Green chilies, chopped',
        'Ginger, grated',
        'Ghee',
        'Salt to taste',
      ],
      'instructions': [
        'Boil mustard greens and spinach until tender. Drain and blend into a coarse paste.',
        'In a pan, sauté chopped onions, green chilies, and grated ginger in ghee until golden brown.',
        'Add the greens paste and cook until it thickens.',
        'Meanwhile, knead cornmeal with water to make a dough. Roll into rotis (flatbreads).',
        'Cook the rotis on a griddle until golden brown.',
        'Serve hot saag with makki di roti and a dollop of ghee.',
      ],
      'prepTimeMinutes': 40,
      'cookTimeMinutes': 30,
      'servings': 3,
      'difficulty': 'Medium',
      'cuisine': 'Pakistani',
      'caloriesPerServing': 280,
      'tags': ['Saag', 'Roti', 'Main course', 'Indian', 'Pakistani', 'Asian'],
      'userId': 43,
      'image': 'https://cdn.dummyjson.com/recipe-images/15.webp',
      'rating': 4.3,
      'reviewCount': 86,
      'mealType': ['Breakfast', 'Lunch', 'Dinner'],
      'isFavourite': false,
      'price': 'RM15',
    },
    {
      'id': 16,
      'name': 'Japanese Ramen Soup',
      'ingredients': [
        'Ramen noodles',
        'Chicken broth',
        'Soy sauce',
        'Mirin',
        'Sesame oil',
        'Shiitake mushrooms, sliced',
        'Bok choy, chopped',
        'Green onions, sliced',
        'Soft-boiled eggs',
        'Grilled chicken slices',
        'Norwegian seaweed (nori)',
      ],
      'instructions': [
        'Cook ramen noodles according to package instructions and set aside.',
        'In a pot, combine chicken broth, some soy sauce, mirin, and sesame oil. Bring to a simmer.',
        'Add sliced shiitake mushrooms and chopped bok choy. Cook until vegetables are tender.',
        'Divide the cooked noodles into serving bowls and ladle the hot broth over them.',
        'Top with green onions, soft-boiled eggs, grilled chicken slices, and nori.',
        'Serve hot and enjoy the authentic Japanese ramen!',
      ],
      'prepTimeMinutes': 20,
      'cookTimeMinutes': 25,
      'servings': 2,
      'difficulty': 'Medium',
      'cuisine': 'Japanese',
      'caloriesPerServing': 480,
      'tags': ['Ramen', 'Japanese', 'Soup', 'Asian'],
      'userId': 85,
      'image': 'https://cdn.dummyjson.com/recipe-images/16.webp',
      'rating': 4.9,
      'reviewCount': 38,
      'mealType': ['Dinner'],
      'isFavourite': true,
      'price': 'RM22',
    },
    {
      'id': 17,
      'name': 'Moroccan Chickpea Tagine',
      'ingredients': [
        'Chickpeas, cooked',
        'Tomatoes, chopped',
        'Carrots, diced',
        'Onions, finely chopped',
        'Garlic, minced',
        'Cumin',
        'Coriander',
        'Cinnamon',
        'Paprika',
        'Vegetable broth',
        'Olives',
        'Fresh cilantro, chopped',
      ],
      'instructions': [
        'In a tagine or large pot, sauté chopped onions and minced garlic until softened.',
        'Add diced carrots, chopped tomatoes, and cooked chickpeas.',
        'Season with cumin, coriander, cinnamon, and paprika. Stir to coat.',
        'Pour in vegetable broth and bring to a simmer. Cook until carrots are tender.',
        'Stir in olives and garnish with fresh cilantro before serving.',
        'Serve this flavorful Moroccan dish with couscous or crusty bread.',
      ],
      'prepTimeMinutes': 15,
      'cookTimeMinutes': 30,
      'servings': 4,
      'difficulty': 'Easy',
      'cuisine': 'Moroccan',
      'caloriesPerServing': 320,
      'tags': ['Tagine', 'Chickpea', 'Moroccan'],
      'userId': 207,
      'image': 'https://cdn.dummyjson.com/recipe-images/17.webp',
      'rating': 4.5,
      'reviewCount': 50,
      'mealType': ['Dinner'],
      'isFavourite': false,
      'price': 'RM18',
    },
    {
      'id': 18,
      'name': 'Korean Bibimbap',
      'ingredients': [
        'Cooked white rice',
        'Beef bulgogi (marinated and grilled beef slices)',
        'Carrots, julienned and sautéed',
        'Spinach, blanched and seasoned',
        'Zucchini, sliced and grilled',
        'Bean sprouts, blanched',
        'Fried egg',
        'Gochujang (Korean red pepper paste)',
        'Sesame oil',
        'Toasted sesame seeds',
      ],
      'instructions': [
        'Arrange cooked white rice in a bowl.',
        'Top with beef bulgogi, sautéed carrots, seasoned spinach, grilled zucchini, and blanched bean sprouts.',
        'Place a fried egg on top and drizzle with gochujang and sesame oil.',
        'Sprinkle with toasted sesame seeds before serving.',
        'Mix everything together before enjoying this delicious Korean bibimbap!',
        'Feel free to customize with additional vegetables or protein.',
      ],
      'prepTimeMinutes': 30,
      'cookTimeMinutes': 20,
      'servings': 2,
      'difficulty': 'Medium',
      'cuisine': 'Korean',
      'caloriesPerServing': 550,
      'tags': ['Bibimbap', 'Korean', 'Rice'],
      'userId': 121,
      'image': 'https://cdn.dummyjson.com/recipe-images/18.webp',
      'rating': 4.9,
      'reviewCount': 56,
      'mealType': ['Dinner'],
      'isFavourite': true,
      'price': 'RM25',
    },
    {
      'id': 19,
      'name': 'Greek Moussaka',
      'ingredients': [
        'Eggplants, sliced',
        'Ground lamb or beef',
        'Onions, finely chopped',
        'Garlic, minced',
        'Tomatoes, crushed',
        'Red wine',
        'Cinnamon',
        'Allspice',
        'Nutmeg',
        'Olive oil',
        'Milk',
        'Flour',
        'Parmesan cheese',
        'Egg yolks',
      ],
      'instructions': [
        'Preheat oven to 375°F (190°C).',
        'Sauté sliced eggplants in olive oil until browned. Set aside.',
        'In the same pan, cook chopped onions and minced garlic until softened.',
        'Add ground lamb or beef and brown. Stir in crushed tomatoes, red wine, and spices.',
        'In a separate saucepan, make béchamel sauce: melt butter, whisk in flour, add milk, and cook until thickened.',
        'Remove from heat and stir in Parmesan cheese and egg yolks.',
        'In a baking dish, layer eggplants and meat mixture. Top with béchamel sauce.',
        'Bake for 40-45 minutes until golden brown. Let it cool before slicing.',
        'Serve slices of moussaka warm and enjoy this Greek classic!',
      ],
      'prepTimeMinutes': 45,
      'cookTimeMinutes': 45,
      'servings': 6,
      'difficulty': 'Medium',
      'cuisine': 'Greek',
      'caloriesPerServing': 420,
      'tags': ['Moussaka', 'Greek'],
      'userId': 173,
      'image': 'https://cdn.dummyjson.com/recipe-images/19.webp',
      'rating': 4.3,
      'reviewCount': 26,
      'mealType': ['Dinner'],
      'isFavourite': false,
      'price': 'RM28',
    },
    {
      'id': 20,
      'name': 'Butter Chicken (Murgh Makhani)',
      'ingredients': [
        'Chicken thighs, boneless and skinless',
        'Yogurt',
        'Ginger-garlic paste',
        'Garam masala',
        'Kashmiri red chili powder',
        'Tomato puree',
        'Butter',
        'Heavy cream',
        'Kasuri methi (dried fenugreek leaves)',
        'Sugar',
        'Salt to taste',
      ],
      'instructions': [
        'Marinate chicken thighs in a mixture of yogurt, ginger-garlic paste, garam masala, and Kashmiri red chili powder.',
        'In a pan, melt butter and sauté the marinated chicken until browned.',
        'Add tomato puree and cook until the oil separates. Stir in heavy cream.',
        'Sprinkle kasuri methi, sugar, and salt. Simmer until the chicken is fully cooked.',
        'Serve this creamy butter chicken over rice or with naan for an authentic Pakistani/Indian experience.',
      ],
      'prepTimeMinutes': 30,
      'cookTimeMinutes': 25,
      'servings': 4,
      'difficulty': 'Medium',
      'cuisine': 'Pakistani',
      'caloriesPerServing': 480,
      'tags': ['Butter chicken', 'Curry', 'Indian', 'Pakistani', 'Asian'],
      'userId': 138,
      'image': 'https://cdn.dummyjson.com/recipe-images/20.webp',
      'rating': 4.5,
      'reviewCount': 44,
      'mealType': ['Dinner'],
      'isFavourite': true,
      'price': 'RM26',
    },
    {
      'id': 21,
      'name': 'Thai Green Curry',
      'ingredients': [
        'Chicken thighs, boneless and skinless',
        'Green curry paste',
        'Coconut milk',
        'Fish sauce',
        'Sugar',
        'Eggplant, sliced',
        'Bell peppers, sliced',
        'Basil leaves',
        'Jasmine rice for serving',
      ],
      'instructions': [
        'In a pot, simmer green curry paste in coconut milk.',
        'Add chicken, fish sauce, and sugar. Cook until chicken is tender.',
        'Stir in sliced eggplant and bell peppers. Simmer until vegetables are cooked.',
        'Garnish with fresh basil leaves.',
        'Serve hot over jasmine rice and enjoy this Thai classic!',
      ],
      'prepTimeMinutes': 20,
      'cookTimeMinutes': 30,
      'servings': 4,
      'difficulty': 'Medium',
      'cuisine': 'Thai',
      'caloriesPerServing': 480,
      'tags': ['Curry', 'Thai'],
      'userId': 153,
      'image': 'https://cdn.dummyjson.com/recipe-images/21.webp',
      'rating': 4.2,
      'reviewCount': 18,
      'mealType': ['Dinner'],
      'isFavourite': false,
      'price': 'RM24',
    },
    {
      'id': 22,
      'name': 'Mango Lassi',
      'ingredients': [
        'Ripe mango, peeled and diced',
        'Yogurt',
        'Milk',
        'Honey',
        'Cardamom powder',
        'Ice cubes',
      ],
      'instructions': [
        'In a blender, combine diced mango, yogurt, milk, honey, and cardamom powder.',
        'Blend until smooth and creamy.',
        'Add ice cubes and blend again until the lassi is chilled.',
        'Pour into glasses and garnish with a sprinkle of cardamom.',
        'Enjoy this refreshing Mango Lassi!',
      ],
      'prepTimeMinutes': 10,
      'cookTimeMinutes': 0,
      'servings': 2,
      'difficulty': 'Easy',
      'cuisine': 'Indian',
      'caloriesPerServing': 180,
      'tags': ['Lassi', 'Mango', 'Indian', 'Pakistani', 'Asian'],
      'userId': 76,
      'image': 'https://cdn.dummyjson.com/recipe-images/22.webp',
      'rating': 4.7,
      'reviewCount': 15,
      'mealType': ['Beverage'],
      'isFavourite': false,
      'price': 'RM8',
    },
    {
      'id': 23,
      'name': 'Italian Tiramisu',
      'ingredients': [
        'Espresso, brewed and cooled',
        'Ladyfinger cookies',
        'Mascarpone cheese',
        'Heavy cream',
        'Sugar',
        'Cocoa powder',
      ],
      'instructions': [
        'In a bowl, whip heavy cream until stiff peaks form.',
        'In another bowl, mix mascarpone cheese and sugar until smooth.',
        'Gently fold the whipped cream into the mascarpone mixture.',
        'Dip ladyfinger cookies into brewed espresso and layer them in a serving dish.',
        'Spread a layer of the mascarpone mixture over the cookies.',
        'Repeat layers and finish with a dusting of cocoa powder.',
        'Chill in the refrigerator for a few hours before serving.',
        'Indulge in the decadence of this classic Italian Tiramisu!',
      ],
      'prepTimeMinutes': 30,
      'cookTimeMinutes': 0,
      'servings': 6,
      'difficulty': 'Medium',
      'cuisine': 'Italian',
      'caloriesPerServing': 350,
      'tags': ['Tiramisu', 'Italian'],
      'userId': 130,
      'image': 'https://cdn.dummyjson.com/recipe-images/23.webp',
      'rating': 4.6,
      'reviewCount': 0,
      'mealType': ['Dessert'],
      'isFavourite': true,
      'price': 'RM20',
    },
    {
      'id': 24,
      'name': 'Turkish Kebabs',
      'ingredients': [
        'Ground lamb or beef',
        'Onions, grated',
        'Garlic, minced',
        'Parsley, finely chopped',
        'Cumin',
        'Coriander',
        'Red pepper flakes',
        'Salt and pepper to taste',
        'Flatbread for serving',
        'Tahini sauce',
      ],
      'instructions': [
        'In a bowl, mix ground meat, grated onions, minced garlic, chopped parsley, and spices.',
        'Form the mixture into kebab shapes and grill until fully cooked.',
        'Serve the kebabs on flatbread with a drizzle of tahini sauce.',
        'Enjoy these flavorful Turkish Kebabs with your favorite sides.',
      ],
      'prepTimeMinutes': 25,
      'cookTimeMinutes': 15,
      'servings': 4,
      'difficulty': 'Easy',
      'cuisine': 'Turkish',
      'caloriesPerServing': 280,
      'tags': ['Kebabs', 'Turkish', 'Grilling'],
      'userId': 26,
      'image': 'https://cdn.dummyjson.com/recipe-images/24.webp',
      'rating': 4.6,
      'reviewCount': 78,
      'mealType': ['Dinner'],
      'isFavourite': false,
      'price': 'RM22',
    },
    {
      'id': 25,
      'name': 'Blueberry Banana Smoothie',
      'ingredients': [
        'Blueberries, fresh or frozen',
        'Banana, peeled and sliced',
        'Greek yogurt',
        'Almond milk',
        'Honey',
        'Chia seeds (optional)',
      ],
      'instructions': [
        'In a blender, combine blueberries, banana, Greek yogurt, almond milk, and honey.',
        'Blend until smooth and creamy.',
        'Add chia seeds for extra nutrition and blend briefly.',
        'Pour into a glass and enjoy this nutritious Blueberry Banana Smoothie!',
      ],
      'prepTimeMinutes': 10,
      'cookTimeMinutes': 0,
      'servings': 1,
      'difficulty': 'Easy',
      'cuisine': 'Smoothie',
      'caloriesPerServing': 220,
      'tags': ['Smoothie', 'Blueberry', 'Banana'],
      'userId': 16,
      'image': 'https://cdn.dummyjson.com/recipe-images/25.webp',
      'rating': 4.8,
      'reviewCount': 30,
      'mealType': ['Breakfast', 'Beverage'],
      'isFavourite': false,
      'price': 'RM12',
    },
    {
      'id': 26,
      'name': 'Mexican Street Corn (Elote)',
      'ingredients': [
        'Corn on the cob',
        'Mayonnaise',
        'Cotija cheese, crumbled',
        'Chili powder',
        'Lime wedges',
      ],
      'instructions': [
        'Grill or roast corn on the cob until kernels are charred.',
        'Brush each cob with mayonnaise, then sprinkle with crumbled Cotija cheese and chili powder.',
        'Serve with lime wedges for squeezing over the top.',
        'Enjoy this delicious and flavorful Mexican Street Corn!',
      ],
      'prepTimeMinutes': 15,
      'cookTimeMinutes': 15,
      'servings': 4,
      'difficulty': 'Easy',
      'cuisine': 'Mexican',
      'caloriesPerServing': 180,
      'tags': ['Elote', 'Mexican', 'Street food'],
      'userId': 93,
      'image': 'https://cdn.dummyjson.com/recipe-images/26.webp',
      'rating': 4.6,
      'reviewCount': 2,
      'mealType': ['Snack', 'Side Dish'],
      'isFavourite': false,
      'price': 'RM10',
    },
    {
      'id': 27,
      'name': 'Russian Borscht',
      'ingredients': [
        'Beets, peeled and shredded',
        'Cabbage, shredded',
        'Potatoes, diced',
        'Onions, finely chopped',
        'Carrots, grated',
        'Tomato paste',
        'Beef or vegetable broth',
        'Garlic, minced',
        'Bay leaves',
        'Sour cream for serving',
      ],
      'instructions': [
        'In a pot, sauté chopped onions and garlic until softened.',
        'Add shredded beets, cabbage, diced potatoes, grated carrots, and tomato paste.',
        'Pour in broth and add bay leaves. Simmer until vegetables are tender.',
        'Serve hot with a dollop of sour cream on top.',
        'Enjoy the hearty and comforting flavors of Russian Borscht!',
      ],
      'prepTimeMinutes': 30,
      'cookTimeMinutes': 40,
      'servings': 6,
      'difficulty': 'Medium',
      'cuisine': 'Russian',
      'caloriesPerServing': 220,
      'tags': ['Borscht', 'Russian', 'Soup'],
      'userId': 1,
      'image': 'https://cdn.dummyjson.com/recipe-images/27.webp',
      'rating': 4.3,
      'reviewCount': 39,
      'mealType': ['Dinner'],
      'isFavourite': false,
      'price': 'RM18',
    },
    {
      'id': 28,
      'name': 'South Indian Masala Dosa',
      'ingredients': [
        'Dosa batter (fermented rice and urad dal batter)',
        'Potatoes, boiled and mashed',
        'Onions, finely chopped',
        'Mustard seeds',
        'Cumin seeds',
        'Curry leaves',
        'Turmeric powder',
        'Green chilies, chopped',
        'Ghee',
        'Coconut chutney for serving',
      ],
      'instructions': [
        'In a pan, heat ghee and add many seeds, cumin seeds, and curry leaves.',
        'Add chopped onions, green chilies, and turmeric powder. Sauté until onions are golden brown.',
        'Mix in boiled and mashed potatoes. Cook until well combined and seasoned.',
        'Spread dosa batter on a hot griddle to make thin pancakes.',
        'Place a spoonful of the potato mixture in the center, fold, and serve hot.',
        'Pair with coconut chutney for a delicious South Indian meal.',
      ],
      'prepTimeMinutes': 40,
      'cookTimeMinutes': 20,
      'servings': 4,
      'difficulty': 'Medium',
      'cuisine': 'Indian',
      'caloriesPerServing': 320,
      'tags': ['Dosa', 'Indian', 'Asian'],
      'userId': 138,
      'image': 'https://cdn.dummyjson.com/recipe-images/28.webp',
      'rating': 4.4,
      'reviewCount': 96,
      'mealType': ['Breakfast'],
      'isFavourite': true,
      'price': 'RM12',
    },
    {
      'id': 29,
      'name': 'Lebanese Falafel Wrap',
      'ingredients': [
        'Falafel balls',
        'Whole wheat or regular wraps',
        'Tomatoes, diced',
        'Cucumbers, sliced',
        'Red onions, thinly sliced',
        'Lettuce, shredded',
        'Tahini sauce',
        'Fresh parsley, chopped',
      ],
      'instructions': [
        'Warm falafel balls according to package instructions.',
        'Place a generous serving of falafel in the center of each wrap.',
        'Top with diced tomatoes, sliced cucumbers, red onions, shredded lettuce, and fresh parsley.',
        'Drizzle with tahini sauce and wrap tightly.',
        'Enjoy this Lebanese Falafel Wrap filled with fresh and flavorful ingredients!',
      ],
      'prepTimeMinutes': 15,
      'cookTimeMinutes': 10,
      'servings': 2,
      'difficulty': 'Easy',
      'cuisine': 'Lebanese',
      'caloriesPerServing': 400,
      'tags': ['Falafel', 'Lebanese', 'Wrap'],
      'userId': 110,
      'image': 'https://cdn.dummyjson.com/recipe-images/29.webp',
      'rating': 4.7,
      'reviewCount': 84,
      'mealType': ['Lunch'],
      'isFavourite': false,
      'price': 'RM15',
    },
    {
      'id': 30,
      'name': 'Brazilian Caipirinha',
      'ingredients': [
        'Cachaça (Brazilian sugarcane spirit)',
        'Lime, cut into wedges',
        'Granulated sugar',
        'Ice cubes',
      ],
      'instructions': [
        'In a glass, muddle lime wedges with granulated sugar to release the juice.',
        'Fill the glass with ice cubes.',
        'Pour cachaça over the ice and stir well.',
        'Sip and enjoy the refreshing taste of the Brazilian Caipirinha!',
        'Adjust sugar and lime to suit your taste preferences.',
      ],
      'prepTimeMinutes': 5,
      'cookTimeMinutes': 0,
      'servings': 1,
      'difficulty': 'Easy',
      'cuisine': 'Brazilian',
      'caloriesPerServing': 150,
      'tags': ['Caipirinha', 'Brazilian', 'Cocktail'],
      'userId': 134,
      'image': 'https://cdn.dummyjson.com/recipe-images/30.webp',
      'rating': 4.4,
      'reviewCount': 55,
      'mealType': ['Beverage'],
      'isFavourite': false,
      'price': 'RM18',
    },
  ];

  late bool _isEditMode;

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.orange, size: 20.0),
          const SizedBox(width: 8.0),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF003D33),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16.0, color: Colors.grey),
        const SizedBox(width: 4.0),
        Text(value, style: const TextStyle(fontSize: 12.0, color: Colors.grey)),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan',
            style: TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003D33),
            ),
          ),
          const SizedBox(height: 4.0),
          const Text(
            'Manage meals and recipes',
            style: TextStyle(fontSize: 14.0, color: Colors.grey),
          ),
          const SizedBox(height: 24.0),
          Container(
            height: 50.0,
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      AppState.of(context, listen: false).setTabIndex(1);
                      context.go('/main-page');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Meal Plan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4.0,
                          offset: const Offset(0.0, 2.0),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'My Recipes',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF003D33),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.initialEditMode;
  }

  @override
  void dispose() {
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _durationController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      minBudget = double.tryParse(_minBudgetController.text);
      maxBudget = double.tryParse(_maxBudgetController.text);
      maxDuration = int.tryParse(_durationController.text);
      maxServings = int.tryParse(_servingsController.text);
      maxCalories = int.tryParse(_caloriesController.text);
      showFilters = false;
    });
  }

  void _clearFilters() {
    setState(() {
      _minBudgetController.clear();
      _maxBudgetController.clear();
      _durationController.clear();
      _servingsController.clear();
      _caloriesController.clear();
      minBudget = null;
      maxBudget = null;
      maxDuration = null;
      maxServings = null;
      maxCalories = null;
      selectedDifficulty = null;
    });
  }

  Widget _buildFilterField(
      String label,
      TextEditingController controller,
      String hint,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF003D33),
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          height: 48.0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    final isSelected = selectedDifficulty == difficulty;
    return GestureDetector(
      onTap: () =>
          setState(() => selectedDifficulty = isSelected ? null : difficulty),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1BAB52)
              : const Color(0xFFE8F5E9).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFEEEEEE),
          ),
        ),
        child: Text(
          difficulty,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF003D33),
            fontWeight: FontWeight.w600,
            fontSize: 14.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50.0,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 12.0),
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: const InputDecoration(
                      hintText: 'Search saved recipes...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1BAB52),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 20.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        GestureDetector(
          onTap: () => setState(() => showFilters = !showFilters),
          child: Container(
            height: 50.0,
            width: 50.0,
            decoration: BoxDecoration(
              color: showFilters
                  ? const Color(0xFF1BAB52)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(
              Icons.tune,
              color: showFilters ? Colors.white : const Color(0xFF003D33),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final filteredRecipes = _recipes.where((recipe) {
      if (searchQuery.isNotEmpty &&
          !recipe['name'].toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      final price =
          double.tryParse(
            recipe['price'].toString().replaceAll(RegExp('[^0-9.]'), ''),
          ) ??
              0.0;
      if (minBudget != null && price < minBudget!) {
        return false;
      }
      if (maxBudget != null && price > maxBudget!) {
        return false;
      }
      final duration =
          int.tryParse(
            recipe['prepTime'].toString().replaceAll(RegExp('[^0-9]'), ''),
          ) ??
              0;
      if (maxDuration != null && duration > maxDuration!) {
        return false;
      }
      if (maxServings != null && recipe['servings'] > maxServings!) {
        return false;
      }
      if (maxCalories != null && recipe['calories'] > maxCalories!) {
        return false;
      }
      if (selectedDifficulty != null &&
          recipe['difficulty'] != selectedDifficulty) {
        return false;
      }
      return true;
    }).toList();
    final favorites = filteredRecipes
        .where((r) => r['isFavourite'] == true)
        .toList();
    final allRecipes = filteredRecipes
        .where((r) => r['isFavourite'] == false)
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'My Recipes',
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003D33),
                              ),
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              'View Saved Recipes',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        _buildEditToggle(),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                    _buildToggle(),
                    const SizedBox(height: 24.0),
                    _buildSearchBar(),
                    const SizedBox(height: 24.0),
                    if (showFilters) _buildFilterForm(),
                    _buildAddButton(),
                    const SizedBox(height: 24.0),
                    if (favorites.isNotEmpty) ...[
                      _buildSectionHeader('Favourites', icon: Icons.star),
                      const SizedBox(height: 16.0),
                      ...favorites.map((r) => _buildRecipeCard(r)),
                      const SizedBox(height: 24.0),
                    ],
                    if (allRecipes.isNotEmpty) ...[
                      _buildSectionHeader('All Recipes (${allRecipes.length})'),
                      const SizedBox(height: 16.0),
                      ...allRecipes.map((r) => _buildRecipeCard(r)),
                      const SizedBox(height: 24.0),
                    ],
                    if (filteredRecipes.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: Text(
                            'No recipes match your filters',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10.0,
              offset: const Offset(0.0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1BAB52),
          unselectedItemColor: Colors.grey,
          currentIndex: 1,
          onTap: (index) {
            appState.setTabIndex(index);
            context.go('/main-page');
          },
          selectedLabelStyle: const TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12.0),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              label: 'Plan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              label: 'List',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Pantry',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFFF7043),
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: const Icon(
          Icons.qr_code_scanner,
          color: Colors.white,
          size: 28.0,
        ),
      ),
    );
  }

  Widget _buildFilterForm() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 24.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8.0,
            offset: const Offset(0.0, 4.0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterField(
                  'Min Budget (RM)',
                  _minBudgetController,
                  '0',
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: _buildFilterField(
                  'Max Budget (RM)',
                  _maxBudgetController,
                  '100',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: _buildFilterField(
                  'Max Duration (min)',
                  _durationController,
                  '60',
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: _buildFilterField(
                  'Max Servings',
                  _servingsController,
                  '10',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _buildFilterField('Max Calories', _caloriesController, '1000'),
          const SizedBox(height: 16.0),
          const Text(
            'Difficulty',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF003D33),
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              _buildDifficultyChip('Easy'),
              const SizedBox(width: 12.0),
              _buildDifficultyChip('Medium'),
              const SizedBox(width: 12.0),
              _buildDifficultyChip('Hard'),
            ],
          ),
          const SizedBox(height: 24.0),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    side: const BorderSide(color: Color(0xFFEEEEEE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'Clear Filters',
                    style: TextStyle(
                      color: Color(0xFF1BAB52),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1BAB52),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0.0,
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddRecipeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.0)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Add New Recipe',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D33),
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      'Choose how to add your recipe',
                      style: TextStyle(fontSize: 14.0, color: Colors.grey),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F8E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF003D33),
                      size: 20.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32.0),
            _buildAddOption(
              icon: Icons.edit_outlined,
              title: 'Manual Entry',
              subtitle: 'Add recipe details manually',
              iconBgColor: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF1BAB52),
              onTap: () {
                Navigator.pop(context);
                context.push('/recipe-edit', extra: <String, dynamic>{});
              },
            ),
            const SizedBox(height: 16.0),
            _buildAddOption(
              icon: Icons.camera_alt_outlined,
              title: 'Scan Meal or Ingredients',
              subtitle:
              'Get recommended recipe by scanning meal or ingredients',
              iconBgColor: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF1BAB52),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16.0),
            _buildAddOption(
              icon: Icons.description_outlined,
              title: 'Scan Written Recipe',
              subtitle: 'Extract recipe from text or handwritten notes',
              iconBgColor: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFFFB74D),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required void Function() onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 56.0,
                  height: 56.0,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Icon(icon, color: iconColor, size: 28.0),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003D33),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget _buildAddButton() {
    return Container(
      width: double.infinity,
      height: 54.0,
      decoration: BoxDecoration(
        color: const Color(0xFF1BAB52),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAddRecipeSheet,
          borderRadius: BorderRadius.circular(12.0),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add, color: Colors.white),
              SizedBox(width: 8.0),
              Text(
                'Add New Recipe',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isEditMode = !_isEditMode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: _isEditMode
              ? const Color(0xFF1BAB52)
              : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isEditMode ? Icons.check_circle_outline : Icons.edit_outlined,
              size: 18.0,
              color: _isEditMode ? Colors.white : const Color(0xFF1BAB52),
            ),
            const SizedBox(width: 8.0),
            Text(
              _isEditMode ? 'Done' : 'Edit',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _isEditMode ? Colors.white : const Color(0xFF1BAB52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final isFavourite = recipe['isFavourite'] == true;
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'recipe-view',
          extra: Map<String, dynamic>.from(recipe),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8.0,
              offset: const Offset(0.0, 4.0),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                if (isFavourite)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.star, color: Colors.orange, size: 20.0),
                  ),
                Expanded(
                  child: Text(
                    recipe['name'] ?? 'Recipe',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33),
                    ),
                  ),
                ),
                if (_isEditMode)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        _deleteRecipe(recipe);
                      } else if (value == 'favourite') {
                        _toggleFavourite(recipe);
                      } else if (value == 'plan') {
                        _addToPlan(recipe);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: const [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20.0,
                            ),
                            SizedBox(width: 8.0),
                            Text(
                              'Delete Recipe',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'favourite',
                        child: Row(
                          children: [
                            Icon(
                              isFavourite ? Icons.star : Icons.star_border,
                              color: Colors.orange,
                              size: 20.0,
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              isFavourite
                                  ? 'Remove from Favourites'
                                  : 'Add to Favourites',
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'plan',
                        child: Row(
                          children: const [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: Color(0xFF1BAB52),
                              size: 20.0,
                            ),
                            SizedBox(width: 8.0),
                            Text('Add to Plan'),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    recipe['difficulty'] ?? 'Easy',
                    style: const TextStyle(
                      color: Color(0xFF1BAB52),
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  recipe['mealType'] is List
                      ? (recipe['mealType'] as List).join(', ')
                      : recipe['mealType'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  Icons.access_time,
                  recipe['prepTime'] ??
                      '${(recipe['prepTimeMinutes'] ?? 0) + (recipe['cookTimeMinutes'] ?? 0)}m',
                ),
                _buildInfoItem(
                  Icons.attach_money,
                  recipe['price'] ?? 'RM${recipe['budget'] ?? 15}',
                ),
                _buildInfoItem(
                  Icons.people_outline,
                  '${recipe['servings'] ?? 4}',
                ),
                _buildInfoItem(
                  Icons.local_fire_department_outlined,
                  '${recipe['calories'] ?? recipe['caloriesPerServing'] ?? 450}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteRecipe(Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text('Are you sure you want to delete "${recipe['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _recipes.removeWhere((r) => r['id'] == recipe['id']);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleFavourite(Map<String, dynamic> recipe) {
    setState(() {
      final index = _recipes.indexWhere((r) => r['id'] == recipe['id']);
      if (index != -1) {
        _recipes[index]['isFavourite'] =
        !(_recipes[index]['isFavourite'] ?? false);
      }
    });
  }

  Future<void> _addToPlan(Map<String, dynamic> recipe) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1BAB52),
            onPrimary: Colors.white,
            onSurface: Color(0xFF003D33),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${recipe['name']}" added to plan for ${picked.day}/${picked.month}/${picked.year}',
          ),
          backgroundColor: const Color(0xFF1BAB52),
        ),
      );
    }
  }

  Widget _buildToggle() {
    return Container(
      height: 44.0,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isSavedRecipesSelected) {
                  setState(() => isSavedRecipesSelected = true);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSavedRecipesSelected
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: Alignment.center,
                child: Text(
                  'My Saved Recipes',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSavedRecipesSelected
                        ? const Color(0xFF003D33)
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                context.pushNamed('search-recipes');
              },
              child: Container(
                decoration: BoxDecoration(
                  color: !isSavedRecipesSelected
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Search Recipes',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: !isSavedRecipesSelected
                        ? const Color(0xFF003D33)
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
