import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/purchase_controller.dart';
import '../models/purchase_invoice.dart';
import '../models/supplier.dart';

class PurchaseInvoiceEditScreen extends StatefulWidget {
  final PurchaseInvoice? invoice;

  const PurchaseInvoiceEditScreen({Key? key, this.invoice}) : super(key: key);

  @override
  State<PurchaseInvoiceEditScreen> createState() => _PurchaseInvoiceEditScreenState();
}

class _PurchaseInvoiceEditScreenState extends State<PurchaseInvoiceEditScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedSupplierId;
  DateTime _selectedDate = DateTime.now();
  List<PurchaseItem> _items = [];
  late TextEditingController _dateController;

  // For adding new items
  final _itemNameController = TextEditingController();
  final _itemQuantityController = TextEditingController();
  final _itemUnitPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: DateFormat.yMMMd().format(_selectedDate));
    Provider.of<PurchaseController>(context, listen: false).fetchSuppliers(); // Ensure suppliers are loaded

    if (widget.invoice != null) {
      _selectedSupplierId = widget.invoice!.supplierId;
      _selectedDate = widget.invoice!.date;
      _dateController.text = DateFormat.yMMMd().format(_selectedDate);
      _items = List<PurchaseItem>.from(widget.invoice!.items.map((item) => PurchaseItem( // Create deep copies for editing
          id: item.id,
          invoiceId: item.invoiceId,
          itemName: item.itemName,
          quantity: item.quantity,
          unitPrice: item.unitPrice
      )));
    } else {
      // Default to first supplier if available
      final suppliers = Provider.of<PurchaseController>(context, listen: false).suppliers;
      if (suppliers.isNotEmpty) {
        _selectedSupplierId = suppliers.first.id;
      }
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat.yMMMd().format(_selectedDate);
      });
    }
  }

  void _addItem() {
    if (_itemNameController.text.isEmpty ||
        _itemQuantityController.text.isEmpty ||
        _itemUnitPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all item fields.")));
      return;
    }
    final quantity = double.tryParse(_itemQuantityController.text);
    final unitPrice = double.tryParse(_itemUnitPriceController.text);

    if (quantity == null || quantity <= 0 || unitPrice == null || unitPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid quantity or unit price.")));
      return;
    }

    setState(() {
      _items.add(PurchaseItem(
        itemName: _itemNameController.text,
        quantity: quantity,
        unitPrice: unitPrice,
      ));
    });
    _itemNameController.clear();
    _itemQuantityController.clear();
    _itemUnitPriceController.clear();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double _calculateTotalAmount() {
    return _items.fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_selectedSupplierId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a supplier.')),
        );
        return;
      }
      if (_items.isEmpty && widget.invoice == null) { // Only enforce for new invoices
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item to the invoice.')),
        );
        return;
      }


      final purchaseController = Provider.of<PurchaseController>(context, listen: false);

      final newInvoice = PurchaseInvoice(
        id: widget.invoice?.id,
        supplierId: _selectedSupplierId!,
        date: _selectedDate,
        items: _items, // these are already new instances or copies
      );
      newInvoice.calculateTotalAmount(); // Calculate total before saving

      bool success;
      if (widget.invoice == null) {
        success = await purchaseController.addPurchaseInvoice(newInvoice);
      } else {
        success = await purchaseController.updatePurchaseInvoice(newInvoice);
      }

      if (success && mounted) {
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(purchaseController.errorMessage ?? 'Failed to save invoice.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _itemNameController.dispose();
    _itemQuantityController.dispose();
    _itemUnitPriceController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final purchaseController = Provider.of<PurchaseController>(context); // Can be listen:true for supplier dropdown

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'Add Purchase Invoice' : 'Edit Purchase Invoice'),
        actions: [
            Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(child: Text("Total: ${_calculateTotalAmount().toStringAsFixed(2)}", style: TextStyle(fontSize: 16)))
            )
        ]
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              // Supplier Dropdown
              DropdownButtonFormField<int>(
                value: _selectedSupplierId,
                hint: const Text('Select Supplier'),
                items: purchaseController.suppliers.map((Supplier supplier) {
                  return DropdownMenuItem<int>(
                    value: supplier.id,
                    child: Text(supplier.name),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedSupplierId = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select a supplier' : null,
                decoration: const InputDecoration(labelText: 'Supplier'),
              ),
              // Date Picker
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Invoice Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _pickDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please select a date';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Item Entry Section
              Text('Invoice Items', style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _itemNameController, decoration: const InputDecoration(labelText: 'Item Name'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _itemQuantityController, decoration: const InputDecoration(labelText: 'Qty'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _itemUnitPriceController, decoration: const InputDecoration(labelText: 'Unit Price'), keyboardType: TextInputType.number)),
                  IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: _addItem),
                ],
              ),
              const SizedBox(height: 10),
              // Items List
              Expanded(
                child: _items.isEmpty
                    ? const Center(child: Text('No items added yet.'))
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Card(
                            child: ListTile(
                              title: Text(item.itemName),
                              subtitle: Text('Qty: ${item.quantity}, Price: ${item.unitPrice.toStringAsFixed(2)}, Total: ${item.totalPrice.toStringAsFixed(2)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => _removeItem(index),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(widget.invoice == null ? 'Add Invoice' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
