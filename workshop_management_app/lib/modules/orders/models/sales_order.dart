import 'order_item.dart';
import 'payment.dart';

class SalesOrder {
  final int? id;
  final int customerId;
  final DateTime orderDate;
  DateTime? deliveryDate; // Can be nullable
  double totalAmount;    // Calculated from items
  String status;         // e.g., "Pending", "Confirmed", "Awaiting Payment", "Shipped", "Completed", "Cancelled"

  List<OrderItem> items; // Transient, loaded separately
  List<Payment> payments; // Transient, loaded separately

  SalesOrder({
    this.id,
    required this.customerId,
    required this.orderDate,
    this.deliveryDate,
    this.totalAmount = 0.0,
    this.status = 'Pending',
    this.items = const [],
    this.payments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'order_date': orderDate.toIso8601String().substring(0, 10),
      'delivery_date': deliveryDate?.toIso8601String().substring(0, 10),
      'total_amount': totalAmount,
      'status': status,
    };
  }

  factory SalesOrder.fromMap(Map<String, dynamic> map, {List<OrderItem> items = const [], List<Payment> payments = const []}) {
    return SalesOrder(
      id: map['id'],
      customerId: map['customer_id'],
      orderDate: DateTime.parse(map['order_date']),
      deliveryDate: map['delivery_date'] != null ? DateTime.parse(map['delivery_date']) : null,
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Pending',
      items: items,
      payments: payments,
    );
  }

  void calculateTotalAmount() {
    totalAmount = items.fold(0.0, (sum, item) => sum + (item.quantity * item.priceAtSale));
  }

  double get totalPaid {
    return payments.fold(0.0, (sum, payment) => sum + payment.amount);
  }

  double get outstandingAmount {
    return totalAmount - totalPaid;
  }

  @override
  String toString() {
    return 'SalesOrder{id: $id, customerId: $customerId, orderDate: $orderDate, status: $status, totalAmount: $totalAmount}';
  }
}
