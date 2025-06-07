class OrderItem {
  final int? id;
  final int orderId;    // Foreign Key to SalesOrder(id)
  final int productId;  // Foreign Key to Product(id) from Parts module
  final double quantity;
  final double priceAtSale; // Price per unit at the time of sale

  OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.priceAtSale,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'price_at_sale': priceAtSale,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      orderId: map['order_id'],
      productId: map['product_id'],
      quantity: map['quantity']?.toDouble() ?? 0.0,
      priceAtSale: map['price_at_sale']?.toDouble() ?? 0.0,
    );
  }

  double get itemTotal => quantity * priceAtSale;

  @override
  String toString() {
    return 'OrderItem{id: $id, orderId: $orderId, productId: $productId, quantity: $quantity, priceAtSale: $priceAtSale}';
  }
}
