// ─────────────────────────────────────────────────────────────────
//  add_item_sheet.dart  (fixed)
//
//  BEFORE: onAdd only collected (name, quantity, price, category).
//          quantityAmount, unit, and dietaryTags were never gathered,
//          so every newly-added item had empty tags → dietary warnings
//          never fired, and Edit fields were always blank.
//
//  AFTER:  Collects all six fields that GroceryService.addItem expects:
//            name, quantity, quantityAmount, unit, price, category,
//            dietaryTags
//          Dietary tags use toggle chips so the user marks what an item
//          contains (Meat, Seafood, Dairy, Non-Halal…).
//          These tags are what hasDietaryWarningFor() checks, so
//          warnings will now fire correctly for Vegan/Halal/etc.
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class AddItemSheet extends StatefulWidget {
  final List<String> categories;
  final String currencySymbol;

  /// Updated signature — now passes all fields that the DB needs.
  final void Function(
      String name,
      String quantity,
      double? quantityAmount,
      String? unit,
      double price,
      String category,
      List<String> dietaryTags,
      ) onAdd;

  const AddItemSheet({
    super.key,
    required this.categories,
    required this.currencySymbol,
    required this.onAdd,
  });

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _nameController     = TextEditingController();
  final _qtyAmtController   = TextEditingController();   // numeric quantity
  final _unitController     = TextEditingController();   // kg, pcs, L …
  final _priceController    = TextEditingController();
  String? _selectedCategory;
  final _formKey = GlobalKey<FormState>();

  // ── Dietary tag options ────────────────────────────────────────────────────
  // These map directly to what hasDietaryWarningFor() checks (case-insensitive):
  //   'Vegan'       → flags: meat, seafood, dairy
  //   'Vegetarian'  → flags: meat, seafood
  //   'Halal'       → flags: non-halal
  //   'Pescatarian' → flags: meat
  static const _tagOptions = [
    'meat',
    'seafood',
    'dairy',
    'eggs',
    'gluten',
    'non-halal',
    'nuts',
  ];

  // Display labels for chips (Title Case)
  static const _tagLabels = {
    'meat':      'Meat 🥩',
    'seafood':   'Seafood 🦐',
    'dairy':     'Dairy 🥛',
    'eggs':      'Eggs 🥚',
    'gluten':    'Gluten 🌾',
    'non-halal': 'Non-Halal 🚫',
    'nuts':      'Nuts 🥜',
  };

  final Set<String> _selectedTags = {};

  final List<String> _defaultCategories = [
    'Produce',
    'Meat & Seafood',
    'Dry Goods',
    'Dairy',
    'Beverages',
    'Snacks',
    'Frozen',
    'Other',
  ];

  List<String> get _allCategories {
    final all = {..._defaultCategories, ...widget.categories}.toList()..sort();
    return all;
  }

  // ── Computed display quantity string ───────────────────────────────────────
  // Mirrors the logic in the Edit sheet so stored data is consistent.
  String get _quantityString {
    final qty = double.tryParse(_qtyAmtController.text);
    final unit = _unitController.text.trim();
    if (qty == null) return unit.isNotEmpty ? unit : '';
    final qStr = qty == qty.roundToDouble()
        ? qty.round().toString()
        : qty.toStringAsFixed(1);
    return unit.isNotEmpty ? '$qStr $unit' : qStr;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final qty = double.tryParse(_qtyAmtController.text);
      final unit = _unitController.text.trim();
      widget.onAdd(
        _nameController.text.trim(),
        _quantityString,
        qty,
        unit.isNotEmpty ? unit : null,
        double.tryParse(_priceController.text.trim()) ?? 0.0,
        _selectedCategory ?? _allCategories.first,
        _selectedTags.toList(),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyAmtController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ───────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Custom Item',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 20),

              // ── Item name ─────────────────────────────────────────────────
              _buildField(
                controller: _nameController,
                label: 'Item Name',
                hint: 'e.g. Chicken Breast',
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // ── Quantity amount + unit (side by side) ─────────────────────
              Row(children: [
                Expanded(
                  child: _buildField(
                    controller: _qtyAmtController,
                    label: 'Qty Amount',
                    hint: 'e.g. 2',
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _unitController,
                    label: 'Unit',
                    hint: 'kg, pcs, L…',
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // ── Price ─────────────────────────────────────────────────────
              _buildField(
                controller: _priceController,
                label: 'Price (${widget.currencySymbol.trim()})',
                hint: '0.00',
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // ── Category ──────────────────────────────────────────────────
              _buildCategoryDropdown(),
              const SizedBox(height: 16),

              // ── Dietary tags ──────────────────────────────────────────────
              // These are what hasDietaryWarningFor() checks — selecting the
              // correct tags is how dietary warnings get triggered on the list.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This item contains (select all that apply)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _tagOptions.map((tag) {
                      final selected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(
                          _tagLabels[tag] ?? tag,
                          style: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? const Color(0xFF2E7D32)
                                : Colors.grey.shade700,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        selected: selected,
                        onSelected: (val) => setState(() {
                          if (val) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        }),
                        selectedColor: const Color(0xFFE8F5E9),
                        checkmarkColor: const Color(0xFF2E7D32),
                        backgroundColor: const Color(0xFFF5F5F5),
                        side: BorderSide(
                          color: selected
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        showCheckmark: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Submit ────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Add to List',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          hint: Text('Select category',
              style: TextStyle(color: Colors.grey.shade400)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          items: _allCategories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
      ],
    );
  }
}