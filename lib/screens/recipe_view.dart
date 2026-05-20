import 'package:flutter/material.dart';
import '../globals/app_state.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../services/recipe_service.dart'; // ✅ NEW

class RecipeView extends StatefulWidget {
  const RecipeView({required this.recipe, super.key});

  final Map<String, dynamic> recipe;

  @override
  State<RecipeView> createState() {
    return _RecipeViewState();
  }
}

class _RecipeViewState extends State<RecipeView> {
  late Map<String, dynamic> _currentRecipe;
  bool _isLoading = false; // ✅ NEW

  @override
  void initState() {
    super.initState();
    // ✅ NEW: Normalize field names so this view works whether the data
    // comes from Supabase (recipe_name, cooking_steps, etc.) or
    // from local hardcoded maps (name, instructions, etc.)
    _currentRecipe = RecipeService.normalize(
      Map<String, dynamic>.from(widget.recipe),
    );

    // ✅ NEW: If the recipe has a Supabase UUID id, fetch fresh data
    // This ensures the view always shows the latest saved version
    final id = _currentRecipe['id'];
    if (id != null && id is String && id.contains('-')) {
      _refreshFromSupabase(id);
    }
  }

  // ✅ NEW: Fetches the latest version of the recipe from Supabase
  Future<void> _refreshFromSupabase(String id) async {
    setState(() => _isLoading = true);
    try {
      final fresh = await RecipeService.getRecipeById(id);
      if (fresh != null && mounted) {
        setState(() => _currentRecipe = fresh);
      }
    } catch (_) {
      // Fall back to the passed-in data — no error shown to user
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInfoItem(
      IconData icon,
      String value,
      String label,
      Color bgColor,
      Color iconColor,
      ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Icon(icon, color: iconColor, size: 20.0),
        ),
        const SizedBox(height: 8.0),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF003D33),
            fontSize: 14.0,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12.0)),
      ],
    );
  }

  Widget _buildToolChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF003D33),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStepItem(int number, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.0,
            height: 28.0,
            decoration: const BoxDecoration(
              color: Color(0xFF1BAB52),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12.0,
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(
                color: Color(0xFF003D33),
                fontSize: 15.0,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200.0,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: const Icon(Icons.restaurant, color: Colors.grey, size: 48.0),
    );
  }

  Widget _buildIngredientItem(String name, String measurement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Color(0xFF003D33),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            measurement,
            style: const TextStyle(color: Colors.grey, fontSize: 14.0),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final bool isFromSearch = widget.recipe['isFromSearch'] ?? false;
    final int prepTime = _currentRecipe['prepTimeMinutes'] ?? 0;
    final int cookTime = _currentRecipe['cookTimeMinutes'] ?? 0;
    final int totalTime = prepTime + cookTime;

    // ✅ UPDATED: Reads budget from Supabase 'budget' field or legacy 'price' field
    String budget = '15';
    if (_currentRecipe['price'] != null) {
      budget = _currentRecipe['price'].toString().replaceAll('RM', '');
    } else if (_currentRecipe['budget'] != null) {
      budget = _currentRecipe['budget'].toString();
    }

    // ✅ UPDATED: Reads from 'tools' (normalized from Supabase 'tools_required')
    final List<String> tools = List<String>.from(
      _currentRecipe['tools'] ?? ['Pan', 'Knife', 'Spoon'],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentRecipe['name'] ?? 'Recipe',
                      style: const TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D33),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // ✅ Loading indicator while refreshing from Supabase
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1BAB52),
                        ),
                      ),
                    ),
                  if (isFromSearch)
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recipe added to Saved Recipes!'),
                            backgroundColor: Color(0xFF1BAB52),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1BAB52),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.bookmark_add_outlined,
                              size: 18.0,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8.0),
                            Text(
                              'Save',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () async {
                        // ✅ Pass the normalized recipe to RecipeEdit
                        final result = await context.pushNamed(
                          'recipe-edit',
                          extra: _currentRecipe,
                        );
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            // Normalize result in case RecipeEdit returns
                            // Supabase-style fields
                            _currentRecipe = RecipeService.normalize(
                              Map<String, dynamic>.from(result),
                            );
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 18.0,
                              color: Color(0xFF003D33),
                            ),
                            SizedBox(width: 8.0),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF003D33),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 12.0),
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
                        size: 20.0,
                        color: Color(0xFF003D33),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe image
                    if (_currentRecipe['image'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24.0),
                          child: _currentRecipe['image']
                              .toString()
                              .startsWith('http')
                              ? Image.network(
                            _currentRecipe['image'],
                            height: 200.0,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                _buildPlaceholderImage(),
                          )
                              : Image.file(
                            File(_currentRecipe['image']),
                            height: 200.0,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                _buildPlaceholderImage(),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: _buildPlaceholderImage(),
                      ),

                    // Info card
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 6.0,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  // ✅ Reads from normalized 'difficulty' field
                                  _currentRecipe['difficulty'] ?? 'Easy',
                                  style: const TextStyle(
                                    color: Color(0xFF1BAB52),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.restaurant_menu_outlined,
                                    size: 16.0,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    '${tools.length} tools',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildInfoItem(
                                Icons.access_time,
                                '${totalTime > 0 ? totalTime : _currentRecipe['prepTime'] ?? '35'}m',
                                'Time',
                                const Color(0xFFE8F5E9),
                                const Color(0xFF1BAB52),
                              ),
                              _buildInfoItem(
                                Icons.attach_money,
                                'RM$budget',
                                'Budget',
                                const Color(0xFFFFF3E0),
                                const Color(0xFFFF9800),
                              ),
                              _buildInfoItem(
                                Icons.people_outline,
                                '${_currentRecipe['servings'] ?? 4}',
                                'Servings',
                                const Color(0xFFE8F5E9),
                                const Color(0xFF1BAB52),
                              ),
                              _buildInfoItem(
                                Icons.local_fire_department_outlined,
                                // ✅ Reads from normalized 'caloriesPerServing'
                                '${_currentRecipe['caloriesPerServing'] ?? _currentRecipe['calories'] ?? 450}',
                                'Calories',
                                const Color(0xFFFFEBEE),
                                const Color(0xFFEF5350),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // Tools
                    const Row(
                      children: [
                        Icon(
                          Icons.handyman_outlined,
                          color: Color(0xFF1BAB52),
                          size: 20.0,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'Tools Required',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003D33),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    if (tools.isNotEmpty)
                      Wrap(
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children: tools
                            .map((tool) => _buildToolChip(tool))
                            .toList(),
                      )
                    else
                      const Text(
                        'No tools listed',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14.0,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 32.0),

                    // Ingredients
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ingredients',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003D33),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          // ✅ Reads from normalized 'ingredients' field
                          ...(_currentRecipe['ingredients']
                          as List<dynamic>? ??
                              [])
                              .map((ing) {
                            if (ing is Map) {
                              final String name =
                                  ing['name']?.toString() ?? '';
                              final String amount =
                                  ing['amount']?.toString() ?? '';
                              final String unit =
                                  ing['unit']?.toString() ?? '';
                              return _buildIngredientItem(
                                name,
                                '$amount $unit'.trim(),
                              );
                            }
                            return _buildIngredientItem(
                                ing.toString(), '');
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Cooking Steps
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cooking Steps',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003D33),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          // ✅ Reads from normalized 'instructions' field
                          // (mapped from Supabase 'cooking_steps')
                          ...(_currentRecipe['instructions']
                          as List<dynamic>? ??
                              [])
                              .asMap()
                              .entries
                              .map(
                                (entry) => _buildStepItem(
                              entry.key + 1,
                              entry.value.toString(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40.0),
                  ],
                ),
              ),
            ),
          ],
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
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
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