import 'package:flutter/material.dart';
import '../globals/app_state.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../services/recipe_service.dart';
import '../services/grocery_service.dart';
import '../services/pantry_service.dart';
import '../services/ingredient_pricing_service.dart';

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
    final isFullyLoaded = widget.recipe['isFullyLoaded'] == true;

    if (isFromSearch && !isFullyLoaded && id != null && id is String && !id.contains('-')) {
      _fetchSpoonacularDetails(id);
    } else if (id != null && id is String && id.contains('-')) {
      _refreshFromSupabase(id);
    }
  }

  // ── DATA FETCHING ─────────────────────────────────────────────────────────

  Future<void> _fetchSpoonacularDetails(String spoonacularId) async {
    setState(() => _isLoading = true);
    try {
      final full = await RecipeService.fetchSpoonacularRecipe(spoonacularId);
      if (full != null && mounted) {
        setState(() => _currentRecipe = full);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshFromSupabase(String id) async {
    setState(() => _isLoading = true);
    try {
      final fresh = await RecipeService.getRecipeById(id);
      if (fresh != null && mounted) {
        setState(() => _currentRecipe = fresh);
      }
    } catch (_) {
    } finally {
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

  String _inferCategory(String name) {
    final n = name.toLowerCase();
    if (RegExp(r'cheese|milk|butter|cream|egg|yogurt|cheddar|mozzarella|dairy')
        .hasMatch(n)) return 'Dairy & Eggs';
    if (RegExp(
        r'chicken|beef|pork|lamb|turkey|duck|bacon|sausage|ham|steak|mince|meat|veal')
        .hasMatch(n)) return 'Meat & Poultry';
    if (RegExp(r'fish|salmon|tuna|shrimp|prawn|crab|lobster|cod|tilapia|seafood|squid')
        .hasMatch(n)) return 'Seafood';
    if (RegExp(
        r'corn|pepper|tomato|onion|garlic|carrot|spinach|lettuce|avocado|potato|capsicum|bean|zucchini|broccoli|mushroom|celery|cucumber|kale|cabbage|pea|leek|chilli|chili')
        .hasMatch(n)) return 'Vegetables & Produce';
    if (RegExp(
        r'apple|banana|lemon|lime|orange|mango|strawberry|berry|grape|peach|pear|fruit')
        .hasMatch(n)) return 'Fruits';
    if (RegExp(
        r'quinoa|rice|flour|pasta|bread|oat|noodle|tortilla|wheat|grain|cereal|barley|couscous')
        .hasMatch(n)) return 'Grains & Pasta';
    if (RegExp(r'sauce|enchilada|salsa|verde|broth|stock|paste|canned|soup|dressing')
        .hasMatch(n)) return 'Canned & Jarred';
    if (RegExp(
        r'salt|cumin|cilantro|basil|oregano|paprika|thyme|rosemary|coriander|spice|herb|seasoning|cardamom|turmeric|cinnamon|nutmeg|pepper')
        .hasMatch(n)) return 'Herbs & Spices';
    if (RegExp(
        r'oil|olive oil|vinegar|soy sauce|mustard|mayo|mayonnaise|ketchup|syrup|honey')
        .hasMatch(n)) return 'Oils & Condiments';
    return 'Other';
  }

  // ── STEP 1: Load pantry → compute shortages → show selection sheet ────────

  Future<void> _showIngredientSelectionSheet() async {
    final allIngredients =
        _currentRecipe['ingredients'] as List<dynamic>? ?? [];
    if (allIngredients.isEmpty) return;

    // Load pantry inventory first
    setState(() => _isAddingToList = true);
    List<Map<String, dynamic>> pantryItems = [];
    try {
      final pantry = await PantryService.getItems('pantry');
      final fridge = await PantryService.getItems('fridge');
      pantryItems = [...pantry, ...fridge];
    } catch (_) {
      // Non-critical — continue without pantry check
    }
    if (mounted) setState(() => _isAddingToList = false);
    if (!mounted) return;

    // Pre-compute pantry shortage for every ingredient
    final List<PantryCheckResult> pantryChecks =
    allIngredients.map((ing) {
      if (ing is! Map) {
        return PantryCheckResult(
            status: PantryStatus.missing,
            shortageAmount: 0,
            neededAmount: 0);
      }
      final name = ing['name']?.toString().trim() ?? '';
      final amount =
          double.tryParse(ing['amount']?.toString() ?? '') ?? 0.0;
      final unit = ing['unit']?.toString().trim() ?? '';
      return IngredientPricingService.checkPantry(
        ingredientName: name,
        neededAmount: amount,
        neededUnit: unit,
        pantryItems: pantryItems,
      );
    }).toList();

    // Default: covered items unchecked, others checked
    final selected = List<bool>.generate(
      allIngredients.length,
          (i) => pantryChecks[i].status != PantryStatus.covered,
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final checkedCount = selected.where((v) => v).length;

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.72,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Choose Ingredients',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003D33),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setSheetState(() {
                          final allSelected = selected.every((v) => v);
                          for (int i = 0; i < selected.length; i++) {
                            selected[i] = allSelected
                                ? false
                                : pantryChecks[i].status !=
                                PantryStatus.covered;
                          }
                        }),
                        child: Text(
                          selected.every((v) => v)
                              ? 'Deselect All'
                              : 'Select All',
                          style: const TextStyle(
                            color: Color(0xFF1BAB52),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sub-count
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$checkedCount of ${allIngredients.length} selected',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ),
                ),

                const Divider(height: 1),

                // Ingredient list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    itemCount: allIngredients.length,
                    separatorBuilder: (_, __) =>
                    const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final ing = allIngredients[i];
                      if (ing is! Map) return const SizedBox.shrink();
                      final name =
                          ing['name']?.toString().trim() ?? '';
                      final amount =
                          ing['amount']?.toString().trim() ?? '';
                      final unit =
                          ing['unit']?.toString().trim() ?? '';
                      return _IngredientSelectionTile(
                        name: name,
                        amount: amount,
                        unit: unit,
                        isSelected: selected[i],
                        pantryCheck: pantryChecks[i],
                        onChanged: (val) => setSheetState(
                                () => selected[i] = val ?? false),
                      );
                    },
                  ),
                ),

                // Bottom: legend + CTA
                Container(
                  padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      MediaQuery.of(ctx).padding.bottom + 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Pantry legend
                      if (pantryItems.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              _legendDot(const Color(0xFF4CAF50)),
                              const SizedBox(width: 4),
                              Text('In pantry',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600)),
                              const SizedBox(width: 12),
                              _legendDot(const Color(0xFFFF9800)),
                              const SizedBox(width: 4),
                              Text('Partial',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600)),
                              const SizedBox(width: 12),
                              _legendDot(Colors.grey.shade300),
                              const SizedBox(width: 4),
                              Text('Not in pantry',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600)),
                            ],
                          ),
                        ),

                      // Add button
                      ElevatedButton.icon(
                        onPressed: checkedCount == 0
                            ? null
                            : () {
                          Navigator.pop(ctx);
                          final chosen =
                          <Map<String, dynamic>>[];
                          final chosenChecks =
                          <PantryCheckResult>[];
                          for (int i = 0;
                          i < allIngredients.length;
                          i++) {
                            if (selected[i] &&
                                allIngredients[i] is Map) {
                              chosen.add(
                                  Map<String, dynamic>.from(
                                      allIngredients[i]
                                      as Map));
                              chosenChecks
                                  .add(pantryChecks[i]);
                            }
                          }
                          _addIngredientsToGroceryList(
                              chosen,
                              chosenChecks,
                              pantryItems);
                        },
                        icon: const Icon(
                            Icons.add_shopping_cart_outlined,
                            size: 20),
                        label: Text(
                          checkedCount == 0
                              ? 'Select at least one ingredient'
                              : 'Add $checkedCount Ingredient${checkedCount == 1 ? '' : 's'} to List',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1BAB52),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF1BAB52)
                              .withValues(alpha: 0.35),
                          disabledForegroundColor: Colors.white60,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  // ── STEP 2: Smart add — pantry-aware + AI pricing ─────────────────────────

  Future<void> _addIngredientsToGroceryList(
      List<Map<String, dynamic>> selectedIngredients,
      List<PantryCheckResult> pantryChecks,
      List<Map<String, dynamic>> pantryItems,
      ) async {
    if (selectedIngredients.isEmpty) return;
    setState(() => _isAddingToList = true);

    final recipeName =
        _currentRecipe['name'] as String? ?? 'Unknown Recipe';
    int added = 0;
    int skipped = 0;
    int pantrySkipped = 0;

    for (int idx = 0; idx < selectedIngredients.length; idx++) {
      final ing = selectedIngredients[idx];
      final check = pantryChecks[idx];

      final name = ing['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;

      // Fully covered by pantry — skip
      if (check.status == PantryStatus.covered) {
        pantrySkipped++;
        continue;
      }

      final unit = ing['unit']?.toString().trim() ?? '';
      final buyAmount = check.status == PantryStatus.partial
          ? check.shortageAmount
          : check.neededAmount;

      if (buyAmount <= 0) {
        pantrySkipped++;
        continue;
      }

      // Get AI-estimated Malaysian retail price
      PricingResult pricing;
      try {
        pricing = await IngredientPricingService.estimatePrice(
          name: name,
          amount: buyAmount,
          unit: unit,
        );
      } catch (_) {
        pricing = const PricingResult(
          suggestedPurchaseUnit: '1 pack',
          estimatedPriceMyr: 5.0,
          priceSource: 'Estimated',
        );
      }

      final display = buyAmount == buyAmount.truncateToDouble()
          ? buyAmount.toInt().toString()
          : buyAmount.toStringAsFixed(1);
      final quantity =
      [display, unit].where((s) => s.isNotEmpty).join(' ');
      final category = _inferCategory(name);

      try {
        await GroceryService.addItem(
          name: name,
          quantity: quantity,
          quantityAmount: buyAmount,
          unit: unit.isNotEmpty ? unit : null,
          price: double.parse(
              pricing.estimatedPriceMyr.toStringAsFixed(2)),
          category: category,
          recipe: recipeName,
          suggestedPurchaseUnit: pricing.suggestedPurchaseUnit,
          priceSource: pricing.priceSource,
          pantryShortageAmount:
          check.status == PantryStatus.partial ? buyAmount : null,
        );
        added++;
      } catch (_) {
        skipped++;
      }
    }

    if (!mounted) return;
    setState(() => _isAddingToList = false);

    String msg;
    Color color;
    if (added == 0 && pantrySkipped > 0) {
      msg = '✅ All selected ingredients are already in your pantry!';
      color = const Color(0xFF1565C0);
    } else if (added > 0 && pantrySkipped > 0) {
      msg = '🛒 $added added · $pantrySkipped already in pantry';
      color = const Color(0xFF2E7D32);
    } else if (skipped > 0) {
      msg = '🛒 $added added · $skipped failed — check connection';
      color = const Color(0xFFE65100);
    } else {
      msg =
      '🛒 $added ingredient${added == 1 ? '' : 's'} added with real-price estimates!';
      color = const Color(0xFF2E7D32);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── UI WIDGET BUILDERS ────────────────────────────────────────────────────

  Widget _buildInfoItem(
      IconData icon, String text, String label, Color bg, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22.0),
            const SizedBox(height: 6.0),
            Text(
              text,
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.bold,
                fontSize: 13.0,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolChip(String tool) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFB2DFDB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.kitchen_outlined,
              size: 14.0, color: Color(0xFF1BAB52)),
          const SizedBox(width: 6.0),
          Text(
            tool,
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
      padding:
      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
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

  Widget _buildLoadingSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(title,
              style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003D33))),
        if (title.isNotEmpty) const SizedBox(height: 12.0),
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
            // ── App Bar ───────────────────────────────────────────────
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  // Edit button (saved recipes only)
                  if (!isFromSearch)
                    GestureDetector(
                      onTap: () async {
                        final result = await context.pushNamed(
                          'recipe-edit',
                          extra: _currentRecipe,
                        );
                        if (result != null &&
                            result is Map<String, dynamic>) {
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
                  const SizedBox(width: 8.0),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 18.0, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe image
                    _buildRecipeImage(),
                    const SizedBox(height: 20.0),

                    // Info card row (difficulty badge + stats grid)
                    _buildInfoCard(servings),
                    const SizedBox(height: 28.0),

                    // Tools Required
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

                    // Ingredients section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9)
                            .withValues(alpha: 0.5),
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
                                final name =
                                    ing['name']?.toString() ?? '';
                                final amount =
                                    ing['amount']?.toString() ?? '';
                                final unit =
                                    ing['unit']?.toString() ?? '';
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

                    // ── Add to Grocery List button ─────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isAddingToList || ingredients.isEmpty)
                            ? null
                            : () => _showIngredientSelectionSheet(),
                        icon: _isAddingToList
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                            Icons.add_shopping_cart_outlined,
                            size: 20),
                        label: Text(
                          _isAddingToList
                              ? 'Checking pantry & estimating prices...'
                              : 'Add Ingredients to Grocery List',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1BAB52),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF1BAB52)
                              .withValues(alpha: 0.4),
                          disabledForegroundColor: Colors.white70,
                          padding:
                          const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28.0),

                    // Cooking Instructions
                    const Row(
                      children: [
                        Icon(Icons.menu_book_outlined,
                            color: Color(0xFF1BAB52), size: 20.0),
                        SizedBox(width: 8.0),
                        Text(
                          'Cooking Instructions',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003D33),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    if (_isLoading)
                      _buildLoadingSection('')
                    else if (instructions.isEmpty)
                      const Text(
                        'No instructions available.',
                        style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic),
                      )
                    else
                      ...instructions.asMap().entries.map((e) =>
                          _buildStepItem(
                              e.key + 1, e.value.toString())),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeImage() {
    final imageUrl = _currentRecipe['image'];
    if (imageUrl == null || (imageUrl as String).isEmpty) {
      return _buildPlaceholderImage();
    }

    // Local file (user-uploaded recipe)
    if (!imageUrl.startsWith('http')) {
      final file = File(imageUrl);
      return ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: Image.file(
          file,
          height: 200.0,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: Image.network(
        imageUrl,
        height: 200.0,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildInfoCard(int servings) {
    final difficulty =
    (_currentRecipe['difficulty'] as String? ?? 'Easy');
    final toolsCount =
        (_currentRecipe['tools'] as List? ?? []).length;

    Color diffColor;
    switch (difficulty) {
      case 'Hard':
        diffColor = Colors.red.shade600;
        break;
      case 'Medium':
        diffColor = Colors.orange.shade600;
        break;
      default:
        diffColor = const Color(0xFF1BAB52);
    }

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border:
        Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  difficulty,
                  style: TextStyle(
                    color: diffColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.0,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$toolsCount tool${toolsCount == 1 ? '' : 's'} needed',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13.0),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              _buildInfoItem(
                Icons.access_time_outlined,
                _isLoading ? '...' : _timeDisplay,
                'Cook Time',
                const Color(0xFFFFF8E1),
                const Color(0xFFFFA000),
              ),
              const SizedBox(width: 10.0),
              _buildInfoItem(
                Icons.people_outline,
                '$servings',
                'Servings',
                const Color(0xFFE8EAF6),
                const Color(0xFF3949AB),
              ),
              const SizedBox(width: 10.0),
              _buildInfoItem(
                Icons.attach_money_outlined,
                _isLoading ? '...' : _budgetDisplay,
                'Budget',
                const Color(0xFFE8F5E9),
                const Color(0xFF1BAB52),
              ),
              const SizedBox(width: 10.0),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ingredient selection tile shown inside the bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _IngredientSelectionTile extends StatelessWidget {
  final String name;
  final String amount;
  final String unit;
  final bool isSelected;
  final PantryCheckResult pantryCheck;
  final ValueChanged<bool?> onChanged;

  const _IngredientSelectionTile({
    required this.name,
    required this.amount,
    required this.unit,
    required this.isSelected,
    required this.pantryCheck,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isCovered = pantryCheck.status == PantryStatus.covered;
    final isPartial = pantryCheck.status == PantryStatus.partial;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isSelected,
              onChanged: onChanged,
              activeColor: const Color(0xFF1BAB52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5)),
              side:
              BorderSide(color: Colors.grey.shade400, width: 1.5),
            ),
          ),
          const SizedBox(width: 14),

          // Name + quantity info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isCovered
                        ? Colors.grey.shade400
                        : const Color(0xFF1A1A1A),
                    decoration: isCovered
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [amount, unit].where((s) => s.isNotEmpty).join(' '),
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500),
                ),
                if (isPartial) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Buy ${IngredientPricingService.formatShortage(pantryCheck.shortageAmount, unit)} more (partial in pantry)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE65100),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Pantry status badge
          if (isCovered)
            _PantryBadge(
              label: 'In pantry',
              color: const Color(0xFF4CAF50),
              icon: Icons.check_circle_outline,
            )
          else if (isPartial)
            _PantryBadge(
              label: 'Partial',
              color: const Color(0xFFFF9800),
              icon: Icons.circle_outlined,
            ),
        ],
      ),
    );
  }
}

class _PantryBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _PantryBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}