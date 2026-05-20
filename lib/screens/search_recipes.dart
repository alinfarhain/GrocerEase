import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../globals/app_state.dart';
import '../services/recipe_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SETUP REQUIRED BEFORE USING THIS FILE:
//
// 1. Add http package to pubspec.yaml:
//      dependencies:
//        http: ^1.2.0
//    Then run: flutter pub get
//
// 2. Get a FREE Spoonacular API key:
//      → Go to https://spoonacular.com/food-api
//      → Sign up for free (150 calls/day)
//      → Copy your API key
//      → Paste it below replacing 'YOUR_SPOONACULAR_API_KEY'
//
// 3. Allow internet on Android — add to android/app/src/main/AndroidManifest.xml
//    inside <manifest> tag:
//      <uses-permission android:name="android.permission.INTERNET"/>
// ─────────────────────────────────────────────────────────────────────────────

class SearchRecipes extends StatefulWidget {
  const SearchRecipes({super.key});

  @override
  State<SearchRecipes> createState() => _SearchRecipesState();
}

class _SearchRecipesState extends State<SearchRecipes> {
  // ── Paste your Spoonacular API key here ──────────────────────────────────
  static const String _apiKey = 'e6772569c1144f8283b6fd9e92e13e07';

  // ── State ─────────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _searchError;

  // Filter state
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

