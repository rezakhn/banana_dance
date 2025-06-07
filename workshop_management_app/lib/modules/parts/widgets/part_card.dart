import 'package:flutter/material.dart';
import '../models/part.dart';

class PartCard extends StatelessWidget {
  final Part part;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const PartCard({
    Key? key,
    required this.part,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(part.name),
        subtitle: Text(part.isAssembly ? 'Type: Assembly' : 'Type: Component/Raw Material'),
        trailing: onDelete != null ? IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          tooltip: 'Delete Part',
          onPressed: onDelete,
        ) : null,
        onTap: onTap,
      ),
    );
  }
}
