import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import '../globals/app_state.dart';

class SearchRecipes extends StatefulWidget {
  const SearchRecipes({super.key});

  @override
  State<SearchRecipes> createState() => _SearchRecipesState();
}

class _SearchRecipesState extends State<SearchRecipes> {
  static const String _apiKey = 'e6772569c1144f8283b6fd9e92e13e07';

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

  @override
  void dispose() {
    _searchController.dispose();
    _durationController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    super.dispose();
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
      final uri = Uri.parse(
        'https://api.spoonacular.com/recipes/complexSearch'
            '?query=${Uri.encodeComponent(query)}'
            '&apiKey=$_apiKey'
            '&number=15'
            '&addRecipeInformation=true'
            '&fillIngredients=true'
            '&addNutritionInformation=true',   // ← calories data
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        setState(() {
          _searchResults = results
              .map((meal) => _mapSpoonacularRecipe(meal as Map<String, dynamic>))
              .toList();
          _isSearching = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _searchError = 'Invalid API key. Please check your Spoonacular API key.';
          _isSearching = false;
        });
      } else if (response.statusCode == 402) {
        setState(() {
          _searchError = 'Daily limit reached (150/day free). Try again tomorrow.';
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
        _searchError = 'No internet connection. Please try again.';
        _isSearching = false;
      });
    }
  }

  // ── SPOONACULAR → LOCAL MAP ───────────────────────────────────────────────

  Map<String, dynamic> _mapSpoonacularRecipe(Map<String, dynamic> meal) {
    // 1. Extract cooking steps AND tools from analyzedInstructions
    final toolsSet = <String>{};
    final instructions = <String>[];

    final analyzedInstructions = meal['analyzedInstructions'] as List? ?? [];
    for (final group in analyzedInstructions) {
      if (group is! Map) continue;
      final steps = group['steps'] as List? ?? [];
      for (final step in steps) {
        if (step is! Map) continue;

        // Actual cooking step text
        final text = step['step']?.toString().trim() ?? '';
        if (text.isNotEmpty) instructions.add(text);

        // Extract kitchen tools from equipment list
        final equipment = step['equipment'] as List? ?? [];
        for (final eq in equipment) {
          if (eq is! Map) continue;
          final name = eq['name']?.toString().trim() ?? '';
          if (name.isNotEmpty) toolsSet.add(_capitalize(name));
        }
      }
    }

    // Fallback: if no analyzed instructions, parse plain text 'instructions' field
    if (instructions.isEmpty) {
      final plain = (meal['instructions'] as String? ?? '')
          .replaceAll(RegExp(r'<[^>]*>'), '') // strip HTML tags
          .trim();
      if (plain.isNotEmpty) {
        // Split by line breaks or numbered list patterns
        final parts = plain
            .split(RegExp(r'\r?\n+|\d+\.\s+'))
            .map((s) => s.trim())
            .where((s) => s.length > 10)
            .toList();
        instructions.addAll(parts.isEmpty ? [plain] : parts);
      }
    }

    // 2. Map ingredients — use Spoonacular's pre-converted metric measures
    final ingredients = <Map<String, dynamic>>[];
    for (final ing in (meal['extendedIngredients'] as List? ?? [])) {
      if (ing is! Map) continue;

      double amount;
      String unit;

      // Prefer the metric measure Spoonacular provides
      final metricMeasure = ing['measures']?['metric'];
      if (metricMeasure != null && metricMeasure['amount'] != null) {
        amount = (metricMeasure['amount'] as num).toDouble();
        unit = metricMeasure['unitShort']?.toString() ?? '';
      } else {
        amount = (ing['amount'] as num?)?.toDouble() ?? 0;
        unit = ing['unit']?.toString() ?? '';
      }

      // Manually convert any remaining US imperial units
      final converted = _convertToMetric(amount, unit);
      amount = converted['amount'] as double;
      unit = converted['unit'] as String;

      // Normalize unit display names
      unit = _normalizeUnit(unit);

      // Format the number (fractions for non-metric, decimals for metric)
      final formatted = _formatIngredientAmount(amount, unit);

      ingredients.add({
        'name': ing['name']?.toString() ?? '',
        'amount': formatted,
        'unit': unit,
      });
    }

    // 3. Extract calories per serving from nutrition block
    int caloriesPerServing = 0;
    final nutrition = meal['nutrition'];
    if (nutrition is Map) {
      final nutrients = nutrition['nutrients'] as List? ?? [];
      for (final n in nutrients) {
        if (n is Map &&
            (n['name'] as String? ?? '').toLowerCase() == 'calories') {
          caloriesPerServing = ((n['amount'] as num?)?.toDouble() ?? 0).round();
          break;
        }
      }
    }

    // 4. Estimate difficulty from cook time
    final readyInMinutes = (meal['readyInMinutes'] as int?) ?? 30;
    String difficulty = 'Medium';
    if (readyInMinutes <= 20) difficulty = 'Easy';
    if (readyInMinutes > 60) difficulty = 'Hard';

    // 5. Estimate RM budget from Spoonacular's USD price per serving
    // pricePerServing is in USD cents; 1 USD ≈ 4.7 MYR
    final servings = (meal['servings'] as int?) ?? 4;
    final priceUSDCents =
        (meal['pricePerServing'] as num?)?.toDouble() ?? 0;
    final budgetRM = (priceUSDCents / 100) * 4.7 * servings;
    final budget =
    budgetRM > 0 ? budgetRM.toStringAsFixed(2) : '0';

    return {
      'id': meal['id']?.toString(),
      'name': meal['title'] ?? '',
      'image': meal['image'],
      'cookTimeMinutes': readyInMinutes,
      'prepTimeMinutes': 0,
      'servings': servings,
      'caloriesPerServing': caloriesPerServing,
      'difficulty': difficulty,
      'tools': toolsSet.toList(),
      'ingredients': ingredients,
      'instructions': instructions,
      'mealType':
      List<String>.from((meal['dishTypes'] as List? ?? []).take(2)),
      'budget': budget,
      'isFromSearch': true,
      'sourceUrl': meal['sourceUrl'] ?? '',
    };
  }

