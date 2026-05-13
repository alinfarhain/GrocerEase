// ─────────────────────────────────────────────
//  grocery_list_screen.dart  (updated)
//  Changes:
//   • "By Recipe" toggle now actually groups & renders items by recipe
//   • Currency symbol passed from AppCurrency (consistent everywhere)
//   • GroceryItemTile now receives currencySymbol & userDietaryPreference
//   • Sample data extended with recipe, unit, quantityAmount, dietaryTags
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/grocery_item.dart';
import '../widgets/grocery_item_tile.dart';
import '../widgets/progress_card.dart';
import '../widgets/add_item_sheet.dart';

class GroceryListScreen extends StatefulWidget {
  /// These two values are fed down from the profile / app state.
  /// In a real app you'd use Provider / Riverpod; here they're passed
  /// as constructor parameters to keep the diff minimal.
  final AppCurrency currency;
  final String dietaryPreference;

  const GroceryListScreen({
    super.key,
    this.currency = const AppCurrency(
        code: 'MYR', symbol: 'RM ', label: 'Malaysian Ringgit (RM)'),
    this.dietaryPreference = 'None',
  });

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  bool _showByRecipe = false;
  final double _budget = 115.00;

  // ── Sample data (extended with recipe / unit / dietaryTags) ──────────
  final List<GroceryCategory> _categories = [
    GroceryCategory(
      name: 'Produce',
      items: [
        GroceryItem(
          id: '1',
          name: 'Tomatoes',
          quantity: '4 pcs',
          quantityAmount: 4,
          unit: 'pcs',
          price: 3.50,
          category: 'Produce',
          recipe: 'Pasta Arrabbiata',
          dietaryTags: ['Vegan', 'Halal'],
        ),
        GroceryItem(
          id: '2',
          name: 'Bell Peppers',
          quantity: '2 pcs',
          quantityAmount: 2,
          unit: 'pcs',
          price: 4.00,
          category: 'Produce',
          recipe: 'Chicken Stir Fry',
          dietaryTags: ['Vegan', 'Halal'],
        ),
        GroceryItem(
          id: '3',
          name: 'Spinach',
          quantity: '1 bunch',
          price: 2.50,
          category: 'Produce',
          recipe: 'Pasta Arrabbiata',
          dietaryTags: ['Vegan', 'Halal'],
          isChecked: true,
        ),
      ],
    ),
    GroceryCategory(
      name: 'Meat & Seafood',
      items: [
        GroceryItem(
          id: '4',
          name: 'Chicken Breast',
          quantity: '500 g',
          quantityAmount: 500,
          unit: 'g',
          price: 7.00,
          category: 'Meat & Seafood',
          recipe: 'Chicken Stir Fry',
          // No Halal tag — will trigger warning for Halal users
          dietaryTags: ['Meat'],
        ),
        GroceryItem(
          id: '5',
          name: 'Salmon Fillet',
          quantity: '2 fillets',
          quantityAmount: 2,
          unit: 'fillets',
          price: 12.00,
          category: 'Meat & Seafood',
          recipe: 'Grilled Salmon',
          dietaryTags: ['Seafood', 'Halal'],
          isChecked: true,
        ),
      ],
    ),
    GroceryCategory(
      name: 'Dry Goods',
      items: [
        GroceryItem(
          id: '6',
          name: 'Pasta',
          quantity: '500 g',
          quantityAmount: 500,
          unit: 'g',
          price: 2.00,
          category: 'Dry Goods',
          recipe: 'Pasta Arrabbiata',
          dietaryTags: ['Vegan', 'Halal'],
        ),
        GroceryItem(
          id: '7',
          name: 'Rice',
          quantity: '2 kg',
          quantityAmount: 2,
          unit: 'kg',
          price: 4.00,
          category: 'Dry Goods',
          recipe: 'Chicken Stir Fry',
          dietaryTags: ['Vegan', 'Halal'],
        ),
        GroceryItem(
          id: '8',
          name: 'Olive Oil',
          quantity: '1 L',
          quantityAmount: 1,
          unit: 'L',
          price: 8.00,
          category: 'Dry Goods',
          recipe: 'Grilled Salmon',
          dietaryTags: ['Vegan', 'Halal'],
          isChecked: true,
        ),
        GroceryItem(
          id: '9',
          name: 'Tortillas',
          quantity: '1 pack',
          price: 3.50,
          category: 'Dry Goods',
          dietaryTags: ['Vegan', 'Halal'],
        ),
      ],
    ),
  ];

  // ── Helpers ───────────────────────────────────────────────────────────
  List<GroceryItem> get _allItems =>
      _categories.expand((c) => c.items).toList();

  int get _checkedCount => _allItems.where((i) => i.isChecked).length;
  int get _totalCount => _allItems.length;
  int get _remainingCount => _totalCount - _checkedCount;

  double get _spentTotal =>
      _allItems.where((i) => i.isChecked).fold(0.0, (s, i) => s + i.price);

  String get _sym => widget.currency.symbol;
  String get _diet => widget.dietaryPreference;

