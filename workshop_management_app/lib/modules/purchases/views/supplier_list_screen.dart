import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management_app/shared/widgets/main_layout_scaffold.dart';
import '../controllers/purchase_controller.dart';
import '../models/supplier.dart';
import 'supplier_edit_screen.dart';
import '../widgets/supplier_card.dart';

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
    final Widget screenBody = Consumer<PurchaseController>(
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
                  MaterialPageRoute(builder: (context) => SupplierEditScreen(supplier: supplier))
                ).then((_) => Provider.of<PurchaseController>(context, listen: false).fetchSuppliers());
              },
              onDelete: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Confirm Delete'),
                    content: Text('Are you sure you want to delete ${supplier.name}? This may fail if the supplier has associated invoices.'),
                    actions: [
                      TextButton(child: Text('Cancel'), onPressed: ()=>Navigator.pop(ctx, false)),
                      TextButton(child: Text('Delete'), onPressed: ()=>Navigator.pop(ctx, true))
                    ]
                  )
                );
                if (confirm == true && mounted) {
                    bool success = await controller.deleteSupplier(supplier.id!);
                    if (!success && mounted && controller.errorMessage != null) {
                         ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${controller.errorMessage}')),
                          );
                    }
                }
              }
            );
          }
        );
      }
    );
    return MainLayoutScaffold(
      title: 'Suppliers',
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          tooltip: 'Add Supplier',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SupplierEditScreen())
            ).then((_) => Provider.of<PurchaseController>(context, listen: false).fetchSuppliers());
          }
        )
      ],
      body: screenBody,
    );
  }
}
