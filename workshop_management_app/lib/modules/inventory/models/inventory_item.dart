class InventoryItem {
  // In a full system, partId would be a foreign key to a 'parts' table.
  // For now, itemName acts as a unique identifier for the inventory item.
  final String itemName; // PRIMARY KEY
  double quantity;
  double threshold; // For low stock warnings

  InventoryItem({
    required this.itemName,
    required this.quantity,
    this.threshold = 0.0, // Default threshold to 0 if not specified
  });

  Map<String, dynamic> toMap() {
    return {
      'item_name': itemName,
      'quantity': quantity,
      'threshold': threshold,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      itemName: map['item_name'],
      quantity: map['quantity'],
      threshold: map['threshold'],
    );
  }

  @override
  String toString() {
    return 'InventoryItem{itemName: $itemName, quantity: $quantity, threshold: $threshold}';
  }
}
