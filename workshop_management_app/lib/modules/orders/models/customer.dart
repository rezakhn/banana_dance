class Customer {
  final int? id;
  final String name;
  final String contactInfo;

  Customer({
    this.id,
    required this.name,
    this.contactInfo = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact_info': contactInfo,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      contactInfo: map['contact_info'] ?? '',
    );
  }

  @override
  String toString() {
    return 'Customer{id: $id, name: $name, contactInfo: $contactInfo}';
  }
}
