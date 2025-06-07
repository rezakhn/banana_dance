import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/purchase_controller.dart';
import '../models/supplier.dart';
import 'supplier_edit_screen.dart';
import '../widgets/supplier_card.dart'; // Added import

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({Key? key}) : super(key: key);

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PurchaseController>(context, listen: false).fetchSuppliers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupplierEditScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<PurchaseController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.suppliers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage != null && controller.suppliers.isEmpty) {
            return Center(child: Text('Error: ${controller.errorMessage}'));
          }
          if (controller.suppliers.isEmpty) {
            return const Center(child: Text('No suppliers found. Add one!'));
          }

          return ListView.builder(
            itemCount: controller.suppliers.length,
            itemBuilder: (context, index) {
              final supplier = controller.suppliers[index];
              return SupplierCard(
                supplier: supplier,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SupplierEditScreen(supplier: supplier),
                    ),
                  );
                },
                onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: Text('Are you sure you want to delete ${supplier.name}? This might fail if they have associated invoices.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await controller.deleteSupplier(supplier.id!);
                      if (controller.errorMessage != null && mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${controller.errorMessage}')),
                          );
                      }
                    }
                },
              );
            },
          );
        },
      ),
    );
  }
}
