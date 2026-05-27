import 'package:flutter/material.dart';
import '../../models/detected_pantry_item.dart';
import '../../repositories/pantry_repository.dart';
import '../widgets/detected_item_card.dart';

class ScanResultScreen extends StatefulWidget {
  final List<DetectedPantryItem> detectedItems;

  const ScanResultScreen({super.key, required this.detectedItems});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late List<DetectedPantryItem> _items;
  bool _isSaving = false;
  final _repo = PantryRepository();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.detectedItems);
    _checkDuplicates();
  }

  Future<void> _checkDuplicates() async {
    final names = _items.map((i) => i.itemName).toList();
    final existing = await _repo.findExistingItems(names);
    if (existing.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${existing.join(', ')} already in your pantry',
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int get _selectedCount => _items.where((i) => i.isSelected).length;

  void _toggleItem(DetectedPantryItem item) {
    setState(() => item.isSelected = !item.isSelected);
  }

  void _selectAll() => setState(() {
    for (final item in _items) item.isSelected = true;
  });

  void _deselectAll() => setState(() {
    for (final item in _items) item.isSelected = false;
  });

  Future<void> _addToDatabase() async {
    if (_selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one item')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _repo.addDetectedItems(_items);
      if (!mounted) return;
      Navigator.pop(context, true); // true = refresh pantry list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_selectedCount item(s) added to pantry'),
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
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSuccessBanner(),
            _buildItemsList(),
            _buildTipBar(),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          const Text(
            'Pantry Scan Results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 17, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FBF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB8E8CE)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF5E7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: Color(0xFF2D9A5F), size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_items.length} item${_items.length != 1 ? 's' : ''} detected',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A5C35),
                ),
              ),
              const Text(
                'Select items to add to your pantry',
                style: TextStyle(fontSize: 12, color: Color(0xFF3A8C5C)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Expanded(
      child: Column(
        children: [
          // Detected Items header + select/deselect all
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Detected Items',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _selectedCount == _items.length
                      ? _deselectAll
                      : _selectAll,
                  child: Text(
                    _selectedCount == _items.length
                        ? 'Deselect All'
                        : 'Select All',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2D9A5F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Scrollable cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _items.length,
              itemBuilder: (context, index) => DetectedItemCard(
                item: _items[index],
                onToggle: () => _toggleItem(_items[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFE0A0)),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Tap ∨ on any card to edit quantity, unit, or storage location',
              style: TextStyle(fontSize: 12, color: Color(0xFFAA7700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Add button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving || _selectedCount == 0
                  ? null
                  : _addToDatabase,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D9A5F),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
                  : Text(
                _selectedCount == 0
                    ? 'No items selected'
                    : 'Add $_selectedCount Item${_selectedCount != 1 ? 's' : ''} to Pantry',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Scan again
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Scan Again',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}