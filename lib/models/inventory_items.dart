class InventoryItem {
  int? id;
  String name;
  String? category; // NEW FIELD
  double sellingPrice;
  double originalPrice;
  int stock;
  String? imagePath;

  InventoryItem({
    this.id,
    required this.name,
    this.category,
    required this.sellingPrice,
    required this.originalPrice,
    required this.stock,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'sellingPrice': sellingPrice,
      'originalPrice': originalPrice,
      'stock': stock,
      'imagePath': imagePath,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      name: map['name'] ?? 'Unknown Item',
      category: map['category'] ?? 'General', // Default to General if null
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (map['originalPrice'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      imagePath: map['imagePath'],
    );
  }
}