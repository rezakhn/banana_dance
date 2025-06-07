class ProductPart {
  final int? id;
  final int productId;  // Foreign Key to Product(id)
  final int partId;     // Foreign Key to Part(id) (can be a raw component or an assembly)
  final double quantity; // Quantity of the part needed for one unit of the product

  ProductPart({
    this.id,
    required this.productId,
    required this.partId,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'part_id': partId,
      'quantity': quantity,
    };
  }

  factory ProductPart.fromMap(Map<String, dynamic> map) {
    return ProductPart(
      id: map['id'],
      productId: map['product_id'],
      partId: map['part_id'],
      quantity: map['quantity'],
    );
  }

  @override
  String toString() {
    return 'ProductPart{id: $id, productId: $productId, partId: $partId, quantity: $quantity}';
  }
}
