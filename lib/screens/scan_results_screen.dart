import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScanResultsScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  const ScanResultsScreen({super.key, required this.result});

  @override
  State<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends State<ScanResultsScreen> {
  Map<String, dynamic>? _selectedRecipe;

  static const Color _green = Color(0xFF2E7D32);
  static const Color _lightGreen = Color(0xFFE8F5E9);

  bool get _isMeal => widget.result['type'] == 'meal';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16,
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
                    child: const Icon(Icons.close, size: 22, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── CONTENT ─────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _isMeal ? _buildMealResult() : _buildIngredientsResult(),
              ),
            ),
          ],
        ),
      ),

      // ── RECIPE DETAIL BOTTOM SHEET ───────────────
      bottomSheet: _selectedRecipe != null
          ? _RecipeDetailSheet(
        recipe: _selectedRecipe!,
        onClose: () => setState(() => _selectedRecipe = null),
      )
          : null,
    );
  }

  // ── MEAL RESULT UI ───────────────────────────────
  Widget _buildMealResult() {
    final recipe = widget.result['recipe'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success banner
        _SuccessBanner(),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  onPressed: () => setState(() => _selectedRecipe = recipe),
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

        // Action buttons
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Add to Saved Recipes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

  // ── INGREDIENTS RESULT UI ────────────────────────
  Widget _buildIngredientsResult() {
    final ingredients = (widget.result['ingredients'] as List<dynamic>?) ?? [];
    final suggestions =
        (widget.result['recipeSuggestions'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SuccessBanner(),
        const SizedBox(height: 20),

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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      ],
    );
  }
}

// ── SUCCESS BANNER ───────────────────────────────────
class _SuccessBanner extends StatelessWidget {
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

// ── RECIPE DETAIL BOTTOM SHEET ───────────────────────
class _RecipeDetailSheet extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback onClose;

  const _RecipeDetailSheet({required this.recipe, required this.onClose});

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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
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
          const SizedBox(height: 16),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingredients',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...ingredients.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $item',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF444444),
                      ),
                    ),
                  )),
                  const SizedBox(height: 16),
                  const Text(
                    'Steps',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...steps.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '${e.key + 1}. ${e.value}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF444444),
                        height: 1.5,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Recipe',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}