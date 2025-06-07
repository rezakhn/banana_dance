import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../controllers/purchase_controller.dart';
import '../models/purchase_invoice.dart';
import '../models/supplier.dart'; // Import Supplier for _getSupplierName
import 'purchase_invoice_edit_screen.dart';
import '../widgets/purchase_invoice_card.dart'; // Added import

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

  String _getSupplierName(BuildContext context, int supplierId) {
    // Ensure listen is false if this is called within build or similar context where rebuilds are frequent.
    // However, for this specific use in itemBuilder, it's better to have suppliers available via Consumer or ensure they are loaded.
    // For simplicity, this assumes suppliers are loaded by initState or a similar mechanism.
    final controller = Provider.of<PurchaseController>(context, listen: false);
    final supplier = controller.suppliers.firstWhere((s) => s.id == supplierId, orElse: () => Supplier(id: supplierId, name: 'Unknown Supplier'));
    return supplier.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PurchaseInvoiceEditScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<PurchaseController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.purchaseInvoices.isEmpty && controller.suppliers.isEmpty) {
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
                    MaterialPageRoute(
                      builder: (context) => PurchaseInvoiceEditScreen(invoice: invoice),
                    ),
                  );
                },
                onDelete: () async {
                     final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: Text('Are you sure you want to delete invoice ID ${invoice.id}?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await controller.deletePurchaseInvoice(invoice.id!);
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
