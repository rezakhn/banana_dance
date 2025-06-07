import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/purchase_controller.dart';
import '../models/supplier.dart';

class SupplierEditScreen extends StatefulWidget {
  final Supplier? supplier;

  const SupplierEditScreen({Key? key, this.supplier}) : super(key: key);

  @override
  State<SupplierEditScreen> createState() => _SupplierEditScreenState();
}

class _SupplierEditScreenState extends State<SupplierEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _contactInfo;

  @override
  void initState() {
    super.initState();
    _name = widget.supplier?.name ?? '';
    _contactInfo = widget.supplier?.contactInfo ?? '';
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final purchaseController = Provider.of<PurchaseController>(context, listen: false);

      final newSupplier = Supplier(
        id: widget.supplier?.id,
        name: _name,
        contactInfo: _contactInfo,
      );

      bool success;
      String? errorMsg;
      if (widget.supplier == null) {
        success = await purchaseController.addSupplier(newSupplier);
      } else {
        success = await purchaseController.updateSupplier(newSupplier);
      }
      errorMsg = purchaseController.errorMessage;


      if (success && mounted) {
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg ?? 'Failed to save supplier. Name might already exist.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.supplier == null ? 'Add Supplier' : 'Edit Supplier'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Supplier Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a supplier name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _contactInfo,
                decoration: const InputDecoration(labelText: 'Contact Info (Phone, Email, etc.)'),
                onSaved: (value) => _contactInfo = value ?? '',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(widget.supplier == null ? 'Add Supplier' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
