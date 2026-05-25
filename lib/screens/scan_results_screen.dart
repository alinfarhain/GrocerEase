import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/recipe_save_service.dart';

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

  static const Color _green = Color(0xFF2E7D32);
  static const Color _lightGreen = Color(0xFFE8F5E9);

  bool get _isMeal => widget.result['type'] == 'meal';

  // ── SAVE MEAL (Add to Saved Recipes on meal page) ─────────
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

  // ── SAVE FROM BOTTOM SHEET (Save Recipe button) ───────────
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

  // ── SAVE FIRST SUGGESTION (Add to Saved Recipes on ingredients page) ──
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

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scan Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(
                      Icons.close,
                      size: 22,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── SCROLLABLE CONTENT ───────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _isMeal
                    ? _buildMealResult()
                    : _buildIngredientsResult(),
              ),
            ),
          ],
        ),
      ),

      // ── RECIPE DETAIL BOTTOM SHEET ───────────────────────
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success banner
        const _SuccessBanner(),
        const SizedBox(height: 20),

        // Label
        const Text(
          'Detected Meal',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Complete recipe found',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.result['confidence'] ?? 0}% confidence',
                  style: const TextStyle(
                    color: _green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Recipe section
        const Text(
          'Recipe',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'View Full Recipe',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Add to Saved Recipes button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving || _savedSuccess ? null : _saveMealRecipe,
            style: ElevatedButton.styleFrom(
              backgroundColor: _savedSuccess ? Colors.grey.shade400 : _green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(
              _savedSuccess ? 'Saved ✓' : 'Add to Saved Recipes',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Scan Again button
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Scan Again',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────
  // INGREDIENTS RESULT
  // ────────────────────────────────────────────────────────
  Widget _buildIngredientsResult() {
    final ingredients =
        (widget.result['ingredients'] as List<dynamic>?) ?? [];
    final suggestions =
        (widget.result['recipeSuggestions'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success banner
        const _SuccessBanner(),
        const SizedBox(height: 20),

        // Detected ingredients label
        const Text(
          'Detected Ingredients',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),

        // Ingredient cards
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
                Text(
                  map['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${map['confidence'] ?? 0}% confidence',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),

        // Recipe suggestions header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recipe Suggestions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _lightGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${suggestions.length} found',
                style: const TextStyle(
                  color: _green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Recipe suggestion cards
        ...suggestions.map((s) {
          final map = s as Map<String, dynamic>;
          return GestureDetector(
            onTap: () => setState(() => _selectedRecipe = map),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                          map['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              map['cookTime'] ?? '',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _lightGreen,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${map['matchPercent'] ?? 0}% match',
                                style: const TextStyle(
                                  color: _green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 24),

        // Add to Saved Recipes button (saves top suggestion)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving || _savedSuccess || suggestions.isEmpty
                ? null
                : () => _saveFirstSuggestion(suggestions),
            style: ElevatedButton.styleFrom(
              backgroundColor: _savedSuccess ? Colors.grey.shade400 : _green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(
              _savedSuccess ? 'Saved ✓' : 'Add to Saved Recipes',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Scan Again button
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Scan Again',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// SUCCESS BANNER WIDGET
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
            color: Color(0xFF2E7D32),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 30),
        ),
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
          // Sheet handle
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

          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  recipe['name'] ?? 'Recipe',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, color: Colors.black54),
              ),
            ],
          ),

          // Meta chips row (prep time, cook time, servings,
          // difficulty, calories)
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
                  _metaChip(
                    '${recipe['caloriesPerServing']} cal/serving',
                  ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Scrollable ingredients + steps
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tools required
                  if ((recipe['toolsRequired'] as List<dynamic>?)
                      ?.isNotEmpty ==
                      true) ...[
                    const Text(
                      'Tools Required',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: (recipe['toolsRequired'] as List<dynamic>)
                          .map((t) => _toolChip(t.toString()))
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Ingredients
                  const Text(
                    'Ingredients',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...ingredients.map(
                        (item) {
                      // Format structured ingredient map into readable string
                      // e.g. { name: Chicken, amount: 1, unit: kg } → "Chicken 1 kg"
                      final String displayText;
                      if (item is Map<String, dynamic>) {
                        final name = item['name']?.toString() ?? '';
                        final amount = item['amount'];
                        final unit = item['unit']?.toString() ?? '';

                        // Format amount: show as int if whole number, decimal if not
                        String amountStr = '';
                        if (amount != null) {
                          final double amountDouble = (amount is num)
                              ? amount.toDouble()
                              : double.tryParse(amount.toString()) ?? 0.0;
                          amountStr = amountDouble == amountDouble.truncateToDouble()
                              ? amountDouble.toInt().toString()
                              : amountDouble.toString();
                        }

                        // Build display: "Chicken 1 kg" or "Salt 1 tsp"
                        final parts = [name, amountStr, unit]
                            .where((s) => s.isNotEmpty && s != '0')
                            .toList();
                        displayText = parts.join(' ');
                      } else {
                        // Fallback for plain strings
                        displayText = item.toString();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                displayText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF444444),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Steps
                  const Text(
                    'Steps',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...steps.asMap().entries.map(
                        (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(right: 10, top: 1),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${e.key + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e.value.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF444444),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Save Recipe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasMetaData() =>
      recipe['prepTime'] != null ||
          recipe['cookTime'] != null ||
          recipe['servings'] != null ||
          recipe['difficultyLevel'] != null ||
          recipe['caloriesPerServing'] != null;

  Widget _metaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2E7D32),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _toolChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE65100),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}