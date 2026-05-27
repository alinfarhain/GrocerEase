import 'package:flutter/material.dart';
import '../models/detected_pantry_item.dart';

class DetectedItemCard extends StatefulWidget {
  final DetectedPantryItem item;
  final VoidCallback onToggle;

  const DetectedItemCard({
    super.key,
    required this.item,
    required this.onToggle,
  });

  @override
  State<DetectedItemCard> createState() => _DetectedItemCardState();
}

class _DetectedItemCardState extends State<DetectedItemCard> {
  late TextEditingController _qtyController;
  bool _isExpanded = false;

  final _units = [
    'pieces', 'kg', 'g', 'L', 'mL',
    'bottles', 'cans', 'boxes', 'bags', 'jars', 'packs',
  ];
  final _storageOptions = ['fridge', 'freezer', 'pantry', 'counter'];

  @override
  void initState() {
    super.initState();
    final q = widget.item.quantity;
    _qtyController = TextEditingController(
      text: q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Color get _confColor {
    final c = widget.item.detectionConfidence;
    if (c >= 0.85) return Colors.green.shade700;
    if (c >= 0.70) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  Color get _confBg {
    final c = widget.item.detectionConfidence;
    if (c >= 0.85) return Colors.green.shade50;
    if (c >= 0.70) return Colors.orange.shade50;
    return Colors.red.shade50;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isSelected
              ? const Color(0xFF2D9A5F)
              : Colors.grey.shade200,
          width: item.isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: widget.onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Checkbox circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: item.isSelected
                          ? const Color(0xFF2D9A5F)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: item.isSelected
                            ? const Color(0xFF2D9A5F)
                            : Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                    child: item.isSelected
                        ? const Icon(Icons.check,
                        color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Name + info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        if (item.brand != null)
                          Text(item.brand!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600),
                          ),
                          if (item.expiryDate != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.calendar_today_outlined,
                                size: 13,
                                color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              _formatExpiry(item.expiryDate!),
                              style: TextStyle(
                                  fontSize: 13,
                                  color:
                                  _expiryColor(item.expiryDate!)),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),

                  // Confidence + expand
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _confBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(item.detectionConfidence * 100).round()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _confColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => setState(
                                () => _isExpanded = !_isExpanded),
                        child: Icon(
                          _isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) _buildEditSection(item),
        ],
      ),
    );
  }

  Widget _buildEditSection(DetectedPantryItem item) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Quantity'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _qtyController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) =>
                    item.quantity = double.tryParse(v) ?? item.quantity,
                    decoration: _inputDeco(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Unit'),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value:
                    _units.contains(item.unit) ? item.unit : 'pieces',
                    decoration: _inputDeco(),
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black87),
                    items: _units
                        .map((u) =>
                        DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => item.unit = v!),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          _label('Storage'),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _storageOptions.contains(item.storageLocation)
                ? item.storageLocation
                : 'pantry',
            decoration: _inputDeco(),
            style:
            const TextStyle(fontSize: 14, color: Colors.black87),
            items: _storageOptions
                .map((s) =>
                DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) =>
                setState(() => item.storageLocation = v!),
          ),
          if (item.storageAdvice != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FBF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.lightbulb_outline,
                    size: 14, color: Color(0xFF2D9A5F)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.storageAdvice!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF2D9A5F)),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(fontSize: 12, color: Colors.grey.shade600));

  InputDecoration _inputDeco() => InputDecoration(
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF2D9A5F)),
    ),
    isDense: true,
  );

  String _formatExpiry(DateTime date) {
    final days = date.difference(DateTime.now()).inDays;
    if (days < 0) return 'Expired';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    if (days < 7) return 'Expires in $days days';
    return 'Expires ${date.day}/${date.month}/${date.year}';
  }

  Color _expiryColor(DateTime date) {
    final days = date.difference(DateTime.now()).inDays;
    if (days <= 0) return Colors.red.shade700;
    if (days <= 3) return Colors.orange.shade700;
    return Colors.grey.shade600;
  }
}