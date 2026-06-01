import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/recipe_service.dart';
import '../globals/app_state.dart';
import '../widgets/scan_page_popup.dart';

class SearchRecipes extends StatefulWidget {
  const SearchRecipes({super.key});

  @override
  State<SearchRecipes> createState() => _SearchRecipesState();
}

class _SearchRecipesState extends State<SearchRecipes> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _searchError;

  bool showFilters = false;
  int? maxDuration;
  int? maxServings;
  int? maxCalories;
  String? selectedDifficulty;
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();

  // ── Save state — keyed by recipe id string ────────────────────────────────
  final Map<String, bool> _savingMap = {};
  final Set<String> _savedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    _durationController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  // ── SAVE ──────────────────────────────────────────────────────────────────

  Future<void> _saveRecipe(Map<String, dynamic> recipe) async {
    final id = recipe['id']?.toString() ?? '';
    if (_savedIds.contains(id) || _savingMap[id] == true) return;

    setState(() => _savingMap[id] = true);

    try {
      // RecipeService.saveSearchedRecipe uses the correct column names:
      // difficulty_level, tools_required, cooking_steps, etc.
      await RecipeService.saveSearchedRecipe(recipe);

      if (mounted) {
        setState(() {
          _savedIds.add(id);
          _savingMap.remove(id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe saved to My Recipes!'),
            backgroundColor: Color(0xFF1BAB52),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingMap.remove(id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── API CALL ──────────────────────────────────────────────────────────────

  Future<void> _searchRecipes() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchError = null;
      _searchResults = [];
    });

    try {
      // Step 1: Search for recipe IDs
      final searchUri = Uri.parse(
        'https://api.spoonacular.com/recipes/complexSearch'
            '?query=${Uri.encodeComponent(query)}'
            '&apiKey=${RecipeService.spoonacularApiKey}'
            '&number=10',
      );

      final searchResponse = await http
          .get(searchUri)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (searchResponse.statusCode == 401) {
        setState(() {
          _searchError = 'Invalid API key. Please check your Spoonacular API key.';
          _isSearching = false;
        });
        return;
      }
      if (searchResponse.statusCode == 402) {
        setState(() {
          _searchError = 'Daily limit reached (150 points/day free). Try again tomorrow.';
          _isSearching = false;
        });
        return;
      }
      if (searchResponse.statusCode != 200) {
        setState(() {
          _searchError = 'Search failed (${searchResponse.statusCode}). Try again.';
          _isSearching = false;
        });
        return;
      }

      final searchData = json.decode(searchResponse.body);
      final basicResults = searchData['results'] as List? ?? [];

      if (basicResults.isEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        return;
      }

      // Step 2: Bulk fetch FULL details (tools, calories, steps)
      final ids = basicResults
          .map((r) => (r as Map<String, dynamic>)['id'].toString())
          .join(',');

      final bulkUri = Uri.parse(
        'https://api.spoonacular.com/recipes/informationBulk'
            '?ids=$ids'
            '&apiKey=${RecipeService.spoonacularApiKey}'
            '&includeNutrition=true',
      );

      final bulkResponse = await http
          .get(bulkUri)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (bulkResponse.statusCode == 200) {
        final fullDetails = json.decode(bulkResponse.body) as List? ?? [];
        setState(() {
          _searchResults = fullDetails
              .map((meal) => RecipeService.mapFullSpoonacularRecipe(
            meal as Map<String, dynamic>,
          ))
              .toList();
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchResults = basicResults
              .map((meal) => RecipeService.mapSpoonacularSearchResult(
            meal as Map<String, dynamic>,
          ))
              .toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = 'No internet connection. Please try again.';
        _isSearching = false;
      });
    }
  }

  // ── FILTERS ───────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredResults {
    return _searchResults.where((r) {
      if (maxDuration != null && (r['cookTimeMinutes'] as int? ?? 0) > maxDuration!) return false;
      if (maxServings != null && (r['servings'] as int? ?? 0) > maxServings!) return false;
      if (maxCalories != null && (r['caloriesPerServing'] as int? ?? 0) > maxCalories!) return false;
      if (selectedDifficulty != null && r['difficulty'] != selectedDifficulty) return false;
      return true;
    }).toList();
  }

  void _applyFilters() => setState(() {
    maxDuration = int.tryParse(_durationController.text);
    maxServings = int.tryParse(_servingsController.text);
    maxCalories = int.tryParse(_caloriesController.text);
    showFilters = false;
  });

  void _clearFilters() => setState(() {
    _durationController.clear();
    _servingsController.clear();
    _caloriesController.clear();
    maxDuration = null;
    maxServings = null;
    maxCalories = null;
    selectedDifficulty = null;
  });

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final results = _filteredResults;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
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
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const ScanPagePopup(),
        ),
        backgroundColor: const Color(0xFFFF7043),
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28.0),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
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

          // Meal Plan | My Recipes top tabs
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
          const SizedBox(height: 32.0),

          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Recipes',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003D33),
                ),
              ),
              Text(
                'View Saved Recipes',
                style: TextStyle(fontSize: 14.0, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 24.0),

          // My Saved Recipes | Search Recipes sub-tabs
          Container(
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
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  // ── SEARCH BAR ────────────────────────────────────────────────────────────

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
                    offset: const Offset(0.0, 2.0))
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
                    onSubmitted: (_) => _searchRecipes(),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Try "nasi lemak", "chicken curry"...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14.0),
                      border: InputBorder.none,
                    ),
                  ),
                ),
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
                      child: Icon(Icons.close, color: Colors.grey, size: 18.0),
                    ),
                  ),
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
                          strokeWidth: 2.0, color: Colors.white),
                    )
                        : const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 20.0),
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
            height: 54.0,
            width: 54.0,
            decoration: BoxDecoration(
              color: showFilters
                  ? const Color(0xFF1BAB52)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Icon(Icons.tune,
                color:
                showFilters ? Colors.white : const Color(0xFF003D33)),
          ),
        ),
      ],
    );
  }

  // ── FILTERS ───────────────────────────────────────────────────────────────

  Widget _buildFilterForm() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter Results',
              style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003D33))),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                  child: _buildFilterField(
                      'Max Duration (min)', _durationController, '60')),
              const SizedBox(width: 12.0),
              Expanded(
                  child: _buildFilterField(
                      'Max Servings', _servingsController, '10')),
            ],
          ),
          const SizedBox(height: 12.0),
          _buildFilterField(
              'Max Calories (per serving)', _caloriesController, '1000'),
          const SizedBox(height: 16.0),
          const Text('Difficulty',
              style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF003D33))),
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
                        borderRadius: BorderRadius.circular(12.0)),
                  ),
                  child: const Text('Clear',
                      style: TextStyle(
                          color: Color(0xFF1BAB52),
                          fontWeight: FontWeight.w600)),
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
                        borderRadius: BorderRadius.circular(12.0)),
                    elevation: 0.0,
                  ),
                  child: const Text('Apply Filters',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterField(
      String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF003D33))),
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
                  : const Color(0xFFEEEEEE)),
        ),
        child: Text(difficulty,
            style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF003D33),
                fontWeight: FontWeight.w600,
                fontSize: 13.0)),
      ),
    );
  }

  // ── STATES ────────────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Column(
          children: [
            const CircularProgressIndicator(color: Color(0xFF1BAB52)),
            const SizedBox(height: 20.0),
            Text('Searching for "${_searchController.text}"...',
                style:
                const TextStyle(color: Colors.grey, fontSize: 14.0)),
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
                  borderRadius: BorderRadius.circular(20.0)),
              child: const Icon(Icons.wifi_off_outlined,
                  size: 48.0, color: Color(0xFFEF5350)),
            ),
            const SizedBox(height: 16.0),
            Text(_searchError ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF003D33),
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 20.0),
            ElevatedButton.icon(
              onPressed: _searchRecipes,
              icon: const Icon(Icons.refresh, size: 18.0),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1BAB52),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final suggestions = [
      'Nasi Lemak',
      'Chicken Curry',
      'Fried Rice',
      'Rendang',
      'Pasta',
      'Sushi',
    ];
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 16.0),
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: Column(
          children: [
            const Icon(Icons.travel_explore,
                size: 64.0, color: Color(0xFF1BAB52)),
            const SizedBox(height: 16.0),
            const Text('Search millions of recipes',
                style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003D33))),
            const SizedBox(height: 8.0),
            const Text(
                'Try searching for your favourite dish\nand discover recipes from around the world',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14.0)),
            const SizedBox(height: 24.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: suggestions.map((s) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = s;
                    _searchRecipes();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                          color: const Color(0xFF1BAB52)
                              .withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search,
                            size: 14.0, color: Color(0xFF1BAB52)),
                        const SizedBox(width: 6.0),
                        Text(s,
                            style: const TextStyle(
                                color: Color(0xFF003D33),
                                fontSize: 13.0,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }).toList(),
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
            const Icon(Icons.search_off_outlined,
                size: 64.0, color: Colors.grey),
            const SizedBox(height: 16.0),
            Text('No recipes found for\n"${_searchController.text}"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF003D33),
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8.0),
            const Text('Try different keywords',
                style: TextStyle(color: Colors.grey, fontSize: 14.0)),
          ],
        ),
      ),
    );
  }

  // ── RESULTS ───────────────────────────────────────────────────────────────

  Widget _buildResultsList(List<Map<String, dynamic>> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    final id = recipe['id']?.toString() ?? '';
    final cookTime = recipe['cookTimeMinutes'] as int? ?? 0;
    final servings = recipe['servings'] as int? ?? 4;
    final difficulty = recipe['difficulty'] as String? ?? 'Medium';
    final mealTypes = recipe['mealType'] as List? ?? [];
    final tools = recipe['tools'] as List? ?? [];
    final calories = recipe['caloriesPerServing'] as int? ?? 0;
    final budget = recipe['budget']?.toString() ?? '0';

    final isSaved = _savedIds.contains(id);
    final isSaving = _savingMap[id] == true;

    return GestureDetector(
      onTap: () => context.pushNamed(
        'recipe-view',
        extra: Map<String, dynamic>.from(recipe),
      ),
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
                offset: const Offset(0.0, 4.0))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ────────────────────────────────────────────────
            if (recipe['image'] != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20.0)),
                child: Image.network(
                  recipe['image'] as String,
                  height: 160.0,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 80.0,
                    color: const Color(0xFFF5F5F5),
                    child: const Center(
                        child: Icon(Icons.restaurant,
                            color: Colors.grey, size: 32.0)),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name row + Save button ────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe['name'] as String? ?? 'Recipe',
                          style: const TextStyle(
                              fontSize: 17.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003D33)),
                        ),
                      ),
                      // Save button — absorbs tap so it doesn't open recipe
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _saveRecipe(recipe),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: isSaved
                                ? const Color(0xFF1BAB52)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: isSaving
                              ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1BAB52),
                            ),
                          )
                              : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_add_outlined,
                                size: 14.0,
                                color: isSaved
                                    ? Colors.white
                                    : const Color(0xFF1BAB52),
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                isSaved ? 'Saved' : 'Save',
                                style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                    color: isSaved
                                        ? Colors.white
                                        : const Color(0xFF1BAB52)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8.0),

                  // ── Difficulty + meal type ────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(difficulty,
                            style: const TextStyle(
                                color: Color(0xFF1BAB52),
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (mealTypes.isNotEmpty)
                        Text(mealTypes.take(2).join(', '),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12.0)),
                    ],
                  ),

                  const SizedBox(height: 12.0),

                  // ── Stats row ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat(Icons.access_time, '${cookTime}m'),
                      _buildStat(Icons.attach_money,
                          budget == '0' ? 'N/A' : 'RM$budget'),
                      _buildStat(Icons.people_outline, '$servings'),
                      _buildStat(
                          Icons.local_fire_department_outlined,
                          calories == 0 ? 'N/A' : '$calories kcal'),
                      _buildStat(
                          Icons.handyman_outlined,
                          '${tools.length} tool${tools.length == 1 ? '' : 's'}'),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.0, color: Colors.grey),
        const SizedBox(width: 3.0),
        Text(value,
            style: const TextStyle(fontSize: 11.0, color: Colors.grey)),
      ],
    );
  }

  // ── BOTTOM NAV ────────────────────────────────────────────────────────────

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10.0,
              offset: const Offset(0.0, -2))
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
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined), label: 'Plan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined), label: 'List'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined), label: 'Pantry'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}