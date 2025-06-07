class AssemblyOrder {
  final int? id;
  final int partId; // Foreign Key to Part(id) where Part.isAssembly is true (the item to be assembled)
  final double quantityToProduce;
  final DateTime date;
  String status; // e.g., "Pending", "In Progress", "Completed"

  AssemblyOrder({
    this.id,
    required this.partId,
    required this.quantityToProduce,
    required this.date,
    this.status = 'Pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'part_id': partId,
      'quantity_to_produce': quantityToProduce,
      'date': date.toIso8601String().substring(0, 10), // Store date as YYYY-MM-DD
      'status': status,
    };
  }

  factory AssemblyOrder.fromMap(Map<String, dynamic> map) {
    return AssemblyOrder(
      id: map['id'],
      partId: map['part_id'],
      quantityToProduce: map['quantity_to_produce'],
      date: DateTime.parse(map['date']),
      status: map['status'],
    );
  }

  @override
  String toString() {
    return 'AssemblyOrder{id: $id, partId: $partId, quantity: $quantityToProduce, date: $date, status: $status}';
  }
}
