import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../globals/app_state.dart';
import '../models/grocery_item.dart';
import '../widgets/grocery_item_tile.dart';
import '../widgets/progress_card.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/scan_page_popup.dart';
import '../services/grocery_service.dart';

class GroceryListScreen extends StatefulWidget {
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

class _GroceryListScreenState extends State<GroceryListScreen>
    with RouteAware {
  bool _showByRecipe = false;
  bool _isEditMode = false;
  bool _isLoading = true;

  List<Map<String, dynamic>> _rawItems = [];

  // ── Map raw row → GroceryItem ─────────────────────────────────────────────
  GroceryItem _toGroceryItem(Map<String, dynamic> raw) {
    return GroceryItem(
      id: raw['id'] as String,
      name: raw['name'] as String? ?? '',
      quantity: raw['quantity'] as String? ?? '',
      quantityAmount: (raw['quantityAmount'] as num?)?.toDouble(),
      unit: raw['unit'] as String?,
      price: (raw['price'] as num?)?.toDouble() ?? 0.0,
      category: raw['category'] as String? ?? 'Other',
      recipe: raw['recipe'] as String?,
      dietaryTags: List<String>.from(raw['dietaryTags'] ?? []),
      isChecked: raw['isChecked'] as bool? ?? false,
      suggestedPurchaseUnit: raw['suggestedPurchaseUnit'] as String?,
      priceSource: raw['priceSource'] as String?,
      pantryShortageAmount:
      (raw['pantryShortageAmount'] as num?)?.toDouble(),
    );
  }

  // ── Computed categories ───────────────────────────────────────────────────
  List<GroceryCategory> get _categories {
    final map = <String, List<GroceryItem>>{};
    for (final raw in _rawItems) {
      final cat = raw['category'] as String? ?? 'Other';
      map.putIfAbsent(cat, () => []).add(_toGroceryItem(raw));
    }
    return map.entries
        .map((e) => GroceryCategory(name: e.key, items: e.value))
        .toList();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadBudget();
    _loadItems();
  }

  Future<void> _loadBudget() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final row = await Supabase.instance.client
          .from('user_profiles')
          .select('budget')
          .eq('id', userId)
          .maybeSingle();
      if (row != null && mounted) {
        final budget = (row['budget'] as num?)?.toDouble() ?? 400.0;
        AppState.of(context, listen: false).setBudget(budget);
      }
    } catch (_) {}
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await GroceryService.getItems();
      if (mounted) {
        setState(() {
          _rawItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Computed helpers ──────────────────────────────────────────────────────
  List<GroceryItem> get _allItems =>
      _categories.expand((c) => c.items).toList();
  int get _checkedCount => _allItems.where((i) => i.isChecked).length;
  int get _totalCount => _allItems.length;
  int get _remainingCount => _totalCount - _checkedCount;
  double get _spentTotal =>
      _allItems.where((i) => i.isChecked).fold(0.0, (s, i) => s + i.price);
  String get _sym => widget.currency.symbol;
  String get _diet => widget.dietaryPreference;

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

  // ── Mutations ─────────────────────────────────────────────────────────────
  Future<void> _toggleItem(GroceryItem item) async {
    final newVal = !item.isChecked;
    setState(() {
      final idx = _rawItems.indexWhere((r) => r['id'] == item.id);
      if (idx != -1) _rawItems[idx]['isChecked'] = newVal;
    });
    try {
      await GroceryService.toggleChecked(item.id, newVal);
    } catch (_) {
      setState(() {
        final idx = _rawItems.indexWhere((r) => r['id'] == item.id);
        if (idx != -1) _rawItems[idx]['isChecked'] = !newVal;
      });
    }
  }

  Future<void> _deleteItem(GroceryItem item) async {
    final backup = Map<String, dynamic>.from(
        _rawItems.firstWhere((r) => r['id'] == item.id));
    setState(() => _rawItems.removeWhere((r) => r['id'] == item.id));
    try {
      await GroceryService.deleteItem(item.id);
    } catch (_) {
      if (mounted) setState(() => _rawItems.add(backup));
    }
  }

  Future<void> _addItem(
      String name,
      String quantity,
      double? quantityAmount,
      String? unit,
      double price,
      String category,
      List<String> dietaryTags,
      ) async {
    try {
      final newItem = await GroceryService.addItem(
        name: name,
        quantity: quantity,
        quantityAmount: quantityAmount,
        unit: unit,
        price: price,
        category: category,
        dietaryTags: dietaryTags,
      );
      if (mounted) setState(() => _rawItems.add(newItem));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to add item: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  // ── Edit mode ─────────────────────────────────────────────────────────────
  void _toggleEditMode() => setState(() => _isEditMode = !_isEditMode);

  // Delete all currently shopping-checked items
  Future<void> _deleteCheckedItems() async {
    final checkedItems = _allItems.where((i) => i.isChecked).toList();
    if (checkedItems.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text(
            'Delete ${checkedItems.length} checked item${checkedItems.length > 1 ? 's' : ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    for (final item in checkedItems) {
      await _deleteItem(item);
    }
  }

  String _calcPPU(double price, double? qty, String? unit) {
    if (qty == null || qty <= 0 || unit == null || unit.trim().isEmpty) {
      return '';
    }
    return '$_sym${(price / qty).toStringAsFixed(2)} / ${unit.trim()}';
  }

  void _showEditItemSheet(GroceryItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final qtyCtrl =
    TextEditingController(text: item.quantityAmount?.toString() ?? '');
    final unitCtrl = TextEditingController(text: item.unit ?? '');
    final priceCtrl =
    TextEditingController(text: item.price.toStringAsFixed(2));

    final ppuNotifier = ValueNotifier<String>(
        _calcPPU(item.price, item.quantityAmount, item.unit));

    void refreshPPU() {
      final p = double.tryParse(priceCtrl.text) ?? 0;
      final q = double.tryParse(qtyCtrl.text);
      final u = unitCtrl.text.trim();
      ppuNotifier.value = _calcPPU(p, q, u);
    }

    priceCtrl.addListener(refreshPPU);
    qtyCtrl.addListener(refreshPPU);
    unitCtrl.addListener(refreshPPU);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Edit Item',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _editField('Item Name', nameCtrl),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _editField('Amount', qtyCtrl,
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _editField('Unit', unitCtrl,
                          hint: 'e.g. kg, pcs')),
                ],
              ),
              const SizedBox(height: 12),
              _editField('Price ($_sym)', priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true)),
              const SizedBox(height: 6),
              ValueListenableBuilder<String>(
                valueListenable: ppuNotifier,
                builder: (_, ppu, __) => ppu.isEmpty
                    ? const SizedBox.shrink()
                    : Text(
                  'Price per unit: $ppu',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final n = nameCtrl.text.trim();
                    final qty = double.tryParse(qtyCtrl.text) ?? 0;
                    final u = unitCtrl.text.trim();
                    final p = double.tryParse(priceCtrl.text) ?? 0;

                    String newQty;
                    if (qty <= 0) {
                      newQty = item.quantity;
                    } else {
                      final qStr = qty == qty.truncateToDouble()
                          ? qty.round().toString()
                          : qty.toStringAsFixed(1);
                      newQty = u.isNotEmpty ? '$qStr $u' : qStr;
                    }

                    try {
                      final updated = await GroceryService.updateItem(
                        id: item.id,
                        name: n.isNotEmpty ? n : null,
                        quantity: newQty,
                        quantityAmount: qty > 0 ? qty : null,
                        unit: u.isNotEmpty ? u : null,
                        price: p,
                        priceSource: 'User',
                      );
                      if (mounted) {
                        setState(() {
                          final idx = _rawItems
                              .indexWhere((r) => r['id'] == item.id);
                          if (idx != -1) _rawItems[idx] = updated;
                        });
                      }
                    } catch (_) {}
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Save Changes',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField(
      String label,
      TextEditingController ctrl, {
        TextInputType keyboardType = TextInputType.text,
        String? hint,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFF2E7D32), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Share ─────────────────────────────────────────────────────────────────
  void _shareList() {
    final budget = AppState.of(context, listen: false).budget;
    final buf = StringBuffer();
    buf.writeln('🛒 Grocery List');
    buf.writeln('$_remainingCount item(s) remaining\n');
    for (final cat in _categories) {
      if (cat.items.isEmpty) continue;
      buf.writeln('── ${cat.name} ──');
      for (final i in cat.items) {
        final tick = i.isChecked ? '✓' : '☐';
        buf.writeln(
            '$tick ${i.name} (${i.quantity})  $_sym${i.price.toStringAsFixed(2)}');
        if (i.suggestedPurchaseUnit != null) {
          buf.writeln('   Buy: ${i.suggestedPurchaseUnit}');
        }
      }
      buf.writeln();
    }
    final grand =
    _allItems.fold(0.0, (s, i) => s + i.price).toStringAsFixed(2);
    buf.writeln('Total: $_sym$grand');
    buf.writeln(
        'Spent: $_sym${_spentTotal.toStringAsFixed(2)} / Budget: $_sym${budget.toStringAsFixed(2)}');

    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Grocery list copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF2E7D32),
        duration: Duration(seconds: 2),
      ),
    );
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

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F8F3),
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      body: Stack(
        children: [
          // ── Main scrollable content ──────────────────────────────────
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadItems,
              color: const Color(0xFF2E7D32),
              child: Column(children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding:
                    const EdgeInsets.fromLTRB(20, 8, 20, 88),
                    children: [
                      ProgressCard(
                        checkedCount: _checkedCount,
                        totalCount: _totalCount,
                        spentTotal: _spentTotal,
                        budget: AppState.of(context).budget,
                        currencySymbol: _sym,
                      ),
                      const SizedBox(height: 16),
                      _buildToggle(),
                      const SizedBox(height: 16),
                      ...(_showByRecipe
                          ? _buildRecipeList()
                          : _buildCategoryList()),
                    ],
                  ),
                ),
              ]),
            ),
          ),

          // ── Floating Add Custom Item button ──────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _showAddItemSheet,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Add Custom Item',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // ── FAB — opens Smart Scan popup ──────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const ScanPagePopup(),
        ),
        backgroundColor: const Color(0xFFFF7043),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: const Icon(Icons.qr_code_scanner,
            color: Colors.white, size: 28),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Grocery List',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _isEditMode
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _isEditMode
                    ? 'Tap 🗑 to delete · Tap ✏️ to edit'
                    : '$_remainingCount items remaining',
                style: TextStyle(
                  fontSize: 13,
                  color: _isEditMode
                      ? const Color(0xFF2E7D32)
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        _headerBtn(Icons.share_outlined, 'Share', _shareList),
        const SizedBox(width: 8),
        // Delete Selected — visible in edit mode when items are checked
        if (_isEditMode && _checkedCount > 0) ...[
          GestureDetector(
            onTap: _deleteCheckedItems,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_sweep_outlined,
                        size: 18, color: Colors.red.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Delete ($_checkedCount)',
                      style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        _headerBtn(
          _isEditMode ? Icons.check_outlined : Icons.edit_outlined,
          _isEditMode ? 'Done' : 'Edit',
          _toggleEditMode,
          withLabel: true,
          active: _isEditMode,
        ),
      ]),
    );
  }

  Widget _headerBtn(
      IconData icon,
      String label,
      VoidCallback onTap, {
        bool withLabel = false,
        bool active = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        color:
        active ? const Color(0xFF2E7D32) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: active
                ? const Color(0xFF2E7D32)
                : const Color(0xFFCCE5CC)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: withLabel ? 14 : 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 18,
                    color: active
                        ? Colors.white
                        : const Color(0xFF2E7D32)),
                if (withLabel) ...[
                  const SizedBox(width: 4),
                  Text(label,
                      style: TextStyle(
                        color:
                        active ? Colors.white : const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Toggle ────────────────────────────────────────────────────────────────
  Widget _buildToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        _toggleOpt('All Items', Icons.format_list_bulleted, false),
        _toggleOpt('By Recipe', Icons.restaurant_outlined, true),
      ]),
    );
  }

  Widget _toggleOpt(String label, IconData icon, bool isRecipe) {
    final sel = _showByRecipe == isRecipe;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showByRecipe = isRecipe),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: sel ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: sel
                ? [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1))
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color:
                  sel ? const Color(0xFF1A1A1A) : Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    color: sel
                        ? const Color(0xFF1A1A1A)
                        : Colors.grey.shade500,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── List builders ─────────────────────────────────────────────────────────
  List<Widget> _buildCategoryList() {
    final out = <Widget>[];
    for (final cat in _categories) {
      if (cat.items.isEmpty) continue;
      out.add(_sectionHeader(cat.name));
      out.add(const SizedBox(height: 10));
      for (final item in cat.items) {
        out.add(_buildTile(item));
        out.add(const SizedBox(height: 8));
      }
      out.add(const SizedBox(height: 8));
    }
    if (out.isEmpty) {
      out.add(Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: 56, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text('Your grocery list is empty.',
                  style: TextStyle(color: Colors.grey, fontSize: 15)),
              const SizedBox(height: 8),
              Text('Tap + to add items',
                  style:
                  TextStyle(color: Colors.grey[400], fontSize: 13)),
            ],
          ),
        ),
      ));
    }
    return out;
  }

  List<Widget> _buildRecipeList() {
    final out = <Widget>[];
    final recipes = _recipeGroups;
    if (recipes.isEmpty) {
      out.add(Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text('No recipe-linked items yet.',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 15)),
        ),
      ));
      return out;
    }
    for (final recipe in recipes) {
      out.add(_recipeHeader(recipe));
      out.add(const SizedBox(height: 10));
      for (final item in recipe.items) {
        out.add(_buildTile(item));
        out.add(const SizedBox(height: 8));
      }
      out.add(const SizedBox(height: 12));
    }
    return out;
  }

  Widget _recipeHeader(GroceryRecipe recipe) {
    final checked = recipe.items.where((i) => i.isChecked).length;
    final total = recipe.items.length;
    final sub = recipe.items.fold(0.0, (s, i) => s + i.price);
    return Row(children: [
      const Icon(Icons.restaurant_outlined,
          size: 18, color: Color(0xFF2E7D32)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(recipe.name,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E7D32))),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('$checked/$total',
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w600)),
      ),
      const SizedBox(width: 8),
      Text('$_sym${sub.toStringAsFixed(2)}',
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A))),
    ]);
  }

  Widget _sectionHeader(String name) {
    return Text(name,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2E7D32),
            letterSpacing: -0.2));
  }

  Widget _buildTile(GroceryItem item) {
    return GroceryItemTile(
      item: item,
      onToggle: () => _toggleItem(item),
      onDelete: () => _deleteItem(item),
      currencySymbol: _sym,
      userDietaryPreference: _diet,
      onEdit: _isEditMode ? () => _showEditItemSheet(item) : null,
    );
  }
}