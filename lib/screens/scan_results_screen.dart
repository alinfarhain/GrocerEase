import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/recipe_save_service.dart';
import '../services/grocery_service.dart';
import '../services/pantry_service.dart';
import '../services/ingredient_pricing_service.dart';

class ScanResultsScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  const ScanResultsScreen({super.key, required this.result});

  @override
  State<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends State<ScanResultsScreen> {
  Map<String, dynamic>? _selectedRecipe;
  bool _isSaving = false;
  bool _savedSuccess = false;
  bool _isAddingToList = false;

  static const Color _green = Color(0xFF2E7D32);
  static const Color _lightGreen = Color(0xFFE8F5E9);

  bool get _isMeal => widget.result['type'] == 'meal';

  // ── SAVE MEAL ─────────────────────────────────────────────────────────────
  Future<void> _saveMealRecipe() async {
    setState(() => _isSaving = true);
    try {
      await RecipeSaveService.saveMealRecipe(widget.result);
      setState(() => _savedSuccess = true);
      _showSuccess('Recipe saved successfully!');
    } catch (e) {
      _showError('Failed to save: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ── SAVE FROM BOTTOM SHEET ────────────────────────────────────────────────
  Future<void> _saveSelectedRecipe(Map<String, dynamic> recipe) async {
    setState(() => _isSaving = true);
    try {
      await RecipeSaveService.saveRecipeSuggestion(
        recipe: recipe,
        overrideName: _isMeal ? widget.result['name'] : null,
      );
      setState(() {
        _selectedRecipe = null;
        _savedSuccess = true;
      });
      _showSuccess('Recipe saved successfully!');
    } catch (e) {
      _showError('Failed to save: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ── SAVE FIRST SUGGESTION ─────────────────────────────────────────────────
  Future<void> _saveFirstSuggestion(List<dynamic> suggestions) async {
    setState(() => _isSaving = true);
    try {
      final first = suggestions.first as Map<String, dynamic>;
      await RecipeSaveService.saveRecipeSuggestion(recipe: first);
      setState(() => _savedSuccess = true);
      _showSuccess('Recipe saved successfully!');
    } catch (e) {
      _showError('Failed to save: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ── INGREDIENT SHEET ──────────────────────────────────────────────────────
  Future<void> _showIngredientSheet(List<dynamic> ingredients) async {
    if (ingredients.isEmpty) return;

    // Pre-load pantry data before opening the sheet
    setState(() => _isAddingToList = true);
    List<Map<String, dynamic>> pantryItems = [];
    try {
      final pantry = await PantryService.getItems('pantry');
      final fridge = await PantryService.getItems('fridge');
      pantryItems = [...pantry, ...fridge];
    } catch (_) {
      // Non-critical — continue without pantry check
    }

    // Compute pantry coverage for every ingredient
    final List<PantryCheckResult> pantryChecks = ingredients.map((ing) {
      if (ing is! Map) {
        return const PantryCheckResult(
            status: PantryStatus.missing, shortageAmount: 0, neededAmount: 0);
      }
      final name = ing['name']?.toString().trim() ?? '';
      final amount = double.tryParse(ing['amount']?.toString() ?? '') ?? 0.0;
      final unit = ing['unit']?.toString().trim() ?? '';
      return IngredientPricingService.checkPantry(
        ingredientName: name,
        neededAmount: amount,
        neededUnit: unit,
        pantryItems: pantryItems,
      );
    }).toList();

    if (!mounted) return;
    setState(() => _isAddingToList = false);

    // Selection state — default all non-covered items selected
    final selected = List<bool>.generate(
      ingredients.length,
          (i) => pantryChecks[i].status != PantryStatus.covered,
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final checkedCount = selected.where((v) => v).length;
            final allIngredients = ingredients;

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Choose Ingredients',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: () {
                            final allSelected = selected.every((v) => v);
                            setSheetState(() {
                              for (int i = 0; i < selected.length; i++) {
                                selected[i] = allSelected
                                    ? false
                                    : pantryChecks[i].status !=
                                    PantryStatus.covered;
                              }
                            });
                          },
                          child: Text(
                            selected.every((v) => v)
                                ? 'Deselect All'
                                : 'Select All',
                            style: const TextStyle(
                              color: _green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Count
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$checkedCount of ${allIngredients.length} selected',
                        style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  // Ingredient list
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      itemCount: allIngredients.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final ing = allIngredients[i];
                        if (ing is! Map) return const SizedBox.shrink();
                        final name = ing['name']?.toString().trim() ?? '';
                        final amount = ing['amount']?.toString().trim() ?? '';
                        final unit = ing['unit']?.toString().trim() ?? '';
                        return _ScanIngredientTile(
                          name: name,
                          amount: amount,
                          unit: unit,
                          isSelected: selected[i],
                          pantryCheck: pantryChecks[i],
                          onChanged: (val) =>
                              setSheetState(() => selected[i] = val ?? false),
                        );
                      },
                    ),
                  ),

                  // Legend + button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      children: [
                        // Legend
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _legendDot(Colors.green),
                            const SizedBox(width: 4),
                            const Text('In pantry',
                                style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 14),
                            _legendDot(Colors.orange),
                            const SizedBox(width: 4),
                            const Text('Partial',
                                style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 14),
                            _legendDot(Colors.grey.shade400),
                            const SizedBox(width: 4),
                            const Text('Not in pantry',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Add to list button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: checkedCount == 0 || _isAddingToList
                                ? null
                                : () async {
                              final selectedIngredients = <Map<String,
                                  dynamic>>[];
                              final selectedChecks =
                              <PantryCheckResult>[];
                              for (int i = 0;
                              i < allIngredients.length;
                              i++) {
                                if (selected[i]) {
                                  selectedIngredients.add(
                                      Map<String, dynamic>.from(
                                          allIngredients[i] as Map));
                                  selectedChecks.add(pantryChecks[i]);
                                }
                              }
                              Navigator.pop(ctx);
                              await _addIngredientsToGroceryList(
                                  selectedIngredients, selectedChecks);
                            },
                            icon: _isAddingToList
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                                : const Icon(Icons.add_shopping_cart_outlined,
                                size: 20),
                            label: Text(
                              checkedCount == 0
                                  ? 'No items selected'
                                  : 'Add $checkedCount Ingredient${checkedCount != 1 ? 's' : ''} to List',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1BAB52),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                              const Color(0xFF1BAB52).withOpacity(0.35),
                              disabledForegroundColor: Colors.white60,
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── ADD INGREDIENTS TO GROCERY LIST ──────────────────────────────────────
  Future<void> _addIngredientsToGroceryList(
      List<Map<String, dynamic>> selectedIngredients,
      List<PantryCheckResult> pantryChecks,
      ) async {
    if (selectedIngredients.isEmpty) return;
    setState(() => _isAddingToList = true);

    final recipeName =
        widget.result['name'] as String? ?? 'Scanned Meal';
    int added = 0;
    int skipped = 0;
    int pantrySkipped = 0;

    for (int idx = 0; idx < selectedIngredients.length; idx++) {
      final ing = selectedIngredients[idx];
      final check = pantryChecks[idx];

      final name = ing['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;

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
          price: double.parse(pricing.estimatedPriceMyr.toStringAsFixed(2)),
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
      msg = '🛒 $added ingredient${added == 1 ? '' : 's'} added to your list!';
      color = const Color(0xFF2E7D32);
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  String _inferCategory(String name) {
    final n = name.toLowerCase();
    if (RegExp(r'chicken|beef|pork|lamb|fish|prawn|shrimp|meat|egg|tofu')
        .hasMatch(n)) return 'Protein';
    if (RegExp(r'milk|cheese|butter|cream|yogurt').hasMatch(n))
      return 'Dairy';
    if (RegExp(r'apple|banana|orange|mango|berry|fruit').hasMatch(n))
      return 'Fruits';
    if (RegExp(r'carrot|onion|garlic|potato|tomato|vegetable|spinach|cabbage|pepper|cucumber')
        .hasMatch(n)) return 'Vegetables';
    if (RegExp(r'rice|noodle|pasta|bread|flour|oat').hasMatch(n))
      return 'Grains';
    if (RegExp(r'oil|salt|sugar|sauce|soy|vinegar|spice|chili|pepper|cumin')
        .hasMatch(n)) return 'Condiments';
    if (RegExp(r'coconut milk|stock|broth|water').hasMatch(n)) return 'Liquids';
    return 'Other';
  }

  Widget _legendDot(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: _green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scan Results',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111)),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child:
                    const Icon(Icons.close, size: 22, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child:
                _isMeal ? _buildMealResult() : _buildIngredientsResult(),
              ),
            ),
          ],
        ),
      ),

      // Recipe detail bottom sheet
      bottomSheet: _selectedRecipe != null
          ? _RecipeDetailSheet(
        recipe: _selectedRecipe!,
        isSaving: _isSaving,
        onClose: () => setState(() => _selectedRecipe = null),
        onSave: () => _saveSelectedRecipe(_selectedRecipe!),
      )
          : null,
    );
  }

  // ────────────────────────────────────────────────────────
  // MEAL RESULT
  // ────────────────────────────────────────────────────────
  Widget _buildMealResult() {
    final recipe = widget.result['recipe'] as Map<String, dynamic>? ?? {};
    final ingredients = (recipe['ingredients'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success banner
        const _SuccessBanner(),
        const SizedBox(height: 20),

        // Detected Meal label
        const Text('Detected Meal',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),

        // Meal card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.result['name'] ?? 'Unknown Meal',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text('Complete recipe found',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.result['confidence'] ?? 0}% confidence',
                  style: const TextStyle(
                      color: _green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Recipe section ───────────────────────────────────
        const Text('Recipe',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tap below to view full recipe with ingredients and steps',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() => _selectedRecipe = {
                    ...recipe,
                    'name': widget.result['name'],
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _green,
                    side: const BorderSide(color: _green),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('View Full Recipe',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Ingredients section ──────────────────────────────
        const Text('Ingredients',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 15, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    ingredients.isEmpty
                        ? 'No ingredients found in recipe'
                        : '${ingredients.length} ingredient${ingredients.length != 1 ? 's' : ''} detected',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
              if (ingredients.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isAddingToList
                        ? null
                        : () => _showIngredientSheet(ingredients),
                    icon: _isAddingToList
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.add_shopping_cart_outlined,
                        size: 18),
                    label: Text(
                      _isAddingToList
                          ? 'Checking pantry...'
                          : 'Add Ingredients to Grocery List',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      disabledForegroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Add to Saved Recipes button ───────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving || _savedSuccess ? null : _saveMealRecipe,
            style: ElevatedButton.styleFrom(
              backgroundColor: _savedSuccess ? Colors.grey.shade400 : _green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
                : Text(
              _savedSuccess ? 'Saved ✓' : 'Add to Saved Recipes',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Scan Again button ────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _lightGreen,
              foregroundColor: _green,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Scan Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────
  // INGREDIENTS RESULT (scan ingredient mode)
  // ────────────────────────────────────────────────────────
  Widget _buildIngredientsResult() {
    final ingredients =
        (widget.result['ingredients'] as List<dynamic>?) ?? [];
    final suggestions =
        (widget.result['recipeSuggestions'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SuccessBanner(),
        const SizedBox(height: 20),

        const Text('Detected Ingredients',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),

        ...ingredients.map((ing) {
          final map = ing as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(map['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (map['confidence'] != null)
                  Text('${map['confidence']}%',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          );
        }),

        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Recipe Suggestions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...suggestions.map((s) {
            final recipe = s as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => setState(() => _selectedRecipe = recipe),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(recipe['name'] ?? '',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            );
          }),
        ],

        // ── Ingredients from recipe suggestion ────────────
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Ingredients',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Builder(builder: (_) {
            final suggestionIngredients = List<dynamic>.from(
              (suggestions.first as Map<String, dynamic>)['ingredients']
              as List<dynamic>? ??
                  [],
            );
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 15, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        suggestionIngredients.isEmpty
                            ? 'No ingredients found'
                            : '${suggestionIngredients.length} ingredient${suggestionIngredients.length != 1 ? 's' : ''} detected',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                  if (suggestionIngredients.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isAddingToList
                            ? null
                            : () =>
                            _showIngredientSheet(suggestionIngredients),
                        icon: _isAddingToList
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2E7D32)),
                        )
                            : const Icon(
                            Icons.add_shopping_cart_outlined, size: 18),
                        label: Text(
                          _isAddingToList
                              ? 'Checking pantry...'
                              : 'Add Ingredients to Grocery List',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                          disabledForegroundColor: Colors.grey,
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                          side:
                          const BorderSide(color: Color(0xFF2E7D32)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: suggestions.isEmpty || _isSaving || _savedSuccess
                ? null
                : () => _saveFirstSuggestion(suggestions),
            style: ElevatedButton.styleFrom(
              backgroundColor: _savedSuccess ? Colors.grey.shade400 : _green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
                : Text(
              _savedSuccess ? 'Saved ✓' : 'Add to Saved Recipes',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _lightGreen,
              foregroundColor: _green,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Scan Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// SUCCESS BANNER
// ────────────────────────────────────────────────────────────
class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
              color: Color(0xFF2E7D32), shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// INGREDIENT SELECTION TILE
// ────────────────────────────────────────────────────────────
class _ScanIngredientTile extends StatelessWidget {
  final String name;
  final String amount;
  final String unit;
  final bool isSelected;
  final PantryCheckResult pantryCheck;
  final ValueChanged<bool?> onChanged;

  const _ScanIngredientTile({
    required this.name,
    required this.amount,
    required this.unit,
    required this.isSelected,
    required this.pantryCheck,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isPartial = pantryCheck.status == PantryStatus.partial;
    final isCovered = pantryCheck.status == PantryStatus.covered;

    Color dotColor = isCovered
        ? Colors.green
        : isPartial
        ? Colors.orange
        : Colors.grey.shade400;

    return CheckboxListTile(
      value: isSelected,
      onChanged: onChanged,
      activeColor: const Color(0xFF1BAB52),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      title: Row(
        children: [
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          if (isPartial) ...[
            const SizedBox(width: 6),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text('Partial',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [amount, unit].where((s) => s.isNotEmpty).join(' '),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          if (isPartial)
            Text(
              'Buy ${pantryCheck.shortageAmount % 1 == 0 ? pantryCheck.shortageAmount.toInt() : pantryCheck.shortageAmount.toStringAsFixed(1)} $unit more (partial in pantry)',
              style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// RECIPE DETAIL BOTTOM SHEET
// ────────────────────────────────────────────────────────────
class _RecipeDetailSheet extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final bool isSaving;
  final VoidCallback onClose;
  final VoidCallback onSave;

  const _RecipeDetailSheet({
    required this.recipe,
    required this.isSaving,
    required this.onClose,
    required this.onSave,
  });

  bool _hasMetaData() =>
      recipe['prepTime'] != null ||
          recipe['cookTime'] != null ||
          recipe['servings'] != null ||
          recipe['difficultyLevel'] != null ||
          recipe['caloriesPerServing'] != null;

  Widget _metaChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label,
        style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w500)),
  );

  @override
  Widget build(BuildContext context) {
    final ingredients = (recipe['ingredients'] as List<dynamic>?) ?? [];
    final steps = (recipe['steps'] as List<dynamic>?) ?? [];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black26)],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Expanded(
                child: Text(recipe['name'] ?? 'Recipe',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              GestureDetector(
                  onTap: onClose,
                  child: const Icon(Icons.close, color: Colors.black54)),
            ],
          ),

          if (_hasMetaData()) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (recipe['prepTime'] != null)
                  _metaChip('Prep: ${recipe['prepTime']}'),
                if (recipe['cookTime'] != null)
                  _metaChip('Cook: ${recipe['cookTime']}'),
                if (recipe['servings'] != null)
                  _metaChip('Serves: ${recipe['servings']}'),
                if (recipe['difficultyLevel'] != null)
                  _metaChip(recipe['difficultyLevel'].toString()),
                if (recipe['caloriesPerServing'] != null)
                  _metaChip('${recipe['caloriesPerServing']} cal/serving'),
              ],
            ),
          ],

          const SizedBox(height: 16),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((recipe['toolsRequired'] as List<dynamic>?)
                      ?.isNotEmpty ==
                      true) ...[
                    const Text('Tools Required',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: (recipe['toolsRequired'] as List<dynamic>)
                          .map((t) => Chip(
                        label: Text(t.toString(),
                            style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.grey.shade100,
                        visualDensity: VisualDensity.compact,
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (ingredients.isNotEmpty) ...[
                    const Text('Ingredients',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    ...ingredients.map((ing) {
                      final map = ing as Map<String, dynamic>;
                      final amt = map['amount']?.toString() ?? '';
                      final unit = map['unit']?.toString() ?? '';
                      final nm = map['name']?.toString() ?? '';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 8, top: 2),
                            decoration: const BoxDecoration(
                                color: Color(0xFF2E7D32),
                                shape: BoxShape.circle),
                          ),
                          Text(
                            [amt, unit, nm]
                                .where((s) => s.isNotEmpty)
                                .join(' '),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ]),
                      );
                    }),
                    const SizedBox(height: 14),
                  ],

                  if (steps.isNotEmpty) ...[
                    const Text('Steps',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    ...steps.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Center(
                              child: Text('${e.key + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Expanded(
                              child: Text(e.value.toString(),
                                  style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Save Recipe button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: isSaving
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : const Text('Save Recipe',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}