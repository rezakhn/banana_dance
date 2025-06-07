import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(product.name),
        // Potentially add more info later like number of parts if needed
        // subtitle: Text('Some detail about the product...'),
        trailing: onDelete != null ? IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          tooltip: 'Delete Product',
          onPressed: onDelete,
        ) : null,
        onTap: onTap,
      ),
    );
  }
}
