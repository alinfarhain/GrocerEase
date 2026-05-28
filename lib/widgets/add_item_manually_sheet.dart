import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddItemManuallySheet extends StatefulWidget {
  const AddItemManuallySheet({super.key});

  @override
  State<AddItemManuallySheet> createState() => _AddItemManuallySheetState();
}

class _AddItemManuallySheetState extends State<AddItemManuallySheet> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isSaving = false;

  // Controllers
  final _itemNameController = TextEditingController();
  final _brandController    = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _notesController    = TextEditingController();

  // Dropdown values
  String _category        = 'other';
  String _unit            = 'pieces';
  String _usageState      = 'full';
  String _storageLocation = 'pantry';

  // Dates
  DateTime? _purchaseDate;
  DateTime? _expiryDate;

  // ── Options ───────────────────────────────────────────────────────────────

  static const _categories = [
    ('dairy',        '🥛 Dairy'),
    ('produce',      '🥦 Produce'),
    ('meat',         '🥩 Meat'),
    ('seafood',      '🐟 Seafood'),
    ('grains',       '🌾 Grains'),
    ('canned_goods', '🥫 Canned Goods'),
    ('condiments',   '🧴 Condiments'),
    ('beverages',    '🧃 Beverages'),
    ('snacks',       '🍿 Snacks'),
    ('frozen',       '🧊 Frozen'),
    ('spices',       '🌶 Spices'),
    ('baked_goods',  '🍞 Baked Goods'),
    ('other',        '📦 Other'),
  ];

  static const _units = [
    'pieces', 'kg', 'g', 'L', 'mL',
    'bottles', 'cans', 'boxes', 'bags', 'jars', 'packs', 'bunches',
  ];

  static const _usageStates = [
    ('full',        'Full',        Icons.circle),
    ('half',        'Half',        Icons.circle_outlined),
    ('quarter',     'Quarter',     Icons.timelapse),
    ('almost_empty','Almost Empty',Icons.battery_1_bar),
  ];

  static const _storageOptions = [
    ('pantry',  'Pantry',  Icons.kitchen_outlined),
    ('fridge',  'Fridge',  Icons.ac_unit_outlined),
    ('freezer', 'Freezer', Icons.severe_cold_outlined),
    ('counter', 'Counter', Icons.countertops_outlined),
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _itemNameController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _supabase.from('pantry_items').insert({
        'user_id':          userId,
        'item_name':        _itemNameController.text.trim(),
        'brand':            _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        'category':         _category,
        'quantity':         double.tryParse(_quantityController.text) ?? 1,
        'unit':             _unit,
        'usage_state':      _usageState,
        'usage_percent':    _usageStateToPercent(_usageState),
        'storage_location': _storageLocation,
        'purchase_date':    _purchaseDate?.toIso8601String().split('T').first,
        'expiry_date':      _expiryDate?.toIso8601String().split('T').first,
        'notes':            _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'detection_source': 'manual',
        'is_consumed':      false,
      });

      if (!mounted) return;
      Navigator.pop(context, true); // true = refresh list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_itemNameController.text.trim()} added to pantry',
          ),
          backgroundColor: const Color(0xFF2D9A5F),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int _usageStateToPercent(String state) {
    return switch (state) {
      'full'         => 100,
      'half'         => 50,
      'quarter'      => 25,
      'almost_empty' => 10,
      _              => 100,
    };
  }

  // ── Date pickers ──────────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isExpiry}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isExpiry
          ? (_expiryDate ?? now.add(const Duration(days: 7)))
          : (_purchaseDate ?? now),
      firstDate: isExpiry ? now : DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2D9A5F),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isExpiry) {
        _expiryDate = picked;
      } else {
        _purchaseDate = picked;
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                const Text(
                  'Add Item Manually',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003D33),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF2D9A5F),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section: Basic Info ────────────────────────────────
                    _sectionLabel('Basic Info'),
                    const SizedBox(height: 10),

                    _fieldLabel('Item Name *'),
                    const SizedBox(height: 6),
                    _textField(
                      controller: _itemNameController,
                      hint: 'e.g., Milk, Eggs, Chicken Breast',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Item name is required'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    _fieldLabel('Brand (Optional)'),
                    const SizedBox(height: 6),
                    _textField(
                      controller: _brandController,
                      hint: 'e.g., Nestlé, Farm Fresh',
                    ),
                    const SizedBox(height: 14),

                    _fieldLabel('Category'),
                    const SizedBox(height: 6),
                    _dropdownField<String>(
                      value: _category,
                      items: _categories
                          .map((c) => DropdownMenuItem(
                        value: c.$1,
                        child: Text(c.$2),
                      ))
                          .toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),

                    const SizedBox(height: 24),
                    _divider(),
                    const SizedBox(height: 20),

                    // ── Section: Quantity ──────────────────────────────────
                    _sectionLabel('Quantity'),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Amount'),
                              const SizedBox(height: 6),
                              _textField(
                                controller: _quantityController,
                                hint: '1',
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (double.tryParse(v) == null) {
                                    return 'Enter a number';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Unit'),
                              const SizedBox(height: 6),
                              _dropdownField<String>(
                                value: _unit,
                                items: _units
                                    .map((u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u),
                                ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _unit = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _fieldLabel('Fill Level'),
                    const SizedBox(height: 8),
                    _usageStateSelector(),

                    const SizedBox(height: 24),
                    _divider(),
                    const SizedBox(height: 20),

                    // ── Section: Storage ───────────────────────────────────
                    _sectionLabel('Storage'),
                    const SizedBox(height: 10),
                    _storageSelector(),

                    const SizedBox(height: 24),
                    _divider(),
                    const SizedBox(height: 20),

                    // ── Section: Dates ─────────────────────────────────────
                    _sectionLabel('Dates'),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Purchase Date'),
                              const SizedBox(height: 6),
                              _dateTile(
                                date: _purchaseDate,
                                hint: 'Optional',
                                onTap: () => _pickDate(isExpiry: false),
                                onClear: () =>
                                    setState(() => _purchaseDate = null),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Expiry Date'),
                              const SizedBox(height: 6),
                              _dateTile(
                                date: _expiryDate,
                                hint: 'Optional',
                                onTap: () => _pickDate(isExpiry: true),
                                onClear: () =>
                                    setState(() => _expiryDate = null),
                                isExpiry: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _divider(),
                    const SizedBox(height: 20),

                    // ── Section: Notes ─────────────────────────────────────
                    _sectionLabel('Notes'),
                    const SizedBox(height: 10),
                    _textField(
                      controller: _notesController,
                      hint: 'e.g., Opened on Monday, store in airtight container…',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 28),

                    // ── Save button ────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D9A5F),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Add Item to Pantry',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Custom widgets ────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2D9A5F),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF003D33),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      color: Colors.grey.shade100,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF6FBF8),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide: const BorderSide(color: Color(0xFF2D9A5F), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdownField<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF6FBF8),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide:
          const BorderSide(color: Color(0xFF2D9A5F), width: 1.5),
        ),
      ),
    );
  }

  Widget _usageStateSelector() {
    return Row(
      children: _usageStates.map((state) {
        final isSelected = _usageState == state.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _usageState = state.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(
                right: state.$1 == 'almost_empty' ? 0 : 6,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2D9A5F)
                    : const Color(0xFFF6FBF8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2D9A5F)
                      : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    state.$3,
                    size: 18,
                    color: isSelected
                        ? Colors.white
                        : Colors.grey.shade500,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _storageSelector() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 3,
      children: _storageOptions.map((opt) {
        final isSelected = _storageLocation == opt.$1;
        return GestureDetector(
          onTap: () => setState(() => _storageLocation = opt.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFE8F5EE)
                  : const Color(0xFFF6FBF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2D9A5F)
                    : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  opt.$3,
                  size: 18,
                  color: isSelected
                      ? const Color(0xFF2D9A5F)
                      : Colors.grey.shade500,
                ),
                const SizedBox(width: 8),
                Text(
                  opt.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF2D9A5F)
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dateTile({
    required DateTime? date,
    required String hint,
    required VoidCallback onTap,
    required VoidCallback onClear,
    bool isExpiry = false,
  }) {
    final hasDate = date != null;

    // Warn if expiry is close
    Color borderColor = Colors.grey.shade200;
    Color bgColor = const Color(0xFFF6FBF8);
    if (hasDate && isExpiry) {
      final days = date!.difference(DateTime.now()).inDays;
      if (days < 0) {
        borderColor = Colors.red.shade300;
        bgColor = Colors.red.shade50;
      } else if (days <= 7) {
        borderColor = Colors.orange.shade300;
        bgColor = Colors.orange.shade50;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: hasDate
                  ? const Color(0xFF2D9A5F)
                  : Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasDate
                    ? '${date!.day}/${date.month}/${date.year}'
                    : hint,
                style: TextStyle(
                  fontSize: 13,
                  color: hasDate
                      ? const Color(0xFF003D33)
                      : Colors.grey.shade400,
                ),
              ),
            ),
            if (hasDate)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}