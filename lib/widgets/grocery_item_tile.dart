// ─────────────────────────────────────────────
//  grocery_item_tile.dart  (updated)
//  Changes:
//   • Accepts [currencySymbol] — fixes the hardcoded "$" inconsistency
//   • Shows price-per-unit below the price when available
//   • Shows a ⚠️ dietary warning chip when item conflicts with user preference
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/grocery_item.dart';

class GroceryItemTile extends StatelessWidget {
  final GroceryItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  /// Currency symbol applied consistently throughout the tile.
  final String currencySymbol;

  /// The user's current dietary preference (from profile).
  /// Pass empty string or 'None' to suppress all warnings.
  final String userDietaryPreference;

  const GroceryItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.currencySymbol,
    required this.userDietaryPreference,
  });

  @override
  Widget build(BuildContext context) {
    final hasDietaryWarning =
        userDietaryPreference.isNotEmpty &&
            userDietaryPreference != 'None' &&
            item.hasDietaryWarningFor(userDietaryPreference);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: item.isChecked ? const Color(0xFFEDF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: hasDietaryWarning
              ? Border.all(color: const Color(0xFFE86E28).withValues(alpha: 0.6), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildCheckbox(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildItemName(),
                            const SizedBox(height: 2),
                            Text(
                              item.quantity,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ── Price column ──────────────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$currencySymbol${item.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: item.isChecked
                                  ? Colors.grey.shade400
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                          // Price per unit (NEW)
                          if (item.pricePerUnit(currencySymbol) != null)
                            Text(
                              item.pricePerUnit(currencySymbol)!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  // ── Dietary warning chip (NEW) ──────────────────
                  if (hasDietaryWarning) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 40), // align under name
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0E8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFFE86E28), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  size: 13, color: Color(0xFFE86E28)),
                              const SizedBox(width: 4),
                              Text(
                                'Not $userDietaryPreference',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFE86E28),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
          item.isChecked ? const Color(0xFF2E7D32) : Colors.transparent,
          border: Border.all(
            color: item.isChecked
                ? const Color(0xFF2E7D32)
                : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: item.isChecked
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      ),
    );
  }

  Widget _buildItemName() {
    return item.isChecked
        ? Text(
      item.name,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade400,
        decoration: TextDecoration.lineThrough,
        decorationColor: Colors.grey.shade400,
      ),
    )
        : Text(
      item.name,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
    );
  }
}
