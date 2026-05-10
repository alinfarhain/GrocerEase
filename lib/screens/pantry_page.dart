import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'scan_page.dart';

class PantryPage extends StatefulWidget {
  const PantryPage({super.key});

  @override
  State<PantryPage> createState() {
    return _PantryPageState();
  }
}

class _PantryPageState extends State<PantryPage> {
  bool isPantrySelected = true;

  final List<Map<String, dynamic>> _pantryItems = [
    {'name': 'Rice', 'quantity': '2 kg', 'expiry': DateTime(2026, 12, 25)},
    {'name': 'Pasta', 'quantity': '500 g', 'expiry': DateTime(2026, 6, 30)},
    {
      'name': 'Olive Oil',
      'quantity': '1 bottle',
      'expiry': DateTime(2026, 12, 10),
    },
    {
      'name': 'Canned Tomatoes',
      'quantity': '4 cans',
      'expiry': DateTime(2024, 12, 31),
    },
  ];

  final List<Map<String, dynamic>> _fridgeItems = [
    {'name': 'Milk', 'quantity': '1 L', 'expiry': DateTime(2024, 12, 25)},
    {'name': 'Cheese', 'quantity': '200 g', 'expiry': DateTime(2024, 12, 30)},
    {'name': 'Eggs', 'quantity': '12 pcs', 'expiry': DateTime(2024, 12, 28)},
    {
      'name': 'Bell Peppers',
      'quantity': '3 pcs',
      'expiry': DateTime(2024, 12, 24),
    },
  ];

  bool isEditing = false;

  int? editingIndex;

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _quantityController = TextEditingController();

