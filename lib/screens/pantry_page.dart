import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/scan_page_popup.dart';
import '../services/pantry_service.dart';
import '../screens/pantry_scan_screen.dart';
import '../widgets/add_item_manually_sheet.dart';

class PantryPage extends StatefulWidget {
  const PantryPage({super.key});

  @override
  State<PantryPage> createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage> {
  bool _isPantrySelected = true;

  List<Map<String, dynamic>> _pantryItems = [];
  List<Map<String, dynamic>> _fridgeItems = [];

  bool _isLoading = true;
  bool _isEditing = false;
  int? _editingIndex;

  // Inline-edit controllers
  final _nameCtrl     = TextEditingController();
  final _brandCtrl    = TextEditingController();
  final _quantityCtrl = TextEditingController();
  String _editUnit          = 'pieces';
  String _editUsageState    = 'full';
  String _editStorageLocation = 'pantry';
  DateTime? _editExpiry;

  static const _units = [
    'pieces','kg','g','L','mL',
    'bottles','cans','boxes','bags','jars','packs',
  ];

  static const _storageOptions = [
    ('pantry','Pantry'),('fridge','Fridge'),
    ('freezer','Freezer'),('counter','Counter'),
  ];

  static const _usageStates = [
    ('full','Full'),('half','Half'),
    ('quarter','Quarter'),('almost_empty','Almost Empty'),
  ];

  // ── Category label helper ─────────────────────────────────────────────────

  static const _categoryLabels = {
    'dairy':        '🥛 Dairy',
    'produce':      '🥦 Produce',
    'meat':         '🥩 Meat',
    'seafood':      '🐟 Seafood',
    'grains':       '🌾 Grains',
    'canned_goods': '🥫 Canned',
    'condiments':   '🧴 Condiments',
    'beverages':    '🧃 Beverages',
    'snacks':       '🍿 Snacks',
    'frozen':       '🧊 Frozen',
    'spices':       '🌶 Spices',
    'baked_goods':  '🍞 Baked',
    'other':        '📦 Other',
  };

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final pantry = await PantryService.getItems('pantry');
      final fridge = await PantryService.getItems('fridge');
      if (mounted) {
        setState(() {
          _pantryItems = pantry;
          _fridgeItems = fridge;
          _isLoading   = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Failed to load pantry: $e', isError: true);
      }
    }
  }

  // ── Expiry colour ─────────────────────────────────────────────────────────

  Color _expiryColour(DateTime? expiry) {
    if (expiry == null) return Colors.grey;
    final diff = DateTime(expiry.year, expiry.month, expiry.day)
        .difference(DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day))
        .inDays;
    if (diff < 0) return const Color(0xFFEF5350);
    if (diff <= 7) return const Color(0xFFFFB300);
    if (diff <= 30) return const Color(0xFFFF9800);
    return const Color(0xFF003D33);
  }

