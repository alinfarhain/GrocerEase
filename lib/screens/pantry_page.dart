import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'scan_page.dart';
import '../services/pantry_service.dart';

class PantryPage extends StatefulWidget {
  const PantryPage({super.key});

  @override
  State<PantryPage> createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage> {
  bool isPantrySelected = true;

  // Loaded from Supabase
  List<Map<String, dynamic>> _pantryItems = [];
  List<Map<String, dynamic>> _fridgeItems = [];

  bool _isLoading = true;
  bool isEditing = false;
  int? editingIndex;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  DateTime? _editingExpiry;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // ── DATA LOADING ─────────────────────────────────────────────────────────

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final pantry = await PantryService.getItems('pantry');
      final fridge = await PantryService.getItems('fridge');
      if (mounted) {
        setState(() {
          _pantryItems = pantry;
          _fridgeItems = fridge;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load pantry: $e')),
        );
      }
    }
  }

  // ── EXPIRY COLOUR HELPERS ─────────────────────────────────────────────────

  /// Returns the colour for the expiry date text / card border.
  /// • Red    → already expired
  /// • Yellow → expires within 7 days
  /// • Orange → expires within 30 days
  /// • Green  → more than 30 days away
  Color _expiryColour(DateTime? expiry) {
    if (expiry == null) return Colors.grey;
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final expiryDay =
    DateTime(expiry.year, expiry.month, expiry.day);
    final diff = expiryDay.difference(today).inDays;

    if (diff < 0) return const Color(0xFFEF5350);      // red   — expired
    if (diff <= 7) return const Color(0xFFFFB300);     // amber — ≤ 7 days
    if (diff <= 30) return const Color(0xFFFF9800);    // orange — ≤ 30 days
    return const Color(0xFF003D33);                    // normal
  }

