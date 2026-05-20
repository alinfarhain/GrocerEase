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
  /// This is the KEY fix — complexSearch doesn't return these reliably.
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
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('❌ Failed to save: $e'),
                                  backgroundColor: Colors.red),
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

            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe image
                    if (_currentRecipe['image'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
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
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                              // ✅ Tools count — shows correctly after fetch
                              Row(
                                children: [
                                  if (_isLoading)
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Colors.grey),
                                    )
                                  else
                                    const Icon(
                                        Icons.restaurant_menu_outlined,
                                        size: 16.0,
                                        color: Colors.grey),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    _isLoading
                                        ? 'Loading...'
                                        : tools.isEmpty
                                        ? 'No tools listed'
                                        : '${tools.length} tool${tools.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12.0),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),
                          // ✅ Stats — read-only (servings not adjustable here)
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                            children: [
                              _buildInfoItem(
                                Icons.access_time,
                                _timeDisplay,
                                'Time',
                                const Color(0xFFE8F5E9),
                                const Color(0xFF1BAB52),
                              ),
                              _buildInfoItem(
                                Icons.attach_money,
                                _budgetDisplay,
                                'Budget',
                                const Color(0xFFFFF3E0),
                                const Color(0xFFFF9800),
                              ),
                              _buildInfoItem(
                                Icons.people_outline,
                                '$servings',
                                'Servings',
                                const Color(0xFFE8F5E9),
                                const Color(0xFF1BAB52),
                              ),
                              // ✅ Calories — shows correctly after Spoonacular fetch
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
                    // ✅ Tools list — filled after fetchSpoonacularDetails
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
                          // ✅ Steps — filled after fetchSpoonacularDetails
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