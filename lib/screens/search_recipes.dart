import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../globals/app_state.dart';

class SearchRecipes extends StatefulWidget {
  const SearchRecipes({super.key});

  @override
  State<SearchRecipes> createState() {
    return _SearchRecipesState();
  }
}

class _SearchRecipesState extends State<SearchRecipes> {
  bool isSavedRecipesSelected = false;

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
      'image': 'https://cdn.dummyjson.com/recipe-images/1.webp',
      'mealType': ['Dinner'],
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
      'image': 'https://cdn.dummyjson.com/recipe-images/2.webp',
      'mealType': ['Lunch'],
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
      'image': 'https://cdn.dummyjson.com/recipe-images/3.webp',
      'mealType': ['Snack', 'Dessert'],
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
      'image': 'https://cdn.dummyjson.com/recipe-images/4.webp',
      'mealType': ['Lunch', 'Dinner'],
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
      'image': 'https://cdn.dummyjson.com/recipe-images/5.webp',
      'mealType': ['Dinner'],
      'price': 'RM20',
    },
  ];

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
                context.pop();
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
                if (isSavedRecipesSelected) {
                  setState(() => isSavedRecipesSelected = false);
                }
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

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'recipe-view',
          extra: {...Map<String, dynamic>.from(recipe), 'isFromSearch': true},
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

  Widget _buildInfoItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16.0, color: Colors.grey),
        const SizedBox(width: 4.0),
        Text(value, style: const TextStyle(fontSize: 12.0, color: Colors.grey)),
      ],
    );
  }

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
                      hintText: 'Search new recipes...',
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

  @override
  Widget build(BuildContext context) {
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
          (recipe['prepTimeMinutes'] ?? 0) + (recipe['cookTimeMinutes'] ?? 0);
      if (maxDuration != null && duration > maxDuration!) {
        return false;
      }
      if (maxServings != null && (recipe['servings'] ?? 0) > maxServings!) {
        return false;
      }
      if (maxCalories != null &&
          (recipe['caloriesPerServing'] ?? 0) > maxCalories!) {
        return false;
      }
      if (selectedDifficulty != null &&
          recipe['difficulty'] != selectedDifficulty) {
        return false;
      }
      return true;
    }).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
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
                                context.pop();
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Recipes',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D33),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    const Text(
                      'Search New Recipes',
                      style: TextStyle(fontSize: 14.0, color: Colors.grey),
                    ),
                    const SizedBox(height: 24.0),
                    _buildToggle(),
                    const SizedBox(height: 24.0),
                    _buildSearchBar(),
                    const SizedBox(height: 24.0),
                    if (showFilters) _buildFilterForm(),
                    _buildAddButton(),
                    const SizedBox(height: 24.0),
                    if (searchQuery.isEmpty)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(40.0),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE8F5E9,
                            ).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          child: const Column(
                            children: const [
                              Icon(
                                Icons.search,
                                size: 64.0,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16.0),
                              Text(
                                'Start searching to discover new recipes',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (filteredRecipes.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: Text(
                            'No recipes match your search',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                      )
                    else
                      ...filteredRecipes.map((r) => _buildRecipeCard(r)),
                    const SizedBox(height: 24.0),
                  ],
                ),
              ),
            ],
          ),
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
            AppState.of(context, listen: false).setTabIndex(index);
            context.go('/main-page');
          },
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
    );
  }
}
