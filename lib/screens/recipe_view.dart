import 'package:flutter/material.dart';
import '../globals/app_state.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../services/recipe_service.dart';
import '../services/grocery_service.dart';

class RecipeView extends StatefulWidget {
  const RecipeView({required this.recipe, super.key});

  final Map<String, dynamic> recipe;

  @override
  State<RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends State<RecipeView> {
  late Map<String, dynamic> _currentRecipe;
  bool _isLoading = false;
  bool _isAddingToList = false;

  @override
  void initState() {
    super.initState();
    _currentRecipe = RecipeService.normalize(
      Map<String, dynamic>.from(widget.recipe),
    );

    final id = _currentRecipe['id'];
    final isFromSearch = widget.recipe['isFromSearch'] == true;
    // ✅ Recipes from bulk search already have full data — skip extra API call
    final isFullyLoaded = widget.recipe['isFullyLoaded'] == true;

    if (isFromSearch && !isFullyLoaded && id != null && id is String && !id.contains('-')) {
      // Only fetch if the recipe came from basic search (not from bulk fetch)
      _fetchSpoonacularDetails(id);
    } else if (id != null && id is String && id.contains('-')) {
      // Supabase UUID → refresh saved recipe
      _refreshFromSupabase(id);
    }
  }

  // ── DATA FETCHING ─────────────────────────────────────────────────────────

  /// Fetches full recipe details from Spoonacular (steps, tools, calories).
  Future<void> _fetchSpoonacularDetails(String spoonacularId) async {
    setState(() => _isLoading = true);
    try {
      final full = await RecipeService.fetchSpoonacularRecipe(spoonacularId);
      if (full != null && mounted) {
        setState(() => _currentRecipe = full);
      }
    } catch (_) {
      // Keep showing basic data on error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Refreshes a user's saved recipe from Supabase.
  Future<void> _refreshFromSupabase(String id) async {
    setState(() => _isLoading = true);
    try {
      final fresh = await RecipeService.getRecipeById(id);
      if (fresh != null && mounted) {
        setState(() => _currentRecipe = fresh);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── DISPLAY HELPERS ───────────────────────────────────────────────────────

  String get _budgetDisplay {
    final b = (_currentRecipe['budget'] ?? _currentRecipe['price'] ?? '0')
        .toString()
        .replaceAll('RM', '')
        .trim();
    if (b.isEmpty || b == '0' || b == '0.0') return 'N/A';
    return 'RM$b';
  }

  String get _caloriesDisplay {
    final c = (_currentRecipe['caloriesPerServing'] ??
        _currentRecipe['calories'] ??
        0) as int;
    return c == 0 ? 'N/A' : '$c kcal';
  }

  String get _timeDisplay {
    final cook = (_currentRecipe['cookTimeMinutes'] as int?) ?? 0;
    final prep = (_currentRecipe['prepTimeMinutes'] as int?) ?? 0;
    final total = cook + prep;
    return total > 0 ? '${total}m' : '${cook}m';
  }

  // ── GROCERY LIST HELPERS ──────────────────────────────────────────────────

  /// Infers a grocery category from an ingredient name using keyword matching.
  String _inferCategory(String name) {
    final n = name.toLowerCase();
    if (RegExp(r'cheese|milk|butter|cream|egg|yogurt|cheddar|mozzarella|dairy').hasMatch(n)) {
      return 'Dairy & Eggs';
    }
    if (RegExp(r'chicken|beef|pork|lamb|turkey|duck|bacon|sausage|ham|steak|mince|meat|veal').hasMatch(n)) {
      return 'Meat & Poultry';
    }
    if (RegExp(r'fish|salmon|tuna|shrimp|prawn|crab|lobster|cod|tilapia|seafood|squid').hasMatch(n)) {
      return 'Seafood';
    }
    if (RegExp(r'corn|pepper|tomato|onion|garlic|carrot|spinach|lettuce|avocado|potato|capsicum|bean|zucchini|broccoli|mushroom|celery|cucumber|kale|cabbage|pea|leek|chilli|chili').hasMatch(n)) {
      return 'Vegetables & Produce';
    }
    if (RegExp(r'apple|banana|lemon|lime|orange|mango|strawberry|berry|grape|peach|pear|fruit').hasMatch(n)) {
      return 'Fruits';
    }
    if (RegExp(r'quinoa|rice|flour|pasta|bread|oat|noodle|tortilla|wheat|grain|cereal|barley|couscous').hasMatch(n)) {
      return 'Grains & Pasta';
    }
    if (RegExp(r'sauce|enchilada|salsa|verde|broth|stock|paste|canned|soup|dressing').hasMatch(n)) {
      return 'Canned & Jarred';
    }
    if (RegExp(r'salt|cumin|cilantro|basil|oregano|paprika|thyme|rosemary|coriander|spice|herb|seasoning|cardamom|turmeric|cinnamon|nutmeg|pepper').hasMatch(n)) {
      return 'Herbs & Spices';
    }
    if (RegExp(r'oil|olive oil|vinegar|soy sauce|mustard|mayo|mayonnaise|ketchup|syrup|honey').hasMatch(n)) {
      return 'Oils & Condiments';
    }
    return 'Other';
  }

  /// Adds all recipe ingredients to the grocery list via GroceryService.
  Future<void> _addIngredientsToGroceryList() async {
    final ingredients = _currentRecipe['ingredients'] as List<dynamic>? ?? [];
    if (ingredients.isEmpty) return;

    setState(() => _isAddingToList = true);

    // Split total recipe budget (already in MYR) evenly across ingredients.
    final budgetStr = (_currentRecipe['budget'] ?? _currentRecipe['price'] ?? '0')
        .toString()
        .replaceAll('RM', '')
        .trim();
    final totalBudget = double.tryParse(budgetStr) ?? 0.0;
    final pricePerIngredient = (totalBudget > 0 && ingredients.isNotEmpty)
        ? totalBudget / ingredients.length
        : 0.0;

    final recipeName = _currentRecipe['name'] as String? ?? 'Unknown Recipe';

    int added = 0;
    int skipped = 0;

    for (final ing in ingredients) {
      if (ing is! Map) continue;
      final name = ing['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;

      final amountStr = ing['amount']?.toString().trim() ?? '';
      final unit = ing['unit']?.toString().trim() ?? '';
      final quantityAmount = double.tryParse(amountStr);
      final quantity = [amountStr, unit].where((s) => s.isNotEmpty).join(' ');
      final category = _inferCategory(name);

      try {
        await GroceryService.addItem(
          name: name,
          quantity: quantity,
          quantityAmount: quantityAmount,
          unit: unit.isNotEmpty ? unit : null,
          price: double.parse(pricePerIngredient.toStringAsFixed(2)),
          category: category,
          recipe: recipeName, // ← links item to the "By Recipe" tab
        );
        added++;
      } catch (_) {
        skipped++;
      }
    }

    if (!mounted) return;
    setState(() => _isAddingToList = false);

    final msg = skipped == 0
        ? '🛒 $added ingredient${added == 1 ? '' : 's'} added to your grocery list!'
        : '🛒 $added added, $skipped failed. Check your connection.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: skipped == 0 ? const Color(0xFF2E7D32) : Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── WIDGET HELPERS ────────────────────────────────────────────────────────

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
            fontSize: 13.0,
          ),
          textAlign: TextAlign.center,
        ),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 11.0)),
      ],
    );
  }

  Widget _buildToolChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.kitchen_outlined,
              size: 14.0, color: Color(0xFF1BAB52)),
          const SizedBox(width: 6.0),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF003D33),
              fontWeight: FontWeight.w500,
              fontSize: 13.0,
            ),
          ),
        ],
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
          const SizedBox(width: 14.0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                instruction,
                style: const TextStyle(
                  color: Color(0xFF003D33),
                  fontSize: 14.0,
                  height: 1.5,
                ),
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
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
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
                fontSize: 14.0,
              ),
            ),
          ),
          Text(
            measurement,
            style: const TextStyle(color: Colors.grey, fontSize: 13.0),
          ),
        ],
      ),
    );
  }

  // ── LOADING SHIMMER SECTION ───────────────────────────────────────────────

  Widget _buildLoadingSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003D33))),
        const SizedBox(height: 12.0),
        Container(
          height: 16.0,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          height: 16.0,
          width: 200.0,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ],
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final bool isFromSearch = widget.recipe['isFromSearch'] ?? false;

    final List<String> tools =
    List<String>.from(_currentRecipe['tools'] ?? []);
    final List<dynamic> ingredients =
        _currentRecipe['ingredients'] as List<dynamic>? ?? [];
    final List<dynamic> instructions =
        _currentRecipe['instructions'] as List<dynamic>? ?? [];
    final int servings = (_currentRecipe['servings'] as int?) ?? 4;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentRecipe['name'] ?? 'Recipe',
                      style: const TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D33),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  // Loading spinner while fetching Spoonacular details
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF1BAB52)),
                      ),
                    ),
                  if (isFromSearch)
                  // Save button (search results)
                    GestureDetector(
                      onTap: () async {
                        try {
                          await RecipeService.saveSearchedRecipe(
                              _currentRecipe);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                Text('✅ Recipe saved to My Recipes!'),
                                backgroundColor: Color(0xFF1BAB52),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Failed to save: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1BAB52),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bookmark_add_outlined,
                                size: 18.0, color: Colors.white),
                            SizedBox(width: 6.0),
                            Text('Save',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 14.0)),
                          ],
                        ),
                      ),
                    )
                  else
                  // Edit button (saved recipes)
                    GestureDetector(
                      onTap: () async {
                        final result = await context.pushNamed(
                          'recipe-edit',
                          extra: _currentRecipe,
                        );
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            _currentRecipe = RecipeService.normalize(
                                Map<String, dynamic>.from(result));
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 18.0, color: Color(0xFF003D33)),
                            SizedBox(width: 6.0),
                            Text('Edit',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF003D33),
                                    fontSize: 14.0)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 10.0),
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEEEEE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 18.0, color: Color(0xFF003D33)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Recipe image ──────────────────────────────────────
                    if (_currentRecipe['image'] != null &&
                        (_currentRecipe['image'] as String).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24.0),
                          child: (_currentRecipe['image'] as String)
                              .startsWith('http')
                              ? Image.network(
                            _currentRecipe['image'],
                            height: 200.0,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildPlaceholderImage(),
                          )
                              : Image.file(
                            File(_currentRecipe['image']),
                            height: 200.0,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildPlaceholderImage(),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: _buildPlaceholderImage(),
                      ),

                    // ── Info card ─────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Column(
                        children: [
                          // Difficulty + tools count
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 6.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  _currentRecipe['difficulty'] ?? 'Medium',
                                  style: const TextStyle(
                                    color: Color(0xFF1BAB52),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.0,
                                  ),
                                ),
                              ),
                              Text(
                                '${tools.length} tool${tools.length == 1 ? '' : 's'} needed',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13.0),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),
                          // Stats row
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                            children: [
                              _buildInfoItem(
                                Icons.access_time_outlined,
                                _isLoading ? '...' : _timeDisplay,
                                'Cook Time',
                                const Color(0xFFFFF3E0),
                                const Color(0xFFFF9800),
                              ),
                              _buildInfoItem(
                                Icons.people_outline,
                                '$servings',
                                'Servings',
                                const Color(0xFFE3F2FD),
                                const Color(0xFF2196F3),
                              ),
                              _buildInfoItem(
                                Icons.attach_money_outlined,
                                _isLoading ? '...' : _budgetDisplay,
                                'Budget',
                                const Color(0xFFE8F5E9),
                                const Color(0xFF1BAB52),
                              ),
                              _buildInfoItem(
                                Icons.local_fire_department_outlined,
                                _isLoading ? '...' : _caloriesDisplay,
                                'Calories',
                                const Color(0xFFFFEBEE),
                                const Color(0xFFEF5350),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28.0),

                    // ── Tools Required ────────────────────────────────────
                    const Row(
                      children: [
                        Icon(Icons.handyman_outlined,
                            color: Color(0xFF1BAB52), size: 20.0),
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
                    const SizedBox(height: 14.0),
                    if (_isLoading)
                      _buildLoadingSection('')
                    else if (tools.isEmpty)
                      const Text(
                        'No tools listed',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14.0,
                            fontStyle: FontStyle.italic),
                      )
                    else
                      Wrap(
                        spacing: 10.0,
                        runSpacing: 10.0,
                        children:
                        tools.map((t) => _buildToolChip(t)).toList(),
                      ),
                    const SizedBox(height: 28.0),

                    // ── Ingredients ───────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color:
                        const Color(0xFFF1F8E9).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Ingredients',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003D33),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$servings serving${servings == 1 ? '' : 's'}',
                                style: const TextStyle(
                                    color: Color(0xFF1BAB52),
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          if (ingredients.isEmpty && _isLoading)
                            _buildLoadingSection('')
                          else if (ingredients.isEmpty)
                            const Text('No ingredients listed.',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic))
                          else
                            ...ingredients.map((ing) {
                              if (ing is Map) {
                                final name = ing['name']?.toString() ?? '';
                                final amount =
                                    ing['amount']?.toString() ?? '';
                                final unit = ing['unit']?.toString() ?? '';
                                return _buildIngredientItem(
                                    name, '$amount $unit'.trim());
                              }
                              return _buildIngredientItem(
                                  ing.toString(), '');
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // ── Add to Grocery List button ────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isAddingToList || ingredients.isEmpty)
                            ? null
                            : _addIngredientsToGroceryList,
                        icon: _isAddingToList
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.add_shopping_cart_outlined,
                            size: 20),
                        label: Text(
                          _isAddingToList
                              ? 'Adding to list…'
                              : 'Add Ingredients to Grocery List',
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1BAB52),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          const Color(0xFF1BAB52).withValues(alpha: 0.5),
                          disabledForegroundColor: Colors.white70,
                          padding:
                          const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // ── Cooking Steps ─────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color:
                        const Color(0xFFF1F8E9).withValues(alpha: 0.5),
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
                          if (_isLoading)
                            _buildLoadingSection('')
                          else if (instructions.isEmpty)
                            const Text(
                              'No steps available.\nTap "Edit" to add cooking steps.',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5),
                            )
                          else
                            ...instructions.asMap().entries.map(
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
                icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today), label: 'Plan'),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined), label: 'List'),
            BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined), label: 'Pantry'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}