  @override
  void dispose() {
    _searchController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _durationController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  // ── API CALL ──────────────────────────────────────────────────────────────

  Future<void> _searchRecipes() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchError = null;
      _searchResults = [];
    });

    try {
      final uri = Uri.parse(
        'https://api.spoonacular.com/recipes/complexSearch'
            '?query=${Uri.encodeComponent(query)}'
            '&apiKey=$_apiKey'
            '&number=15'
            '&addRecipeInformation=true'
            '&fillIngredients=true',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];

        setState(() {
          _searchResults =
              results.map((meal) => _mapSpoonacularRecipe(meal)).toList();
          _isSearching = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _searchError =
          'Invalid API key. Please check your Spoonacular API key.';
          _isSearching = false;
        });
      } else if (response.statusCode == 402) {
        setState(() {
          _searchError =
          'Daily API limit reached (150 searches/day on free plan). Try again tomorrow.';
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchError = 'Search failed (${response.statusCode}). Try again.';
          _isSearching = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError =
        'Could not connect. Please check your internet connection.';
        _isSearching = false;
      });
    }
  }

  // ── FIELD MAPPING ─────────────────────────────────────────────────────────
  // Maps a Spoonacular API result → the local recipe format used in the app

  Map<String, dynamic> _mapSpoonacularRecipe(Map<String, dynamic> meal) {
    // Build ingredients list from extendedIngredients
    final ingredients = (meal['extendedIngredients'] as List? ?? [])
        .map(
          (ing) => {
        'name': ing['name'] ?? '',
        'amount': (ing['amount'] ?? '').toString(),
        'unit': ing['unit'] ?? '',
      },
    )
        .toList();

    // Build cooking steps from analyzedInstructions
    final instructions = <String>[];
    final analyzedInstructions =
        meal['analyzedInstructions'] as List? ?? [];
    if (analyzedInstructions.isNotEmpty) {
      final steps =
          analyzedInstructions[0]['steps'] as List? ?? [];
      for (final step in steps) {
        final text = step['step']?.toString().trim() ?? '';
        if (text.isNotEmpty) instructions.add(text);
      }
    }
    // Fallback: if no analyzed instructions, split summary
    if (instructions.isEmpty) {
      final summary = (meal['summary'] ?? '') as String;
      final cleaned =
      summary.replaceAll(RegExp(r'<[^>]*>'), ''); // strip HTML
      if (cleaned.isNotEmpty) instructions.add(cleaned);
    }

    // Estimate difficulty from cook time
    final readyInMinutes = (meal['readyInMinutes'] as int?) ?? 30;
    String difficulty = 'Medium';
    if (readyInMinutes <= 20) {
      difficulty = 'Easy';
    } else if (readyInMinutes > 60) {
      difficulty = 'Hard';
    }

    // Meal types from dishTypes
    final mealTypes = List<String>.from(
      (meal['dishTypes'] as List? ?? []).take(2),
    );

    return {
      'id': meal['id']?.toString(),
      'name': meal['title'] ?? 'Unknown Recipe',
      'image': meal['image'],
      'cookTimeMinutes': readyInMinutes,
      'prepTimeMinutes': 0,
      'servings': (meal['servings'] as int?) ?? 4,
      'caloriesPerServing': 0, // Spoonacular needs a separate call for this
      'difficulty': difficulty,
      'tools': <String>[],
      'ingredients': ingredients,
      'instructions': instructions,
      'mealType': mealTypes,
      'budget': '0',
      'cuisine': meal['cuisines'] is List && (meal['cuisines'] as List).isNotEmpty
          ? (meal['cuisines'] as List).first
          : '',
      'isFromSearch': true, // Tells RecipeView to show Save button
      'sourceUrl': meal['sourceUrl'] ?? '',
    };
  }

  // ── FILTERS ───────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredResults {
    return _searchResults.where((recipe) {
      final duration = (recipe['cookTimeMinutes'] as int?) ?? 0;
      if (maxDuration != null && duration > maxDuration!) return false;
      if (maxServings != null &&
          (recipe['servings'] as int? ?? 0) > maxServings!) return false;
      if (maxCalories != null &&
          (recipe['caloriesPerServing'] as int? ?? 0) > maxCalories!) {
        return false;
      }
      if (selectedDifficulty != null &&
          recipe['difficulty'] != selectedDifficulty) return false;
      return true;
    }).toList();
  }

  void _applyFilters() {
    setState(() {
      maxDuration = int.tryParse(_durationController.text);
      maxServings = int.tryParse(_servingsController.text);
      maxCalories = int.tryParse(_caloriesController.text);
      showFilters = false;
    });
  }

  void _clearFilters() {
    setState(() {
      _durationController.clear();
      _servingsController.clear();
      _caloriesController.clear();
      maxDuration = null;
      maxServings = null;
      maxCalories = null;
      selectedDifficulty = null;
    });
  }

  // ── BUILD METHODS ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final results = _filteredResults;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // ── Fixed Header ──────────────────────────────────────────────
            _buildHeader(),
            // ── Scrollable Content ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8.0),
                    _buildSearchBar(),
                    const SizedBox(height: 16.0),
                    if (showFilters) _buildFilterForm(),
                    const SizedBox(height: 8.0),

                    // ── States ──────────────────────────────────────────────
                    if (_isSearching)
                      _buildLoadingState()
                    else if (_searchError != null)
                      _buildErrorState()
                    else if (!_hasSearched)
                        _buildEmptyState()
                      else if (results.isEmpty)
                          _buildNoResultsState()
                        else
                          _buildResultsList(results),

                    const SizedBox(height: 40.0),
                  ],
                ),
              ),
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
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFFF9F9F9),
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
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
          // Tabs
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
                    onTap: () => context.pop(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'My Saved Recipes',
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
                      'Search Recipes',
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
          const SizedBox(height: 20.0),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Recipes',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D33),
                      ),
                    ),
                    Text(
                      'Discover recipes from the internet',
                      style: TextStyle(fontSize: 13.0, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Results count badge
              if (_hasSearched && !_isSearching && _searchError == null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    '${_filteredResults.length} found',
                    style: const TextStyle(
                      color: Color(0xFF1BAB52),
                      fontWeight: FontWeight.w600,
                      fontSize: 13.0,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 54.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFEEEEEE)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8.0,
                  offset: const Offset(0.0, 2.0),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16.0),
                const Icon(Icons.search, color: Colors.grey, size: 22.0),
                const SizedBox(width: 10.0),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    // Trigger search when user presses Enter on keyboard
                    onSubmitted: (_) => _searchRecipes(),
                    decoration: const InputDecoration(
                      hintText: 'Try "nasi lemak", "chicken curry"...',
                      hintStyle:
                      TextStyle(color: Colors.grey, fontSize: 14.0),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                // Clear button
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                        _hasSearched = false;
                        _searchError = null;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.close,
                          color: Colors.grey, size: 18.0),
                    ),
                  ),
                // Search submit button
                GestureDetector(
                  onTap: _isSearching ? null : _searchRecipes,
                  child: Container(
                    margin: const EdgeInsets.all(6.0),
                    width: 42.0,
                    height: 42.0,
                    decoration: BoxDecoration(
                      color: _isSearching
                          ? Colors.grey
                          : const Color(0xFF1BAB52),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: _isSearching
                        ? const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        // Filter toggle button
        GestureDetector(
          onTap: () => setState(() => showFilters = !showFilters),
          child: Container(
            height: 54.0,
            width: 54.0,
            decoration: BoxDecoration(
              color: showFilters
                  ? const Color(0xFF1BAB52)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16.0),
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

  Widget _buildFilterForm() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
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
          const Text(
            'Filter Results',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003D33),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: _buildFilterField(
                    'Max Duration (min)', _durationController, '60'),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildFilterField(
                    'Max Servings', _servingsController, '10'),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          _buildFilterField(
              'Max Calories (per serving)', _caloriesController, '1000'),
          const SizedBox(height: 16.0),
          const Text(
            'Difficulty',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF003D33),
            ),
          ),
          const SizedBox(height: 10.0),
          Row(
            children: [
              _buildDifficultyChip('Easy'),
              const SizedBox(width: 8.0),
              _buildDifficultyChip('Medium'),
              const SizedBox(width: 8.0),
              _buildDifficultyChip('Hard'),
            ],
          ),
          const SizedBox(height: 20.0),
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
                    'Clear',
                    style: TextStyle(
                      color: Color(0xFF1BAB52),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
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
            fontSize: 13.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF003D33),
          ),
        ),
        const SizedBox(height: 6.0),
        Container(
          height: 44.0,
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
              TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
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
      onTap: () => setState(
              () => selectedDifficulty = isSelected ? null : difficulty),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1BAB52)
              : const Color(0xFFE8F5E9).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : const Color(0xFFEEEEEE),
          ),
        ),
        child: Text(
          difficulty,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF003D33),
            fontWeight: FontWeight.w600,
            fontSize: 13.0,
          ),
        ),
      ),
    );
  }

  // ── Content States ────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Column(
          children: [
            const CircularProgressIndicator(color: Color(0xFF1BAB52)),
            const SizedBox(height: 20.0),
            Text(
              'Searching for "${_searchController.text}"...',
              style: const TextStyle(color: Colors.grey, fontSize: 14.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: const Icon(
                Icons.wifi_off_outlined,
                size: 48.0,
                color: Color(0xFFEF5350),
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              _searchError ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF003D33),
                fontSize: 15.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton.icon(
              onPressed: _searchRecipes,
              icon: const Icon(Icons.refresh, size: 18.0),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1BAB52),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.travel_explore,
                    size: 64.0,
                    color: Color(0xFF1BAB52),
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Search millions of recipes',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Try searching for your favourite dish\nand discover recipes from around the world',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14.0),
                  ),
                  const SizedBox(height: 24.0),
                  // Suggestion chips
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    alignment: WrapAlignment.center,
                    children: [
                      'Nasi Lemak',
                      'Chicken Curry',
                      'Pasta',
                      'Fried Rice',
                      'Rendang',
                      'Sushi',
                    ].map((suggestion) {
                      return GestureDetector(
                        onTap: () {
                          _searchController.text = suggestion;
                          _searchRecipes();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                              color: const Color(0xFF1BAB52)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.search,
                                size: 14.0,
                                color: Color(0xFF1BAB52),
                              ),
                              const SizedBox(width: 6.0),
                              Text(
                                suggestion,
                                style: const TextStyle(
                                  color: Color(0xFF003D33),
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_outlined,
              size: 64.0,
              color: Colors.grey,
            ),
            const SizedBox(height: 16.0),
            Text(
              'No recipes found for\n"${_searchController.text}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF003D33),
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Try different keywords or check your spelling',
              style: TextStyle(color: Colors.grey, fontSize: 14.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(List<Map<String, dynamic>> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Source attribution
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              const Icon(Icons.public, size: 14.0, color: Colors.grey),
              const SizedBox(width: 6.0),
              Text(
                'Showing ${results.length} results powered by Spoonacular',
                style:
                const TextStyle(color: Colors.grey, fontSize: 12.0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        ...results.map((recipe) => _buildRecipeCard(recipe)),
      ],
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final cookTime = recipe['cookTimeMinutes'] as int? ?? 0;
    final servings = recipe['servings'] as int? ?? 4;
    final difficulty = recipe['difficulty'] as String? ?? 'Medium';
    final mealTypes = recipe['mealType'] as List? ?? [];

    return GestureDetector(
      onTap: () {
        // Navigate to RecipeView — isFromSearch: true shows Save button
        context.pushNamed(
          'recipe-view',
          extra: Map<String, dynamic>.from(recipe),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8.0,
              offset: const Offset(0.0, 4.0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image
            if (recipe['image'] != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20.0),
                ),
                child: Image.network(
                  recipe['image'] as String,
                  height: 160.0,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100.0,
                    color: const Color(0xFFF5F5F5),
                    child: const Center(
                      child: Icon(Icons.restaurant,
                          color: Colors.grey, size: 40.0),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + chevron
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe['name'] as String? ?? 'Recipe',
                          style: const TextStyle(
                            fontSize: 17.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003D33),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bookmark_add_outlined,
                              size: 14.0,
                              color: Color(0xFF1BAB52),
                            ),
                            SizedBox(width: 4.0),
                            Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Color(0xFF1BAB52),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // Difficulty + meal type row
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
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
                          difficulty,
                          style: const TextStyle(
                            color: Color(0xFF1BAB52),
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (mealTypes.isNotEmpty)
                        Text(
                          mealTypes.take(2).join(', '),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12.0,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  // Stats row
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat(Icons.access_time,
                          '${cookTime}m'),
                      _buildStat(
                          Icons.people_outline, '$servings'),
                      _buildStat(
                        Icons.local_fire_department_outlined,
                        recipe['caloriesPerServing'] == 0
                            ? 'N/A'
                            : '${recipe['caloriesPerServing']}',
                      ),
                      _buildStat(
                        Icons.restaurant_menu_outlined,
                        '${(recipe['ingredients'] as List?)?.length ?? 0} ing.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14.0, color: Colors.grey),
        const SizedBox(width: 4.0),
        Text(
          value,
          style: const TextStyle(fontSize: 12.0, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
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
          context.go('/');
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
    );
  }
}