  DateTime? _editingExpiry;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Widget _buildEditingForm(Map<String, dynamic> item, int index) {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
          ),
        ),
        const SizedBox(height: 12.0),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _editingExpiry ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    setState(() {
                      _editingExpiry = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _editingExpiry != null
                            ? DateFormat('dd/MM/yyyy').format(_editingExpiry!)
                            : 'dd/mm/yyyy',
                        style: const TextStyle(color: Color(0xFF003D33)),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        size: 16.0,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                final updatedItem = {
                  'name': _nameController.text,
                  'quantity': _quantityController.text,
                  'expiry': _editingExpiry ?? item['expiry'],
                };
                if (isPantrySelected) {
                  _pantryItems[index] = updatedItem;
                } else {
                  _fridgeItems[index] = updatedItem;
                }
                editingIndex = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1BAB52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 0.0,
              padding: const EdgeInsets.symmetric(vertical: 14.0),
            ),
            child: const Text(
              'Save Changes',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
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
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
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
                    color: Color(0xFF003D33),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20.0,
                      color: Color(0xFF1BAB52),
                    ),
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
              onTap: () {},
            ),
            const SizedBox(height: 16.0),
            _buildOptionCard(
              icon: Icons.qr_code_scanner_outlined,
              iconColor: const Color(0xFF1BAB52),
              iconBgColor: const Color(0xFFE8F5E9),
              title: 'Scan Barcode',
              subtitle: 'Scan product barcode',
              onTap: () {},
            ),
            const SizedBox(height: 24.0),
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
    required void Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddManuallyForm() {
    _nameController.clear();
    _quantityController.clear();
    _editingExpiry = null;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Item Manually',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20.0,
                        color: Color(0xFF1BAB52),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              const Text(
                'Item Name',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF003D33),
                ),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Apples',
                  filled: true,
                  fillColor: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Quantity',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF003D33),
                ),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  hintText: 'e.g., 5 pcs, 500g, 2 kg',
                  filled: true,
                  fillColor: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Expiry Date (Optional)',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF003D33),
                ),
              ),
              const SizedBox(height: 8.0),
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    setModalState(() {
                      _editingExpiry = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _editingExpiry != null
                            ? DateFormat('dd/MM/yyyy').format(_editingExpiry!)
                            : 'dd/mm/yyyy',
                        style: const TextStyle(color: Color(0xFF003D33)),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        size: 16.0,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                height: 56.0,
                child: ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty) {
                      setState(() {
                        final newItem = {
                          'name': _nameController.text,
                          'quantity': _quantityController.text,
                          'expiry': _editingExpiry ?? DateTime.now(),
                        };
                        if (isPantrySelected) {
                          _pantryItems.add(newItem);
                        } else {
                          _fridgeItems.add(newItem);
                        }
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF1BAB52,
                    ).withValues(alpha: 0.5),
                    disabledBackgroundColor: const Color(
                      0xFF1BAB52,
                    ).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 0.0,
                  ),
                  child: Text(
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
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    final DateTime expiry = item['expiry'];
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime oneMonthFromNow = today.add(const Duration(days: 30));
    Color expiryColor = const Color(0xFF003D33);
    if (expiry.isBefore(today)) {
      expiryColor = const Color(0xFFEF5350);
    } else if (expiry.isBefore(oneMonthFromNow)) {
      expiryColor = const Color(0xFFFF9800);
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
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
                    color: Color(0xFF003D33),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20.0,
                      color: Color(0xFF1BAB52),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32.0),
            Text(
              item['name'],
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003D33),
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              isPantrySelected ? 'Pantry' : 'Fridge',
              style: const TextStyle(fontSize: 14.0, color: Colors.grey),
            ),
            const SizedBox(height: 32.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quantity',
                  style: TextStyle(fontSize: 16.0, color: Colors.grey),
                ),
                Text(
                  item['quantity'],
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF003D33),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(color: Color(0xFFEEEEEE)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Expiry Date',
                  style: TextStyle(fontSize: 16.0, color: Colors.grey),
                ),
                Text(
                  DateFormat('MMMM dd, yyyy').format(expiry),
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: expiryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  @override
  Widget _buildItemCard(Map<String, dynamic> item, int index) {
    final bool isCurrentlyEditing = isEditing && editingIndex == index;
    final DateTime expiry = item['expiry'];
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime oneMonthFromNow = today.add(const Duration(days: 30));
    Color borderColor = isCurrentlyEditing
        ? const Color(0xFF1BAB52)
        : Colors.black;
    Color expiryColor = Colors.black;
    FontWeight fontWeight = FontWeight.normal;
    if (!isCurrentlyEditing) {
      if (expiry.isBefore(today)) {
        borderColor = const Color(0xFFEF5350);
        expiryColor = const Color(0xFFEF5350);
        fontWeight = FontWeight.w600;
      } else if (expiry.isBefore(oneMonthFromNow)) {
        borderColor = const Color(0xFFFF9800);
        expiryColor = const Color(0xFFFF9800);
        fontWeight = FontWeight.w600;
      } else {
        borderColor = Colors.black.withValues(alpha: 0.05);
      }
    }
    return GestureDetector(
      onTap: () {
        if (!isEditing) {
          _showItemDetails(item);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8.0,
              offset: const Offset(0.0, 4.0),
            ),
          ],
        ),
        child: isCurrentlyEditing
            ? _buildEditingForm(item, index)
            : Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Text(
                        item['quantity'],
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      const Text(
                        '•',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        DateFormat('dd/MM/yyyy').format(expiry),
                        style: TextStyle(
                          fontSize: 14.0,
                          color: expiryColor,
                          fontWeight: fontWeight,
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
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        editingIndex = index;
                        _nameController.text = item['name'];
                        _quantityController.text = item['quantity'];
                        _editingExpiry = item['expiry'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFFFE0B2,
                        ).withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16.0,
                        color: Color(0xFFFF9800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isPantrySelected) {
                          _pantryItems.removeAt(index);
                        } else {
                          _fridgeItems.removeAt(index);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFFFCDD2,
                        ).withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16.0,
                        color: Color(0xFFEF5350),
                      ),
                    ),
                  ),
                ],
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pantry',
                        style: TextStyle(
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003D33),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isEditing = !isEditing;
                            editingIndex = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: isEditing
                                ? const Color(0xFF1BAB52)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isEditing ? Icons.save : Icons.edit_outlined,
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
                  const SizedBox(height: 4.0),
                  Text(
                    '${totalItems} items tracked',
                    style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                  ),
                  const SizedBox(height: 24.0),
                  Container(
                    height: 50.0,
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => isPantrySelected = true),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isPantrySelected
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8.0),
                                boxShadow: isPantrySelected
                                    ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.05,
                                    ),
                                    blurRadius: 4.0,
                                    offset: const Offset(0.0, 2.0),
                                  ),
                                ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Pantry (${_pantryItems.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isPantrySelected
                                      ? const Color(0xFF003D33)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => isPantrySelected = false),
                            child: Container(
                              decoration: BoxDecoration(
                                color: !isPantrySelected
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8.0),
                                boxShadow: !isPantrySelected
                                    ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.05,
                                    ),
                                    blurRadius: 4.0,
                                    offset: const Offset(0.0, 2.0),
                                  ),
                                ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Fridge (${_fridgeItems.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: !isPantrySelected
                                      ? const Color(0xFF003D33)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildItemCard(item, index),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56.0,
                child: ElevatedButton(
                  onPressed: () => _showAddItemOptions(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1BAB52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
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
        onPressed: () {
          ScanPage.show(context);
        },
        backgroundColor: const Color(0xFFFF7043),
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: const Icon(
          Icons.qr_code_scanner,
          color: Colors.white,
          size: 28.0,
        ),
      ),
    );
  }
}
