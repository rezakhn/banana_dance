class Payment {
  final int? id;
  final int orderId; // Foreign Key to SalesOrder(id)
  final double amount;
  final DateTime paymentDate;
  final String? paymentMethod; // e.g., "Cash", "Card", "Transfer"

  Payment({
    this.id,
    required this.orderId,
    required this.amount,
    required this.paymentDate,
    this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String().substring(0, 10),
      'payment_method': paymentMethod,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      orderId: map['order_id'],
      amount: map['amount']?.toDouble() ?? 0.0,
      paymentDate: DateTime.parse(map['payment_date']),
      paymentMethod: map['payment_method'],
    );
  }

  @override
  String toString() {
    return 'Payment{id: $id, orderId: $orderId, amount: $amount, date: $paymentDate}';
  }
}
