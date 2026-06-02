import 'package:flutter/material.dart';
import '../../services/recipe_extraction_service.dart';
import '../../services/grocery_service.dart';
import '../../services/pantry_service.dart';
import '../../services/ingredient_pricing_service.dart';
import '../../screens/recipe_view.dart';
import 'scan_written_recipe_sheet.dart';

class ExtractedRecipeResultPage extends StatefulWidget {
  final ExtractedRecipe recipe;

  const ExtractedRecipeResultPage({super.key, required this.recipe});

  @override
  State<ExtractedRecipeResultPage> createState() =>
      _ExtractedRecipeResultPageState();
}

class _ExtractedRecipeResultPageState
    extends State<ExtractedRecipeResultPage> {
  final _service = RecipeExtractionService();
  bool _isSaving = false;
  bool _isSaved = false;
  bool _isAddingToList = false;

  // ── Save to DB ─────────────────────────────────────────────────────────────
  Future<void> _saveRecipe() async {
    if (_isSaved) return;
    setState(() => _isSaving = true);
    try {
      await _service.saveToDatabase(widget.recipe);
      setState(() => _isSaved = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Recipe saved successfully! ✓'),
        backgroundColor: Color(0xFF2E7D32),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Convert ExtractedRecipe → RecipeView map ──────────────────────────────
  Map<String, dynamic> _toRecipeViewMap() {
    final r = widget.recipe;
    return {
      'name': r.title ?? 'Extracted Recipe',
      'image': null,
      'cookTimeMinutes': r.cookTimeMinutes ?? 0,
      'prepTimeMinutes': r.prepTimeMinutes ?? 0,
      'servings': r.servings ?? 2,
      'caloriesPerServing': 0,
      'difficulty': 'Easy',
      'tools': <String>[],
      'ingredients': (r.ingredients ?? []).map((ing) => {
        'name': ing['name']?.toString() ?? '',
        'amount': (ing['quantity'] ?? ing['amount'] ?? '').toString(),
        'unit': ing['unit']?.toString() ?? '',
      }).toList(),
      'instructions': r.instructions ?? <String>[],
      'budget': '0',
      'isFullyLoaded': true,
    };
  }

  // ── Normalise ingredients for the sheet ───────────────────────────────────
  // ExtractedRecipe uses 'quantity'; the sheet expects 'amount'.
  List<dynamic> _normalisedIngredients() {
    return (widget.recipe.ingredients ?? []).map((ing) => {
      'name': ing['name']?.toString() ?? '',
      'amount': (ing['quantity'] ?? ing['amount'] ?? '').toString(),
      'unit': ing['unit']?.toString() ?? '',
    }).toList();
  }

  // ── Ingredient sheet ───────────────────────────────────────────────────────
  Future<void> _showIngredientSheet(List<dynamic> ingredients) async {
    if (ingredients.isEmpty) return;
    setState(() => _isAddingToList = true);

    List<Map<String, dynamic>> pantryItems = [];
    try {
      final pantry = await PantryService.getItems('pantry');
      final fridge = await PantryService.getItems('fridge');
      pantryItems = [...pantry, ...fridge];
    } catch (_) {}

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

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Choose Ingredients',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
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
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w600),
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
                        '$checkedCount of ${ingredients.length} selected',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  // List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      itemCount: ingredients.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final ing = ingredients[i];
                        if (ing is! Map) return const SizedBox.shrink();
                        final name = ing['name']?.toString().trim() ?? '';
                        final amount = ing['amount']?.toString().trim() ?? '';
                        final unit = ing['unit']?.toString().trim() ?? '';
                        return _IngredientTile(
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
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: checkedCount == 0 || _isAddingToList
                                ? null
                                : () async {
                              final sel = <Map<String, dynamic>>[];
                              final checks = <PantryCheckResult>[];
                              for (int i = 0;
                              i < ingredients.length;
                              i++) {
                                if (selected[i]) {
                                  sel.add(Map<String, dynamic>.from(
                                      ingredients[i] as Map));
                                  checks.add(pantryChecks[i]);
                                }
                              }
                              Navigator.pop(ctx);
                              await _addIngredientsToGroceryList(
                                  sel, checks);
                            },
                            icon: _isAddingToList
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                                : const Icon(
                                Icons.add_shopping_cart_outlined,
                                size: 20),
                            label: Text(
                              checkedCount == 0
                                  ? 'No items selected'
                                  : 'Add $checkedCount Ingredient${checkedCount != 1 ? 's' : ''} to List',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
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
                                  borderRadius: BorderRadius.circular(14)),
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

  // ── Add to grocery list ────────────────────────────────────────────────────
  Future<void> _addIngredientsToGroceryList(
      List<Map<String, dynamic>> selectedIngredients,
      List<PantryCheckResult> pantryChecks,
      ) async {
    if (selectedIngredients.isEmpty) return;
    setState(() => _isAddingToList = true);

    final recipeName = widget.recipe.title ?? 'Extracted Recipe';
    int added = 0, skipped = 0, pantrySkipped = 0;

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
            name: name, amount: buyAmount, unit: unit);
      } catch (_) {
        pricing = const PricingResult(
            suggestedPurchaseUnit: '1 pack',
            estimatedPriceMyr: 5.0,
            priceSource: 'Estimated');
      }

      final display = buyAmount == buyAmount.truncateToDouble()
          ? buyAmount.toInt().toString()
          : buyAmount.toStringAsFixed(1);
      final quantity =
      [display, unit].where((s) => s.isNotEmpty).join(' ');

      try {
        await GroceryService.addItem(
          name: name,
          quantity: quantity,
          quantityAmount: buyAmount,
          unit: unit.isNotEmpty ? unit : null,
          price:
          double.parse(pricing.estimatedPriceMyr.toStringAsFixed(2)),
          category: _inferCategory(name),
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
      '🛒 $added ingredient${added == 1 ? '' : 's'} added to your list!';
      color = const Color(0xFF2E7D32);
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _inferCategory(String name) {
    final n = name.toLowerCase();
    if (RegExp(r'chicken|beef|pork|lamb|fish|prawn|shrimp|meat|egg|tofu')
        .hasMatch(n)) return 'Protein';
    if (RegExp(r'milk|cheese|butter|cream|yogurt').hasMatch(n))
      return 'Dairy';
    if (RegExp(r'apple|banana|orange|mango|berry|fruit').hasMatch(n))
      return 'Fruits';
    if (RegExp(
        r'carrot|onion|garlic|potato|tomato|vegetable|spinach|cabbage|pepper|cucumber')
        .hasMatch(n)) return 'Vegetables';
    if (RegExp(r'rice|noodle|pasta|bread|flour|oat|bihun|mee').hasMatch(n))
      return 'Grains';
    if (RegExp(
        r'oil|salt|sugar|sauce|soy|vinegar|spice|chili|cili|pepper|cumin|kicap|sos')
        .hasMatch(n)) return 'Condiments';
    return 'Other';
  }

  Widget _legendDot(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    final hasIngredients =
        r.ingredients != null && r.ingredients!.isNotEmpty;
    final hasInstructions =
        r.instructions != null && r.instructions!.isNotEmpty;
    final normIngredients = _normalisedIngredients();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Extracted Recipe',
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Source badge ────────────────────────────────────────────────
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: r.sourceType == 'url_extract'
                    ? Colors.blue[50]
                    : Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: r.sourceType == 'url_extract'
                        ? Colors.blue[200]!
                        : Colors.green[200]!),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  r.sourceType == 'url_extract'
                      ? Icons.link
                      : Icons.camera_alt_outlined,
                  size: 14,
                  color: r.sourceType == 'url_extract'
                      ? Colors.blue[700]
                      : Colors.green[700],
                ),
                const SizedBox(width: 4),
                Text(
                  r.sourceType == 'url_extract'
                      ? 'Extracted from URL'
                      : 'Extracted from Image',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: r.sourceType == 'url_extract'
                        ? Colors.blue[700]
                        : Colors.green[700],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Recipe title label ──────────────────────────────────────────
            if (r.title != null) ...[
              Text(
                r.title!,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 12),
            ],

            // ── Recipe preview card ─────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card header (description + stat chips)
                  if (r.description != null ||
                      r.prepTimeMinutes != null ||
                      r.cookTimeMinutes != null ||
                      r.servings != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:
                        const Color(0xFF2E7D32).withOpacity(0.08),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (r.description != null) ...[
                            Text(r.description!,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    height: 1.4)),
                          ],
                          if (r.prepTimeMinutes != null ||
                              r.cookTimeMinutes != null ||
                              r.servings != null) ...[
                            const SizedBox(height: 12),
                            Row(children: [
                              if (r.prepTimeMinutes != null)
                                _StatChip(
                                    icon: Icons.timer_outlined,
                                    label: 'Prep',
                                    value: '${r.prepTimeMinutes} min'),
                              if (r.cookTimeMinutes != null) ...[
                                const SizedBox(width: 8),
                                _StatChip(
                                    icon: Icons.local_fire_department_outlined,
                                    label: 'Cook',
                                    value: '${r.cookTimeMinutes} min'),
                              ],
                              if (r.servings != null) ...[
                                const SizedBox(width: 8),
                                _StatChip(
                                    icon: Icons.people_outline,
                                    label: 'Serves',
                                    value: '${r.servings}'),
                              ],
                            ]),
                          ],
                        ],
                      ),
                    ),

                  // Ingredients preview
                  if (hasIngredients) ...[
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Text(
                          'Ingredients (${r.ingredients!.length})',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                    ...r.ingredients!.take(5).map((ing) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: Row(children: [
                        Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: Color(0xFF2E7D32),
                                shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(_formatIngredient(ing),
                                style: const TextStyle(
                                    fontSize: 14))),
                      ]),
                    )),
                    if (r.ingredients!.length > 5)
                      Padding(
                        padding:
                        const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        child: Text(
                            '+ ${r.ingredients!.length - 5} more ingredients...',
                            style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                                fontStyle: FontStyle.italic)),
                      ),
                    const SizedBox(height: 8),
                  ] else
                    const Padding(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: _NotExtracted(label: 'Ingredients')),

                  const Divider(height: 24, indent: 20, endIndent: 20),

                  // Instructions preview
                  if (hasInstructions) ...[
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                          'Instructions (${r.instructions!.length} steps)',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                    ...r.instructions!
                        .take(2)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) => Padding(
                      padding: const EdgeInsets.fromLTRB(
                          20, 4, 20, 4),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius:
                              BorderRadius.circular(11),
                            ),
                            child: Center(
                                child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight:
                                        FontWeight.bold))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(entry.value,
                                  style: const TextStyle(
                                      fontSize: 14),
                                  maxLines: 2,
                                  overflow:
                                  TextOverflow.ellipsis)),
                        ],
                      ),
                    )),
                    if (r.instructions!.length > 2)
                      Padding(
                        padding:
                        const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        child: Text(
                            '+ ${r.instructions!.length - 2} more steps...',
                            style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                                fontStyle: FontStyle.italic)),
                      ),
                  ] else
                    const Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: _NotExtracted(label: 'Instructions')),

                  const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── View Full Recipe (below card, outlined style) ───────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RecipeView(recipe: _toRecipeViewMap()),
                  ),
                ),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('View Full Recipe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Ingredients section ─────────────────────────────────────────
            const Text('Ingredients',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
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
                        normIngredients.isEmpty
                            ? 'No ingredients found'
                            : '${normIngredients.length} ingredient${normIngredients.length != 1 ? 's' : ''} in this recipe',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                  if (normIngredients.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isAddingToList
                            ? null
                            : () =>
                            _showIngredientSheet(normIngredients),
                        icon: _isAddingToList
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2E7D32)),
                        )
                            : const Icon(
                            Icons.add_shopping_cart_outlined,
                            size: 18),
                        label: Text(
                          _isAddingToList
                              ? 'Checking pantry...'
                              : 'Add Ingredients to Grocery List',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                          disabledForegroundColor: Colors.grey,
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(
                              color: Color(0xFF2E7D32)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Add to Saved Recipe ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                (_isSaving || _isSaved) ? null : _saveRecipe,
                icon: _isSaving
                    ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2))
                    : Icon(_isSaved
                    ? Icons.bookmark
                    : Icons.bookmark_border),
                label: Text(_isSaved
                    ? 'Saved to My Recipes ✓'
                    : 'Add to Saved Recipe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  _isSaved ? Colors.grey[200] : Colors.orange[50],
                  foregroundColor: _isSaved
                      ? Colors.grey[600]
                      : Colors.orange[800],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: _isSaved
                            ? Colors.grey[300]!
                            : Colors.orange[200]!),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Scan Again ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const ScanWrittenRecipeSheet(),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.grey[300]!),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatIngredient(Map<String, dynamic> ing) {
    final parts = <String>[];
    if (ing['quantity'] != null) parts.add(ing['quantity'].toString());
    if (ing['amount'] != null && ing['quantity'] == null)
      parts.add(ing['amount'].toString());
    if (ing['unit'] != null) parts.add(ing['unit'].toString());
    if (ing['name'] != null) parts.add(ing['name'].toString());
    return parts.join(' ');
  }
}

// ── Ingredient tile ─────────────────────────────────────────────────────────
class _IngredientTile extends StatelessWidget {
  final String name, amount, unit;
  final bool isSelected;
  final PantryCheckResult pantryCheck;
  final ValueChanged<bool?> onChanged;

  const _IngredientTile({
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
    final dotColor = isCovered
        ? Colors.green
        : isPartial
        ? Colors.orange
        : Colors.grey.shade400;

    return CheckboxListTile(
      value: isSelected,
      onChanged: onChanged,
      activeColor: const Color(0xFF1BAB52),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      title: Row(children: [
        Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600))),
        Container(
            width: 8,
            height: 8,
            decoration:
            BoxDecoration(color: dotColor, shape: BoxShape.circle)),
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
      ]),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
      ]),
    );
  }
}

// ── Stat chip ───────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _StatChip(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 4),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style:
              TextStyle(fontSize: 9, color: Colors.grey[500])),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }
}

// ── Not extracted placeholder ───────────────────────────────────────────────
class _NotExtracted extends StatelessWidget {
  final String label;
  const _NotExtracted({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text('$label not found in source',
            style:
            TextStyle(color: Colors.grey[500], fontSize: 13)),
      ]),
    );
  }
}