  // ── UNIT HELPERS ──────────────────────────────────────────────────────────

  /// Converts US imperial amounts to metric. Returns {'amount': double, 'unit': String}.
  Map<String, dynamic> _convertToMetric(double amount, String unit) {
    switch (unit.toLowerCase().trim()) {
    // Weight
      case 'oz':
      case 'ounce':
      case 'ounces':
        return {'amount': _round(amount * 28.3495), 'unit': 'g'};
      case 'lb':
      case 'lbs':
      case 'pound':
      case 'pounds':
        final g = amount * 453.592;
        if (g >= 1000) return {'amount': _round(amount * 0.453592, dp: 2), 'unit': 'kg'};
        return {'amount': _round(g), 'unit': 'g'};
      case 'st':
      case 'stone':
      case 'stones':
        return {'amount': _round(amount * 6.35029, dp: 2), 'unit': 'kg'};

    // Volume
      case 'fl oz':
      case 'fluid ounce':
      case 'fluid ounces':
        return {'amount': _round(amount * 29.5735), 'unit': 'ml'};
      case 'pt':
      case 'pint':
      case 'pints':
        final mlPt = amount * 473.176;
        if (mlPt >= 1000) return {'amount': _round(amount * 0.473176, dp: 2), 'unit': 'l'};
        return {'amount': _round(mlPt), 'unit': 'ml'};
      case 'qt':
      case 'quart':
      case 'quarts':
        final mlQt = amount * 946.353;
        if (mlQt >= 1000) return {'amount': _round(amount * 0.946353, dp: 2), 'unit': 'l'};
        return {'amount': _round(mlQt), 'unit': 'ml'};
      case 'gal':
      case 'gallon':
      case 'gallons':
        return {'amount': _round(amount * 3.78541, dp: 2), 'unit': 'l'};

    // Temperature
      case 'f':
      case '°f':
      case 'fahrenheit':
        return {'amount': _round((amount - 32) * 5 / 9, dp: 1), 'unit': '°C'};

      default:
        return {'amount': amount, 'unit': unit};
    }
  }

  double _round(double value, {int dp = 1}) {
    final factor = math.pow(10, dp).toDouble();
    return (value * factor).round() / factor;
  }

  /// Normalizes unit display names.
  String _normalizeUnit(String unit) {
    switch (unit.toLowerCase().trim()) {
      case 'cups':        return 'cup';
      case 'tablespoon':
      case 'tablespoons':
      case 'tbsps':
      case 'tbs':         return 'tbsp';
      case 'teaspoon':
      case 'teaspoons':
      case 'tsps':        return 'tsp';
      case 'servings':    return 'serving';
      case 'grams':       return 'g';
      case 'kilograms':   return 'kg';
      case 'milligrams':  return 'mg';
      case 'milliliters':
      case 'millilitres': return 'ml';
      case 'liters':
      case 'litres':      return 'l';
      default:            return unit;
    }
  }

  /// Formats a number: decimals for metric units, fractions for everything else.
  String _formatIngredientAmount(double amount, String unit) {
    if (amount <= 0) return '0';

    const metricUnits = {'g', 'kg', 'mg', 'ml', 'l', 'cl', '°c'};
    if (metricUnits.contains(unit.toLowerCase())) {
      if (amount == amount.floorToDouble()) return amount.toInt().toString();
      return amount.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '');
    }

