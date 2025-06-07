class Product {
  final int? id;
  final String name; // Name of the final sellable product

  Product({
    this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
    );
  }

  @override
  String toString() {
    return 'Product{id: $id, name: $name}';
  }
}
