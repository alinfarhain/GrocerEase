// lib/widgets/grocery_item_tile.dart
// Changes vs previous version:
//   • Shows suggestedPurchaseUnit as subtitle ("Buy: 500g chicken tray")
//   • Shows priceSource as a small badge ("AI Est." / "Estimated" / "User")
//   • Pantry shortage note when pantryShortageAmount is set
//   • In edit mode (onEdit != null): shows delete button to the LEFT of the edit pencil

import 'package:flutter/material.dart';
import '../models/grocery_item.dart';

class GroceryItemTile extends StatelessWidget {
  final GroceryItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final String currencySymbol;
  final String userDietaryPreference;

  /// When non-null, edit mode is active — both delete and edit icons are shown.
  final VoidCallback? onEdit;

  const GroceryItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.currencySymbol,
    required this.userDietaryPreference,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasDietaryWarning = userDietaryPreference.isNotEmpty &&
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
        child:
        const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: item.isChecked ? const Color(0xFFEDF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: hasDietaryWarning
              ? Border.all(
              color: const Color(0xFFE86E28).withValues(alpha: 0.6),
              width: 1.5)
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
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Main row: checkbox + name + price ─────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCheckbox(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildItemName(),
                            const SizedBox(height: 2),
                            // Quantity line
                            Text(
                              item.quantity,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            // ── Suggested purchase unit ───────────────
                            if (item.suggestedPurchaseUnit != null &&
                                item.suggestedPurchaseUnit!.isNotEmpty &&
                                !item.isChecked) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 12,
                                    color: Color(0xFF1BAB52),
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      'Buy: ${item.suggestedPurchaseUnit}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            // ── Pantry shortage note ──────────────────
                            if (item.pantryShortageAmount != null &&
                                !item.isChecked) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      size: 12, color: Colors.orange.shade600),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      'Pantry shortage: ${item.pantryShortageAmount!.toStringAsFixed(1)} ${item.unit ?? ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ── Price column ──────────────────────────────────
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
                          // Price-per-unit (legacy for manually added items)
                          if (item.pricePerUnit(currencySymbol) != null &&
                              item.suggestedPurchaseUnit == null)
                            Text(
                              item.pricePerUnit(currencySymbol)!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          // ── Price source badge ─────────────────────────
                          if (item.priceSource != null &&
                              !item.isChecked) ...[
                            const SizedBox(height: 3),
                            _PriceSourceBadge(source: item.priceSource!),
                          ],

                          // ── Edit mode: delete + edit buttons ──────────
                          if (onEdit != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Delete button (left of pencil)
                                GestureDetector(
                                  onTap: onDelete,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius:
                                      BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.delete_outline,
                                        size: 16,
                                        color: Colors.red.shade600),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Edit (pencil) button
                                GestureDetector(
                                  onTap: onEdit,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius:
                                      BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  // ── Dietary warning chip ───────────────────────────────
                  if (hasDietaryWarning) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 40),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: item.isChecked
            ? const Color(0xFF2E7D32)
            : Colors.transparent,
        border: Border.all(
          color: item.isChecked
              ? const Color(0xFF2E7D32)
              : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: item.isChecked
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : null,
    );
  }

  Widget _buildItemName() {
    return Text(
      item.name,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: item.isChecked
            ? Colors.grey.shade400
            : const Color(0xFF1A1A1A),
        decoration: item.isChecked ? TextDecoration.lineThrough : null,
        decorationColor: Colors.grey.shade400,
      ),
    );
  }
}

// ── Price source badge ────────────────────────────────────────────────────────

class _PriceSourceBadge extends StatelessWidget {
  final String source;

  const _PriceSourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final isAI = source.contains('AI');
    final isUser = source.contains('User');

    final Color bgColor;
    final Color textColor;
    final IconData icon;

    if (isUser) {
      bgColor = const Color(0xFFE3F2FD);
      textColor = const Color(0xFF1565C0);
      icon = Icons.person_outline;
    } else if (isAI) {
      bgColor = const Color(0xFFF3E5F5);
      textColor = const Color(0xFF7B1FA2);
      icon = Icons.auto_awesome_outlined;
    } else {
      bgColor = const Color(0xFFFFF8E1);
      textColor = const Color(0xFFE65100);
      icon = Icons.info_outline;
    }

    final label = isUser
        ? 'User price'
        : isAI
        ? 'AI Est.'
        : 'Est.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
                fontSize: 10, color: textColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}