  Color _cardBorderColour(DateTime? expiry, bool editing) {
    if (editing) return const Color(0xFF1BAB52);
    if (expiry == null) return Colors.transparent;
    final diff = DateTime(expiry.year, expiry.month, expiry.day)
        .difference(DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day))
        .inDays;
    if (diff < 0) return const Color(0xFFEF5350);
    if (diff <= 7) return const Color(0xFFFFB300);
    if (diff <= 30) return const Color(0xFFFF9800);
    return Colors.transparent;
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> _saveEdit(int index) async {
    final items = _isPantrySelected ? _pantryItems : _fridgeItems;
    final item = items[index];
    final id = item['id'] as String?;
    if (id == null) return;

    final qty = double.tryParse(_quantityCtrl.text) ?? 1.0;

    try {
      final updated = await PantryService.updateItem(
        id:              id,
        itemName:        _nameCtrl.text.trim(),
        brand:           _brandCtrl.text.trim().isEmpty
            ? null : _brandCtrl.text.trim(),
        quantity:        qty,
        unit:            _editUnit,
        usageState:      _editUsageState,
        storageLocation: _editStorageLocation,
        expiryDate:      _editExpiry,
      );
      if (mounted) {
        setState(() {
          if (_isPantrySelected) _pantryItems[index] = updated;
          else _fridgeItems[index] = updated;
          _editingIndex = null;
        });
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to save: $e', isError: true);
    }
  }

  Future<void> _deleteItem(int index) async {
    final items = _isPantrySelected ? _pantryItems : _fridgeItems;
    final item  = items[index];
    final id    = item['id'] as String?;

    setState(() {
      if (_isPantrySelected) _pantryItems.removeAt(index);
      else _fridgeItems.removeAt(index);
    });

    if (id != null) {
      try {
        await PantryService.deleteItem(id);
      } catch (e) {
        if (mounted) {
          setState(() {
            if (_isPantrySelected) _pantryItems.insert(index, item);
            else _fridgeItems.insert(index, item);
          });
          _showSnack('Failed to delete item', isError: true);
        }
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
        isError ? Colors.red.shade700 : const Color(0xFF2D9A5F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _quantityDisplay(Map<String, dynamic> item) {
    final qty  = item['quantity'] as double? ?? 1.0;
    final unit = item['unit'] as String? ?? 'pieces';
    final qtyStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
    return '$qtyStr $unit';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final items      = _isPantrySelected ? _pantryItems : _fridgeItems;
    final totalItems = _pantryItems.length + _fridgeItems.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pantry',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003D33),
                            ),
                          ),
                          Text(
                            '$totalItems item${totalItems == 1 ? '' : 's'} tracked',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _isEditing    = !_isEditing;
                          _editingIndex = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isEditing
                                ? const Color(0xFF1BAB52)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isEditing
                                    ? Icons.check_circle_outline
                                    : Icons.edit_outlined,
                                size: 18,
                                color: _isEditing
                                    ? Colors.white
                                    : const Color(0xFF003D33),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isEditing ? 'Done' : 'Edit',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _isEditing
                                      ? Colors.white
                                      : const Color(0xFF003D33),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Pantry / Fridge toggle
                  Container(
                    height: 50,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _buildToggleTab(
                          'Pantry (${_pantryItems.length})',
                          _isPantrySelected,
                              () => setState(() {
                            _isPantrySelected = true;
                            _editingIndex     = null;
                          }),
                        ),
                        _buildToggleTab(
                          'Fridge (${_fridgeItems.length})',
                          !_isPantrySelected,
                              () => setState(() {
                            _isPantrySelected = false;
                            _editingIndex     = null;
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  _buildExpiryLegend(),
                ],
              ),
            ),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF1BAB52)))
                  : items.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: _loadItems,
                color: const Color(0xFF1BAB52),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24),
                  itemCount: items.length,
                  itemBuilder: (context, index) => Padding(
                    padding:
                    const EdgeInsets.only(bottom: 16),
                    child:
                    _buildItemCard(items[index], index),
                  ),
                ),
              ),
            ),

            // Add button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _showAddItemOptions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1BAB52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Add Item to ${_isPantrySelected ? 'Pantry' : 'Fridge'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const ScanPagePopup(),
        ),
        backgroundColor: const Color(0xFFFF7043),
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.qr_code_scanner,
            color: Colors.white, size: 28),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildToggleTab(
      String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF003D33) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpiryLegend() {
    return Row(
      children: [
        _legendDot(const Color(0xFFEF5350), 'Expired'),
        const SizedBox(width: 12),
        _legendDot(const Color(0xFFFFB300), '≤ 7 days'),
        const SizedBox(width: 12),
        _legendDot(const Color(0xFFFF9800), '≤ 30 days'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration:
          BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isPantrySelected
                ? Icons.kitchen_outlined
                : Icons.ac_unit_outlined,
            size: 56,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _isPantrySelected
                ? 'Your pantry is empty'
                : 'Your fridge is empty',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Item" below to get started',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, int index) {
    final bool isCurrentlyEditing = _isEditing && _editingIndex == index;
    final DateTime? expiry  = item['expiry'] as DateTime?;
    final borderColour      = _cardBorderColour(expiry, isCurrentlyEditing);
    final expiryTextColour  = _expiryColour(expiry);
    final String expiryLabel = expiry != null
        ? DateFormat('dd/MM/yyyy').format(expiry)
        : 'No expiry';
    final String categoryLabel =
        _categoryLabels[item['category']] ?? '📦 Other';
    final usagePercent = item['usage_percent'] as int? ?? 100;

    return GestureDetector(
      onTap: isCurrentlyEditing
          ? null
          : _isEditing
          ? null
          : () => _showItemDetails(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColour,
            width: borderColour == Colors.transparent ? 0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isCurrentlyEditing
            ? _buildInlineEditForm(item, index)
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + brand
                      Text(
                        item['item_name'] as String? ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003D33),
                        ),
                      ),
                      if ((item['brand'] as String?) != null)
                        Text(
                          item['brand'] as String,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      const SizedBox(height: 6),

                      // Quantity • expiry
                      Row(
                        children: [
                          Text(
                            _quantityDisplay(item),
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                          const Text(' • ',
                              style:
                              TextStyle(color: Colors.grey)),
                          Text(
                            expiryLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: expiryTextColour,
                              fontWeight: expiry != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (_isEditing)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          _editingIndex = index;
                          _nameCtrl.text =
                              item['item_name'] as String? ?? '';
                          _brandCtrl.text =
                              item['brand'] as String? ?? '';
                          _quantityCtrl.text =
                              (item['quantity'] as double? ?? 1.0)
                                  .toStringAsFixed(
                                (item['quantity'] as double? ?? 1.0) %
                                    1 ==
                                    0
                                    ? 0
                                    : 1,
                              );
                          _editUnit = item['unit'] as String? ??
                              'pieces';
                          _editUsageState =
                              item['usage_state'] as String? ??
                                  'full';
                          _editStorageLocation =
                              item['storage_location'] as String? ??
                                  'pantry';
                          _editExpiry = item['expiry'] as DateTime?;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE0B2)
                                .withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit,
                              size: 16, color: Color(0xFFFF9800)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _deleteItem(index),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFCDD2)
                                .withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 16, color: Color(0xFFEF5350)),
                        ),
                      ),
                    ],
                  )
                else
                  const Icon(Icons.chevron_right,
                      color: Colors.grey),
              ],
            ),

            // Category badge + usage bar
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FBF5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    categoryLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF2D9A5F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: usagePercent / 100,
                          minHeight: 5,
                          backgroundColor: Colors.grey.shade100,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(
                            usagePercent > 50
                                ? const Color(0xFF2D9A5F)
                                : usagePercent > 20
                                ? const Color(0xFFFF9800)
                                : Colors.red.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$usagePercent%',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineEditForm(Map<String, dynamic> item, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item name
        _editLabel('Item Name'),
        const SizedBox(height: 6),
        _editTextField(_nameCtrl, 'Item name'),
        const SizedBox(height: 10),

        // Brand
        _editLabel('Brand (optional)'),
        const SizedBox(height: 6),
        _editTextField(_brandCtrl, 'Brand'),
        const SizedBox(height: 10),

        // Quantity + unit
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _editLabel('Quantity'),
                  const SizedBox(height: 6),
                  _editTextField(
                    _quantityCtrl, '1',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _editLabel('Unit'),
                  const SizedBox(height: 6),
                  _editDropdown<String>(
                    value: _editUnit,
                    items: _units
                        .map((u) =>
                        DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _editUnit = v!),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Storage location
        _editLabel('Storage'),
        const SizedBox(height: 6),
        _editDropdown<String>(
          value: _editStorageLocation,
          items: _storageOptions
              .map((s) =>
              DropdownMenuItem(value: s.$1, child: Text(s.$2)))
              .toList(),
          onChanged: (v) => setState(() => _editStorageLocation = v!),
        ),
        const SizedBox(height: 10),

        // Usage state
        _editLabel('Fill Level'),
        const SizedBox(height: 6),
        _editDropdown<String>(
          value: _editUsageState,
          items: _usageStates
              .map((s) =>
              DropdownMenuItem(value: s.$1, child: Text(s.$2)))
              .toList(),
          onChanged: (v) => setState(() => _editUsageState = v!),
        ),
        const SizedBox(height: 10),

        // Expiry date
        _editLabel('Expiry Date'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _editExpiry ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF1BAB52),
                    onPrimary: Colors.white,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _editExpiry = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9).withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _editExpiry != null
                      ? DateFormat('dd/MM/yyyy').format(_editExpiry!)
                      : 'No expiry date',
                  style: TextStyle(
                    fontSize: 13,
                    color: _editExpiry != null
                        ? const Color(0xFF003D33)
                        : Colors.grey,
                  ),
                ),
                const Icon(Icons.calendar_today,
                    size: 15, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Save / Cancel
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    setState(() => _editingIndex = null),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1BAB52)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancel',
                    style: TextStyle(color: Color(0xFF1BAB52))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _saveEdit(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1BAB52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Save',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _editLabel(String text) => Text(
    text,
    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
  );

  Widget _editTextField(
      TextEditingController ctrl,
      String hint, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: const Color(0xFFE8F5E9).withOpacity(0.4),
        isDense: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: Color(0xFF1BAB52)),
        ),
      ),
    );
  }

  Widget _editDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      isDense: true,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFE8F5E9).withOpacity(0.4),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: Color(0xFF1BAB52)),
        ),
      ),
    );
  }

  // ── Modals ────────────────────────────────────────────────────────────────

  void _showItemDetails(Map<String, dynamic> item) {
    final DateTime? expiry       = item['expiry'] as DateTime?;
    final DateTime? purchaseDate = item['purchase_date'] as DateTime?;
    final expiryColour           = _expiryColour(expiry);
    final usagePercent           = item['usage_percent'] as int? ?? 100;
    final categoryLabel =
        _categoryLabels[item['category']] ?? '📦 Other';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Item Details',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close,
                        size: 20, color: Color(0xFF1BAB52)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name
            Text(
              item['item_name'] as String? ?? '',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003D33)),
            ),
            if ((item['brand'] as String?) != null)
              Text(
                item['brand'] as String,
                style:
                const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            const SizedBox(height: 6),

            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FBF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                categoryLabel,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2D9A5F),
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),

            // Usage bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: usagePercent / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        usagePercent > 50
                            ? const Color(0xFF2D9A5F)
                            : usagePercent > 20
                            ? const Color(0xFFFF9800)
                            : Colors.red.shade400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$usagePercent% remaining',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _detailRow('Quantity', _quantityDisplay(item), null),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: Color(0xFFEEEEEE)),
            ),
            _detailRow(
              'Storage',
              item['storage_location'] as String? ?? 'pantry',
              null,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: Color(0xFFEEEEEE)),
            ),
            if (purchaseDate != null) ...[
              _detailRow(
                'Purchased',
                DateFormat('dd MMMM yyyy').format(purchaseDate),
                null,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Color(0xFFEEEEEE)),
              ),
            ],
            _detailRow(
              'Expiry Date',
              expiry != null
                  ? DateFormat('MMMM dd, yyyy').format(expiry)
                  : 'Not set',
              expiryColour,
            ),
            if (expiry != null) ...[
              const SizedBox(height: 8),
              _buildExpiryStatusBadge(expiry),
            ],
            if ((item['storage_advice'] as String?) != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FBF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 16, color: Color(0xFF2D9A5F)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['storage_advice'] as String,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF2D9A5F)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if ((item['notes'] as String?) != null) ...[
              const SizedBox(height: 12),
              Text(
                'Notes: ${item['notes']}',
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color? valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
            const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF003D33),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryStatusBadge(DateTime expiry) {
    final today = DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day);
    final diff =
        DateTime(expiry.year, expiry.month, expiry.day)
            .difference(today)
            .inDays;

    String label;
    Color bg;
    Color text;

    if (diff < 0) {
      label = 'Expired ${diff.abs()} day${diff.abs() == 1 ? '' : 's'} ago';
      bg   = const Color(0xFFFFEBEE);
      text = const Color(0xFFEF5350);
    } else if (diff == 0) {
      label = 'Expires today!';
      bg   = const Color(0xFFFFEBEE);
      text = const Color(0xFFEF5350);
    } else if (diff <= 7) {
      label = 'Expires in $diff day${diff == 1 ? '' : 's'}';
      bg   = const Color(0xFFFFF8E1);
      text = const Color(0xFFFFB300);
    } else if (diff <= 30) {
      label = 'Expires in $diff days';
      bg   = const Color(0xFFFFF3E0);
      text = const Color(0xFFFF9800);
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              color: text,
              fontWeight: FontWeight.w600)),
    );
  }

  void _showAddItemOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Item to ${_isPantrySelected ? 'Pantry' : 'Fridge'}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close,
                        size: 20, color: Color(0xFF1BAB52)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Add manually
            _buildOptionCard(
              icon: Icons.edit_outlined,
              iconColor: const Color(0xFF1BAB52),
              iconBgColor: const Color(0xFFE8F5E9),
              title: 'Add Manually',
              subtitle: 'Enter item details manually',
              onTap: () async {
                Navigator.pop(context);
                final added = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AddItemManuallySheet(),
                );
                if (added == true) _loadItems();
              },
            ),
            const SizedBox(height: 16),

            // Scan & Recognize
            _buildOptionCard(
              icon: Icons.camera_alt_outlined,
              iconColor: const Color(0xFFFF7043),
              iconBgColor: const Color(0xFFFFF3E0),
              title: 'Scan & Recognise',
              subtitle: 'Use camera to identify items',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PantryScanScreen(),
                  ),
                ).then((_) => _loadItems());
              },
            ),
            const SizedBox(height: 16),

            // Scan Barcode
            _buildOptionCard(
              icon: Icons.qr_code_scanner_outlined,
              iconColor: const Color(0xFF1BAB52),
              iconBgColor: const Color(0xFFE8F5E9),
              title: 'Scan Barcode',
              subtitle: 'Scan product barcode',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PantryScanScreen(),
                  ),
                ).then((_) => _loadItems());
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: iconBgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003D33))),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}