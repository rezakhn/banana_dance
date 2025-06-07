class Part {
  final int? id;
  final String name;
  final bool isAssembly; // true if it's an assembly, false if it's a raw component/material

  Part({
    this.id,
    required this.name,
    required this.isAssembly,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_assembly': isAssembly ? 1 : 0, // Store as INTEGER 0 or 1
    };
  }

  factory Part.fromMap(Map<String, dynamic> map) {
    return Part(
      id: map['id'],
      name: map['name'],
      isAssembly: map['is_assembly'] == 1,
    );
  }

  @override
  String toString() {
    return 'Part{id: $id, name: $name, isAssembly: $isAssembly}';
  }
}
