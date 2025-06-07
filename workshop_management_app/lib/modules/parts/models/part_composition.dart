class PartComposition {
  final int? id;
  final int assemblyId;      // Foreign Key to Part(id) where Part.isAssembly is true
  final int componentPartId; // Foreign Key to Part(id) (can be raw or another assembly)
  final double quantity;      // Quantity of component part needed for one unit of assemblyId

  PartComposition({
    this.id,
    required this.assemblyId,
    required this.componentPartId,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assembly_id': assemblyId,
      'component_part_id': componentPartId,
      'quantity': quantity,
    };
  }

  factory PartComposition.fromMap(Map<String, dynamic> map) {
    return PartComposition(
      id: map['id'],
      assemblyId: map['assembly_id'],
      componentPartId: map['component_part_id'],
      quantity: map['quantity'],
    );
  }

  @override
  String toString() {
    return 'PartComposition{id: $id, assemblyId: $assemblyId, componentPartId: $componentPartId, quantity: $quantity}';
  }
}
