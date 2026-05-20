import 'package:flutter/material.dart';
import '../globals/app_state.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../services/recipe_service.dart';

class RecipeView extends StatefulWidget {
  const RecipeView({required this.recipe, super.key});

  final Map<String, dynamic> recipe;

  @override
  State<RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends State<RecipeView> {
  late Map<String, dynamic> _currentRecipe;
  bool _isLoading = false;

  // ✅ Tracks the displayed servings — changes update budget & calories
  int _displayServings = 4;

  @override
  void initState() {
    super.initState();
    _currentRecipe = RecipeService.normalize(
      Map<String, dynamic>.from(widget.recipe),
    );
    // Start with the recipe's original servings
    _displayServings = (_currentRecipe['servings'] as int?) ?? 4;

    // Refresh from Supabase if this is a saved recipe (has UUID id)
    final id = _currentRecipe['id'];
    if (id != null && id is String && id.contains('-')) {
      _refreshFromSupabase(id);
    }
  }

  Future<void> _refreshFromSupabase(String id) async {
    setState(() => _isLoading = true);
    try {
      final fresh = await RecipeService.getRecipeById(id);
      if (fresh != null && mounted) {
        setState(() {
          _currentRecipe = fresh;
          _displayServings = (fresh['servings'] as int?) ?? _displayServings;
        });
      }
    } catch (_) {
      // Fall back to passed-in data silently
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CALCULATED DISPLAY VALUES
  // ─────────────────────────────────────────────────────────────────────────

  /// Total budget for _displayServings.
  /// Spoonacular: uses budgetPerServing × _displayServings
  /// User recipe: uses stored total budget string
  String get _budgetDisplay {
    // Spoonacular recipe — has per-serving RM value
    final budgetPerServing =
    (_currentRecipe['budgetPerServing'] as num?)?.toDouble();
    if (budgetPerServing != null && budgetPerServing > 0) {
      final total = budgetPerServing * _displayServings;
      return 'RM${total.toStringAsFixed(2)}';
    }
    // User's own recipe or legacy data — stored as total string
    if (_currentRecipe['price'] != null) {
      final p = _currentRecipe['price'].toString().trim();
      return p.startsWith('RM') ? p : 'RM$p';
    }
    final b = _currentRecipe['budget']?.toString() ?? '0';
    if (b == '0' || b == '0.0' || b.isEmpty) return 'N/A';
    return 'RM$b';
  }

  /// Calories per serving (stays constant, label says "per serving").
  int get _caloriesPerServing =>
      (_currentRecipe['caloriesPerServing'] as int?) ??
          (_currentRecipe['calories'] as int?) ??
          0;

  /// Total calories for _displayServings.
  int get _totalCalories => _caloriesPerServing * _displayServings;

  // ─────────────────────────────────────────────────────────────────────────
  // WIDGET HELPERS
  // ─────────────────────────────────────────────────────────────────────────

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
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 12.0)),
      ],
    );
  }

  // ✅ Interactive servings adjuster — tapping +/- updates budget & calories
  Widget _buildServingsAdjuster() {
    return Column(
      children: [
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (_displayServings > 1) {
                    setState(() => _displayServings--);
                  }
                },
                child: const Icon(Icons.remove,
                    size: 16.0, color: Color(0xFF1BAB52)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  '$_displayServings',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003D33),
                    fontSize: 14.0,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _displayServings++),
                child: const Icon(Icons.add,
                    size: 16.0, color: Color(0xFF1BAB52)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8.0),
        const Text('Servings',
            style: TextStyle(color: Colors.grey, fontSize: 12.0)),
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
                height: 1.5,
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
          Text(measurement,
              style: const TextStyle(color: Colors.grey, fontSize: 14.0)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final bool isFromSearch = widget.recipe['isFromSearch'] ?? false;

    final int cookTime = _currentRecipe['cookTimeMinutes'] ?? 0;
    final int prepTime = _currentRecipe['prepTimeMinutes'] ?? 0;
    final int totalTime = prepTime + cookTime;

    // ✅ Tools from normalized 'tools' field
    final List<String> tools =
    List<String>.from(_currentRecipe['tools'] ?? []);

    // ✅ Instructions from normalized 'instructions' field
    final List<dynamic> instructions =
        _currentRecipe['instructions'] as List<dynamic>? ?? [];

    // ✅ Ingredients from normalized 'ingredients' field
    final List<dynamic> ingredients =
        _currentRecipe['ingredients'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24.0, vertical: 16.0),
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
                            horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1BAB52),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bookmark_add_outlined,
                                size: 18.0, color: Colors.white),
                            SizedBox(width: 8.0),
                            Text('Save',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    )
                  else
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
                            _displayServings =
                                (_currentRecipe['servings'] as int?) ??
                                    _displayServings;
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
                            SizedBox(width: 8.0),
                            Text('Edit',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF003D33))),
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
                      child: const Icon(Icons.close,
                          size: 20.0, color: Color(0xFF003D33)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable Body ────────────────────────────────────────────
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
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: _buildPlaceholderImage(),
                      ),

                    // ── Info Card ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.0),
                        border:
                        Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 6.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius:
                                  BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  _currentRecipe['difficulty'] ?? 'Easy',
                                  style: const TextStyle(
                                    color: Color(0xFF1BAB52),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                              // ✅ Shows actual tool count; graceful when empty
                              Row(
                                children: [
                                  const Icon(
                                      Icons.restaurant_menu_outlined,
                                      size: 16.0,
                                      color: Colors.grey),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    tools.isEmpty
                                        ? 'No tools listed'
                                        : '${tools.length} tool${tools.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12.0),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                            children: [
                              // Time
                              _buildInfoItem(
                                Icons.access_time,
                                '${totalTime > 0 ? totalTime : cookTime}m',
                                'Time',
                                const Color(0xFFE8F5E9),
                                const Color(0xFF1BAB52),
                              ),
                              // ✅ Budget: total for _displayServings, updates automatically
                              _buildInfoItem(
                                Icons.attach_money,
                                _budgetDisplay,
                                'Budget',
                                const Color(0xFFFFF3E0),
                                const Color(0xFFFF9800),
                              ),
                              // ✅ Servings: interactive adjuster (+/-)
                              _buildServingsAdjuster(),
                              // ✅ Total calories: caloriesPerServing × _displayServings
                              _buildInfoItem(
                                Icons.local_fire_department_outlined,
                                _caloriesPerServing > 0
                                    ? '$_totalCalories'
                                    : 'N/A',
                                'Calories',
                                const Color(0xFFFFEBEE),
                                const Color(0xFFEF5350),
                              ),
                            ],
                          ),
                          // ✅ Hint shown only if calories and budget can scale
                          if (_caloriesPerServing > 0 ||
                              (_currentRecipe['budgetPerServing'] as num?)
                                  ?.toDouble() !=
                                  null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                'Tap − + to adjust servings · budget & calories update automatically',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.0,
                                  color: Colors.grey.withValues(alpha: 0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // ── Tools Required ─────────────────────────────────────
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
                    const SizedBox(height: 16.0),
                    // ✅ Shows actual tool list (detected from instructions)
                    if (tools.isNotEmpty)
                      Wrap(
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children:
                        tools.map((t) => _buildToolChip(t)).toList(),
                      )
                    else
                      const Text(
                        'No tools listed',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14.0,
                            fontStyle: FontStyle.italic),
                      ),
                    const SizedBox(height: 32.0),

                    // ── Ingredients ────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9)
                            .withValues(alpha: 0.5),
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
                          ...ingredients.map((ing) {
                            if (ing is Map) {
                              final name = ing['name']?.toString() ?? '';
                              final amount = ing['amount']?.toString() ?? '';
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
                    const SizedBox(height: 24.0),

                    // ── Cooking Steps ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9)
                            .withValues(alpha: 0.5),
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
                          // ✅ Each step is a separate item, not one big paragraph
                          if (instructions.isEmpty)
                            const Text(
                              'No steps available.',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic),
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