  /// Build recipe groups from the flat item list (NEW).
  List<GroceryRecipe> get _recipeGroups {
    final map = <String, List<GroceryItem>>{};
    for (final item in _allItems) {
      final key = item.recipe ?? 'Other';
      map.putIfAbsent(key, () => []).add(item);
    }
    return map.entries
        .map((e) => GroceryRecipe(name: e.key, items: e.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // ── Mutations ─────────────────────────────────────────────────────────
  void _toggleItem(GroceryItem item) =>
      setState(() => item.isChecked = !item.isChecked);

  void _addItem(
      String name, String quantity, double price, String category) {
    setState(() {
      final newItem = GroceryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        quantity: quantity,
        price: price,
        category: category,
      );
      final cat = _categories.firstWhere(
            (c) => c.name == category,
        orElse: () {
          final newCat = GroceryCategory(name: category, items: []);
          _categories.add(newCat);
          return newCat;
        },
      );
      cat.items.add(newItem);
    });
  }

  void _deleteItem(GroceryItem item) {
    setState(() {
      for (final cat in _categories) {
        cat.items.removeWhere((i) => i.id == item.id);
      }
      _categories.removeWhere((c) => c.items.isEmpty);
    });
  }

  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddItemSheet(
        categories: _categories.map((c) => c.name).toList(),
        currencySymbol: _sym,
        onAdd: _addItem,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 12),
                  ProgressCard(
                    spentTotal: _spentTotal,
                    budget: _budget,
                    checkedCount: _checkedCount,
                    totalCount: _totalCount,
                    currencySymbol: _sym,
                  ),
                  const SizedBox(height: 16),
                  _buildToggle(),
                  const SizedBox(height: 20),
                  // ── Render by category OR by recipe ────────────
                  if (_showByRecipe)
                    ..._buildRecipeList()
                  else
                    ..._buildCategoryList(),
                  const SizedBox(height: 16),
                  _buildAddCustomButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemSheet,
        backgroundColor: const Color(0xFFE86E28),
        shape: const CircleBorder(),
        elevation: 4,
        child:
        const Icon(Icons.crop_free, color: Colors.white, size: 26),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grocery List',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_remainingCount items remaining',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          _headerButton(Icons.share_outlined, 'Share'),
          const SizedBox(width: 8),
          _headerButton(Icons.edit_outlined, 'Edit', withLabel: true),
        ],
      ),
    );
  }

  Widget _headerButton(IconData icon, String label,
      {bool withLabel = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border:
        Border.all(color: const Color(0xFFCCE5CC), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: withLabel ? 14 : 10,
              vertical: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
                if (withLabel) ...[
                  const SizedBox(width: 4),
                  const Text(
                    'Edit',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Toggle ────────────────────────────────────────────────────────────
  Widget _buildToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _toggleOption('All Items', Icons.format_list_bulleted, false),
          _toggleOption('By Recipe', Icons.restaurant_outlined, true),
        ],
      ),
    );
  }

  Widget _toggleOption(String label, IconData icon, bool isRecipe) {
    final isSelected = _showByRecipe == isRecipe;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showByRecipe = isRecipe),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? const Color(0xFF1A1A1A)
                    : Colors.grey.shade500,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF1A1A1A)
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Category list (unchanged logic, updated tile params) ──────────────
  List<Widget> _buildCategoryList() {
    final widgets = <Widget>[];
    for (final category in _categories) {
      if (category.items.isEmpty) continue;
      widgets.add(_buildSectionHeader(category.name));
      widgets.add(const SizedBox(height: 10));
      for (final item in category.items) {
        widgets.add(_buildTile(item));
        widgets.add(const SizedBox(height: 8));
      }
      widgets.add(const SizedBox(height: 8));
    }
    return widgets;
  }

  // ── Recipe list (NEW — fixes the broken "By Recipe" toggle) ──────────
  List<Widget> _buildRecipeList() {
    final widgets = <Widget>[];
    final recipes = _recipeGroups;

    if (recipes.isEmpty) {
      widgets.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              'No recipe-linked items yet.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ),
        ),
      );
      return widgets;
    }

    for (final recipe in recipes) {
      // Recipe header with item count badge
      widgets.add(_buildRecipeHeader(recipe));
      widgets.add(const SizedBox(height: 10));
      for (final item in recipe.items) {
        widgets.add(_buildTile(item));
        widgets.add(const SizedBox(height: 8));
      }
      widgets.add(const SizedBox(height: 12));
    }
    return widgets;
  }

  Widget _buildRecipeHeader(GroceryRecipe recipe) {
    final checkedInRecipe = recipe.items.where((i) => i.isChecked).length;
    final totalInRecipe = recipe.items.length;
    final recipeTotal =
    recipe.items.fold(0.0, (s, i) => s + i.price);

    return Row(
      children: [
        const Icon(Icons.restaurant_outlined,
            size: 18, color: Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            recipe.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E7D32),
              letterSpacing: -0.2,
            ),
          ),
        ),
        // Checked count
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$checkedInRecipe/$totalInRecipe',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Recipe subtotal
        Text(
          '$_sym${recipeTotal.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String name) {
    return Text(
      name,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2E7D32),
        letterSpacing: -0.2,
      ),
    );
  }

  /// Single tile factory — passes currency & dietary pref consistently.
  Widget _buildTile(GroceryItem item) {
    return GroceryItemTile(
      item: item,
      onToggle: () => _toggleItem(item),
      onDelete: () => _deleteItem(item),
      currencySymbol: _sym,
      userDietaryPreference: _diet,
    );
  }

  // ── Add custom button ─────────────────────────────────────────────────
  Widget _buildAddCustomButton() {
    return GestureDetector(
      onTap: _showAddItemSheet,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: const Color(0xFF2E7D32), size: 22),
            const SizedBox(width: 8),
            const Text(
              'Add Custom Item',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