  Color _cardBorderColour(DateTime? expiry, bool isCurrentlyEditing) {
    if (isCurrentlyEditing) return const Color(0xFF1BAB52);
    if (expiry == null) return Colors.transparent;
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final expiryDay =
    DateTime(expiry.year, expiry.month, expiry.day);
    final diff = expiryDay.difference(today).inDays;

    if (diff < 0) return const Color(0xFFEF5350);      // red   — expired
    if (diff <= 7) return const Color(0xFFFFB300);     // amber — ≤ 7 days
    if (diff <= 30) return const Color(0xFFFF9800);    // orange — ≤ 30 days
    return Colors.transparent;
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> _addItem() async {
    if (_nameController.text.trim().isEmpty) return;
    try {
      final storageType = isPantrySelected ? 'pantry' : 'fridge';
      final newItem = await PantryService.addItem(
        name       : _nameController.text,
        quantity   : _quantityController.text,
        expiryDate : _editingExpiry,
        storageType: storageType,
      );
      if (mounted) {
        setState(() {
          if (isPantrySelected) {
            _pantryItems.add(newItem);
          } else {
            _fridgeItems.add(newItem);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveEdit(int index) async {
    final items = isPantrySelected ? _pantryItems : _fridgeItems;
    final item = items[index];
    final id = item['id'] as String?;
    if (id == null) return;

    try {
      final updated = await PantryService.updateItem(
        id        : id,
        name      : _nameController.text,
        quantity  : _quantityController.text,
        expiryDate: _editingExpiry,
      );
      if (mounted) {
        setState(() {
          if (isPantrySelected) {
            _pantryItems[index] = updated;
          } else {
            _fridgeItems[index] = updated;
          }
          editingIndex = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(int index) async {
    final items = isPantrySelected ? _pantryItems : _fridgeItems;
    final item = items[index];
    final id = item['id'] as String?;

    // Optimistic remove
    setState(() {
      if (isPantrySelected) {
        _pantryItems.removeAt(index);
      } else {
        _fridgeItems.removeAt(index);
      }
    });

    if (id != null) {
      try {
        await PantryService.deleteItem(id);
      } catch (e) {
        // Re-insert on failure
        if (mounted) {
          setState(() {
            if (isPantrySelected) {
              _pantryItems.insert(index, item);
            } else {
              _fridgeItems.insert(index, item);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete item. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final items = isPantrySelected ? _pantryItems : _fridgeItems;
    final totalItems = _pantryItems.length + _fridgeItems.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pantry',
                            style: TextStyle(
                              fontSize: 28.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003D33),
                            ),
                          ),
                          Text(
                            '$totalItems item${totalItems == 1 ? '' : 's'} tracked',
                            style: const TextStyle(
                                fontSize: 14.0, color: Colors.grey),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          isEditing = !isEditing;
                          editingIndex = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: isEditing
                                ? const Color(0xFF1BAB52)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isEditing
                                    ? Icons.check_circle_outline
                                    : Icons.edit_outlined,
                                size: 18.0,
                                color: isEditing
                                    ? Colors.white
                                    : const Color(0xFF003D33),
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                isEditing ? 'Done' : 'Edit',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isEditing
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
                  const SizedBox(height: 24.0),

                  // ── Pantry / Fridge toggle ──────────────────────────────
                  Container(
                    height: 50.0,
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Row(
                      children: [
                        _buildToggleTab(
                          'Pantry (${_pantryItems.length})',
                          isPantrySelected,
                              () => setState(() {
                            isPantrySelected = true;
                            editingIndex = null;
                          }),
                        ),
                        _buildToggleTab(
                          'Fridge (${_fridgeItems.length})',
                          !isPantrySelected,
                              () => setState(() {
                            isPantrySelected = false;
                            editingIndex = null;
                          }),
                        ),
                      ],
                    ),
                  ),

                  // ── Expiry legend ───────────────────────────────────────
                  const SizedBox(height: 16.0),
                  _buildExpiryLegend(),
                ],
              ),
            ),

            // ── Item list ─────────────────────────────────────────────────
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
                      horizontal: 24.0),
                  itemCount: items.length,
                  itemBuilder: (context, index) => Padding(
                    padding:
                    const EdgeInsets.only(bottom: 16.0),
                    child: _buildItemCard(items[index], index),
                  ),
                ),
              ),
            ),

            // ── Add button ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56.0,
                child: ElevatedButton(
                  onPressed: _showAddItemOptions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1BAB52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0)),
                    elevation: 0.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: Colors.white),
                      const SizedBox(width: 8.0),
                      Text(
                        'Add Item to ${isPantrySelected ? 'Pantry' : 'Fridge'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
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
        onPressed: () => ScanPage.show(context),
        backgroundColor: const Color(0xFFFF7043),
        elevation: 4.0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0)),
        child: const Icon(Icons.qr_code_scanner,
            color: Colors.white, size: 28.0),
      ),
    );
  }

  // ── WIDGETS ───────────────────────────────────────────────────────────────

  Widget _buildToggleTab(
      String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12.0),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF003D33)
                  : Colors.grey,
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11.0, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPantrySelected
                ? Icons.kitchen_outlined
                : Icons.ac_unit_outlined,
            size: 56,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            isPantrySelected
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
    final bool isCurrentlyEditing = isEditing && editingIndex == index;
    final DateTime? expiry = item['expiry'] as DateTime?;
    final borderColour = _cardBorderColour(expiry, isCurrentlyEditing);
    final expiryTextColour = _expiryColour(expiry);

    final String expiryLabel = expiry != null
        ? DateFormat('dd/MM/yyyy').format(expiry)
        : 'No expiry';

    return GestureDetector(
      onTap: isEditing ? null : () => _showItemDetails(item),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: borderColour,
            width: borderColour == Colors.transparent ? 0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── View / Edit mode row ──────────────────────────────────
            if (!isCurrentlyEditing)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003D33),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              item['quantity'],
                              style: const TextStyle(
                                  fontSize: 13.0, color: Colors.grey),
                            ),
                            const Text(
                              ' • ',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              expiryLabel,
                              style: TextStyle(
                                fontSize: 13.0,
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
                  if (isEditing)
                    Row(
                      children: [
                        // Edit icon
                        GestureDetector(
                          onTap: () => setState(() {
                            editingIndex = index;
                            _nameController.text = item['name'];
                            _quantityController.text = item['quantity'];
                            _editingExpiry = item['expiry'] as DateTime?;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE0B2)
                                  .withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit,
                                size: 16.0,
                                color: Color(0xFFFF9800)),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        // Delete icon
                        GestureDetector(
                          onTap: () => _deleteItem(index),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFCDD2)
                                  .withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 16.0,
                                color: Color(0xFFEF5350)),
                          ),
                        ),
                      ],
                    )
                  else
                    const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              )

            // ── Inline edit form ──────────────────────────────────────
            else
              _buildInlineEditForm(item, index),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineEditForm(Map<String, dynamic> item, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Item Name',
            labelStyle: const TextStyle(color: Color(0xFF1BAB52)),
            filled: true,
            fillColor: const Color(0xFFE8F5E9).withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide:
              const BorderSide(color: Color(0xFF1BAB52)),
            ),
          ),
        ),
        const SizedBox(height: 12.0),

