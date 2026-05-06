class GroceryItem {
  final String id;
  final String name;
  final String quantity;
  final double price;
  final String category;
  bool isChecked;

  GroceryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.category,
    this.isChecked = false,
  });
}

class GroceryCategory {
  final String name;
  final List<GroceryItem> items;

  GroceryCategory({
    required this.name,
    required this.items,
  });
}
