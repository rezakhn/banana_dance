import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:workshop_management_app/shared/widgets/main_layout_scaffold.dart';
import '../controllers/purchase_controller.dart';
import '../models/purchase_invoice.dart';
import '../models/supplier.dart'; // Required for _getSupplierName
import 'purchase_invoice_edit_screen.dart';
import '../widgets/purchase_invoice_card.dart';

class PurchaseInvoiceListScreen extends StatefulWidget {
  const PurchaseInvoiceListScreen({Key? key}) : super(key: key);
  @override
  State<PurchaseInvoiceListScreen> createState() => _PurchaseInvoiceListScreenState();
}

class _PurchaseInvoiceListScreenState extends State<PurchaseInvoiceListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PurchaseController>(context, listen: false).fetchPurchaseInvoices();
      Provider.of<PurchaseController>(context, listen: false).fetchSuppliers();
    });
  }
  String _getSupplierName(BuildContext context, int supplierId) { // Corrected method name from _getCustomerName
    final controller = Provider.of<PurchaseController>(context, listen: false);
    try {
      if (controller.suppliers.isEmpty) {
        return 'ID: $supplierId';
      }
      return controller.suppliers.firstWhere((s) => s.id == supplierId).name;
    } catch (e) {
      return 'Unknown Supplier (ID: $supplierId)';
    }
  }
  @override
  Widget build(BuildContext context) {
    final Widget screenBody = Consumer<PurchaseController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.purchaseInvoices.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage != null && controller.purchaseInvoices.isEmpty) {
          return Center(child: Text('Error: ${controller.errorMessage}'));
        }
        if (controller.purchaseInvoices.isEmpty) {
          return const Center(child: Text('No purchase invoices found. Add one!'));
        }
        return ListView.builder(
          itemCount: controller.purchaseInvoices.length,
          itemBuilder: (context, index) {
            final invoice = controller.purchaseInvoices[index];
            final supplierName = _getSupplierName(context, invoice.supplierId);
            return PurchaseInvoiceCard(
              invoice: invoice,
              supplierName: supplierName,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PurchaseInvoiceEditScreen(invoice: invoice))
                ).then((_) => Provider.of<PurchaseController>(context, listen: false).fetchPurchaseInvoices());
              },
              onDelete: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Confirm Delete'),
                    content: Text('Are you sure you want to delete Purchase Invoice #${invoice.id}?'),
                    actions: [
                      TextButton(child: Text('Cancel'), onPressed: ()=>Navigator.pop(ctx, false)),
                      TextButton(child: Text('Delete'), onPressed: ()=>Navigator.pop(ctx, true))
                    ]
                  )
                );
                if (confirm == true && mounted) {
                    bool success = await controller.deletePurchaseInvoice(invoice.id!);
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
      title: 'Purchase Invoices',
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          tooltip: 'New Purchase Invoice',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PurchaseInvoiceEditScreen())
            ).then((_) => Provider.of<PurchaseController>(context, listen: false).fetchPurchaseInvoices());
          }
        )
      ],
      body: screenBody,
    );
  }
}