        // Quantity
        TextField(
          controller: _quantityController,
          decoration: InputDecoration(
            labelText: 'Quantity',
            labelStyle: const TextStyle(color: Color(0xFF1BAB52)),
            filled: true,
            fillColor: const Color(0xFFE8F5E9).withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide:
              const BorderSide(color: Color(0xFF1BAB52)),
            ),
          ),
        ),
        const SizedBox(height: 12.0),

        // Expiry date picker
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _editingExpiry ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF1BAB52),
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF003D33),
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _editingExpiry = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _editingExpiry != null
                      ? DateFormat('dd/MM/yyyy').format(_editingExpiry!)
                      : 'Expiry Date (Optional)',
                  style: TextStyle(
                    color: _editingExpiry != null
                        ? const Color(0xFF003D33)
                        : Colors.grey,
                  ),
                ),
                const Icon(Icons.calendar_today,
                    size: 16.0, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16.0),

        // Save / Cancel
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    setState(() => editingIndex = null),
                style: OutlinedButton.styleFrom(
                  side:
                  const BorderSide(color: Color(0xFF1BAB52)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                  padding:
                  const EdgeInsets.symmetric(vertical: 12.0),
                ),
                child: const Text('Cancel',
                    style: TextStyle(color: Color(0xFF1BAB52))),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _saveEdit(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1BAB52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                  elevation: 0.0,
                  padding:
                  const EdgeInsets.symmetric(vertical: 12.0),
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

  // ── MODALS ────────────────────────────────────────────────────────────────

  void _showItemDetails(Map<String, dynamic> item) {
    final DateTime? expiry = item['expiry'] as DateTime?;
    final expiryColour = _expiryColour(expiry);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Item Details',
                  style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close,
                        size: 20.0, color: Color(0xFF1BAB52)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            Text(
              item['name'],
              style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003D33)),
            ),
            const SizedBox(height: 4.0),
            Text(
              isPantrySelected ? 'Pantry' : 'Fridge',
              style: const TextStyle(fontSize: 14.0, color: Colors.grey),
            ),
            const SizedBox(height: 24.0),
            _detailRow('Quantity', item['quantity'], null),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(color: Color(0xFFEEEEEE)),
            ),
            _detailRow(
              'Expiry Date',
              expiry != null
                  ? DateFormat('MMMM dd, yyyy').format(expiry)
                  : 'Not set',
              expiryColour,
            ),
            const SizedBox(height: 8.0),
            if (expiry != null) _buildExpiryStatusBadge(expiry),
            const SizedBox(height: 24.0),
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
            const TextStyle(fontSize: 16.0, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF003D33),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryStatusBadge(DateTime expiry) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final diff =
        DateTime(expiry.year, expiry.month, expiry.day)
            .difference(today)
            .inDays;

    String label;
    Color bg;
    Color text;

    if (diff < 0) {
      label = 'Expired ${diff.abs()} day${diff.abs() == 1 ? '' : 's'} ago';
      bg = const Color(0xFFFFEBEE);
      text = const Color(0xFFEF5350);
    } else if (diff == 0) {
      label = 'Expires today!';
      bg = const Color(0xFFFFEBEE);
      text = const Color(0xFFEF5350);
    } else if (diff <= 7) {
      label = 'Expires in $diff day${diff == 1 ? '' : 's'}';
      bg = const Color(0xFFFFF8E1);
      text = const Color(0xFFFFB300);
    } else if (diff <= 30) {
      label = 'Expires in $diff days';
      bg = const Color(0xFFFFF3E0);
      text = const Color(0xFFFF9800);
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12.0,
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
          BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Item to ${isPantrySelected ? 'Pantry' : 'Fridge'}',
                  style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close,
                        size: 20.0, color: Color(0xFF1BAB52)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            _buildOptionCard(
              icon: Icons.edit_outlined,
              iconColor: const Color(0xFF1BAB52),
              iconBgColor: const Color(0xFFE8F5E9),
              title: 'Add Manually',
              subtitle: 'Enter item details manually',
              onTap: () {
                Navigator.pop(context);
                _showAddManuallyForm();
              },
            ),
            const SizedBox(height: 16.0),
            _buildOptionCard(
              icon: Icons.camera_alt_outlined,
              iconColor: const Color(0xFFFF7043),
              iconBgColor: const Color(0xFFFFF3E0),
              title: 'Scan & Recognize',
              subtitle: 'Use camera to identify item',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16.0),
            _buildOptionCard(
              icon: Icons.qr_code_scanner_outlined,
              iconColor: const Color(0xFF1BAB52),
              iconBgColor: const Color(0xFFE8F5E9),
              title: 'Scan Barcode',
              subtitle: 'Scan product barcode',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8.0),
          ],
        ),
      ),
    );
  }

  void _showAddManuallyForm() {
    _nameController.clear();
    _quantityController.clear();
    _editingExpiry = null;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(24.0)),
            ),
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Item Manually',
                      style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003D33)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            size: 20.0, color: Color(0xFF1BAB52)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),

                // Item Name
                const Text('Item Name',
                    style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF003D33))),
                const SizedBox(height: 8.0),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Apples',
                    filled: true,
                    fillColor:
                    const Color(0xFFE8F5E9).withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Quantity
                const Text('Quantity',
                    style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF003D33))),
                const SizedBox(height: 8.0),
                TextField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    hintText: 'e.g., 5 pcs, 500g, 2 kg',
                    filled: true,
                    fillColor:
                    const Color(0xFFE8F5E9).withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Expiry date
                const Text('Expiry Date (Optional)',
                    style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF003D33))),
                const SizedBox(height: 8.0),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF1BAB52),
                            onPrimary: Colors.white,
                            onSurface: Color(0xFF003D33),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setModalState(() => _editingExpiry = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color:
                      const Color(0xFFE8F5E9).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _editingExpiry != null
                              ? DateFormat('dd/MM/yyyy')
                              .format(_editingExpiry!)
                              : 'dd/mm/yyyy',
                          style: TextStyle(
                            color: _editingExpiry != null
                                ? const Color(0xFF003D33)
                                : Colors.grey,
                          ),
                        ),
                        const Icon(Icons.calendar_today,
                            size: 16.0, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 56.0,
                  child: ElevatedButton(
                    onPressed: isSaving ||
                        _nameController.text.trim().isEmpty
                        ? null
                        : () async {
                      setModalState(() => isSaving = true);
                      await _addItem();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1BAB52),
                      disabledBackgroundColor:
                      const Color(0xFF1BAB52).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0)),
                      elevation: 0.0,
                    ),
                    child: isSaving
                        ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5))
                        : Text(
                      'Add Item to ${isPantrySelected ? 'Pantry' : 'Fridge'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                  color: iconBgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24.0),
            ),
            const SizedBox(width: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D33))),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 13.0, color: Colors.grey)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}