class PurchaseInvoice {
  final int? id;
  final int supplierId; // Foreign key to suppliers table
  final DateTime date;
  double totalAmount; // Calculated from items, but can be stored
  List<PurchaseItem> items;

  PurchaseInvoice({
    this.id,
    required this.supplierId,
    required this.date,
    this.totalAmount = 0.0,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'date': date.toIso8601String().substring(0, 10), // Store date as YYYY-MM-DD
      'total_amount': totalAmount,
    };
  }

  factory PurchaseInvoice.fromMap(Map<String, dynamic> map, List<PurchaseItem> items) {
    return PurchaseInvoice(
      id: map['id'],
      supplierId: map['supplier_id'],
      date: DateTime.parse(map['date']),
      totalAmount: map['total_amount'],
      items: items,
    );
  }

  void calculateTotalAmount() {
    totalAmount = items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  @override
  String toString() {
    return 'PurchaseInvoice{id: $id, supplierId: $supplierId, date: $date, totalAmount: $totalAmount, items: ${items.length}}';
  }
}

class PurchaseItem {
  final int? id;
  final int? invoiceId; // Foreign key to purchase_invoices table
  final String itemName; // For now, using item name directly. Later, this could be a part_id
  final double quantity;
  final double unitPrice;
  late final double totalPrice; // Calculated: quantity * unitPrice

  PurchaseItem({
    this.id,
    this.invoiceId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
  }) {
    totalPrice = quantity * unitPrice;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'item_name': itemName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'],
      invoiceId: map['invoice_id'],
      itemName: map['item_name'],
      quantity: map['quantity'],
      unitPrice: map['unit_price'],
      // totalPrice is calculated in constructor or can be read if stored
    );
  }

  @override
  String toString() {
    return 'PurchaseItem{id: $id, itemName: $itemName, quantity: $quantity, unitPrice: $unitPrice, totalPrice: $totalPrice}';
  }
}