    return _toFraction(amount);
  }

  /// Converts a decimal to a readable fraction string, e.g. 1.5 → "1 1/2".
  String _toFraction(double amount) {
    if (amount <= 0) return '0';

    final int whole = amount.floor();
    final double frac = amount - whole;

    if (frac < 0.01) return whole.toString();

    final fractionMap = {
      0.125: '1/8',
      0.25:  '1/4',
      0.333: '1/3',
      0.375: '3/8',
      0.5:   '1/2',
      0.625: '5/8',
      0.667: '2/3',
      0.75:  '3/4',
      0.875: '7/8',
    };

    String fracStr = '';
    for (final entry in fractionMap.entries) {
      if ((frac - entry.key).abs() < 0.025) {
        fracStr = entry.value;
        break;
      }
    }

    if (fracStr.isEmpty) {
      final eighths = (frac * 8).round().clamp(1, 7);
      const e = ['', '1/8', '1/4', '3/8', '1/2', '5/8', '3/4', '7/8'];
      fracStr = e[eighths];
    }

    return whole > 0 ? '$whole $fracStr' : fracStr;
  }

  /// Capitalizes each word (for tool names).
  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
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
        onPressed: () {},
        backgroundColor: const Color(0xFFFF7043),
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28.0),
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
          const Text('Plan',
              style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003D33))),
          const SizedBox(height: 4.0),
          const Text('Manage meals and recipes',
              style: TextStyle(fontSize: 14.0, color: Colors.grey)),
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
                    onTap: () => context.pop(),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8.0)),
                      alignment: Alignment.center,
                      child: const Text('My Saved Recipes',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.grey)),
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
                            offset: const Offset(0.0, 2.0))
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text('Search Recipes',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF003D33))),
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
                    Text('Search Recipes',
                        style: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003D33))),
                    Text('Discover recipes from the internet',
                        style: TextStyle(fontSize: 13.0, color: Colors.grey)),
                  ],
                ),
              ),
              if (_hasSearched && !_isSearching && _searchError == null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text('${_filteredResults.length} found',
                      style: const TextStyle(
                          color: Color(0xFF1BAB52),
                          fontWeight: FontWeight.w600,
                          fontSize: 13.0)),
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
                      hintStyle:
                      TextStyle(color: Colors.grey, fontSize: 14.0),
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
                      color: _isSearching ? Colors.grey : const Color(0xFF1BAB52),
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
                color: showFilters ? Colors.white : const Color(0xFF003D33)),
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
                          color: Colors.white, fontWeight: FontWeight.bold)),
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
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1BAB52)
              : const Color(0xFFE8F5E9).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFEEEEEE)),
        ),
        child: Text(difficulty,
            style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF003D33),
                fontWeight: FontWeight.w600,
                fontSize: 13.0)),
      ),
    );
  }

  // ── States ────────────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Column(
          children: [
            const CircularProgressIndicator(color: Color(0xFF1BAB52)),
            const SizedBox(height: 20.0),
            Text('Searching for "${_searchController.text}"...',
                style: const TextStyle(color: Colors.grey, fontSize: 14.0)),
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
      'Nasi Lemak', 'Chicken Curry', 'Fried Rice',
      'Rendang', 'Pasta', 'Sushi',
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
                          color: const Color(0xFF1BAB52).withValues(alpha: 0.3)),
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

  Widget _buildResultsList(List<Map<String, dynamic>> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                style: const TextStyle(color: Colors.grey, fontSize: 12.0),
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
    final tools = recipe['tools'] as List? ?? [];
    final calories = recipe['caloriesPerServing'] as int? ?? 0;
    final budget = recipe['budget']?.toString() ?? '0';

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
            // Image
            if (recipe['image'] != null)
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20.0)),
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
                  // Name
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 5.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bookmark_add_outlined,
                                size: 14.0, color: Color(0xFF1BAB52)),
                            SizedBox(width: 4.0),
                            Text('Save',
                                style: TextStyle(
                                    fontSize: 12.0,
                                    color: Color(0xFF1BAB52),
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // Difficulty + meal type
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
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat(Icons.access_time, '${cookTime}m'),
                      _buildStat(Icons.attach_money,
                          budget == '0' ? 'N/A' : 'RM$budget'),
                      _buildStat(Icons.people_outline, '$servings'),
                      _buildStat(Icons.local_fire_department_outlined,
                          calories == 0 ? 'N/A' : '$calories kcal'),
                      _buildStat(Icons.handyman_outlined,
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
        Text(value, style: const TextStyle(fontSize: 11.0, color: Colors.grey)),
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