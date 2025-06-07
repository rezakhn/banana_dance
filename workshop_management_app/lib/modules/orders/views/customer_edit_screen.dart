import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/order_controller.dart';
import '../models/customer.dart';

class CustomerEditScreen extends StatefulWidget {
  final Customer? customer;

  const CustomerEditScreen({Key? key, this.customer}) : super(key: key);

  @override
  State<CustomerEditScreen> createState() => _CustomerEditScreenState();
}

class _CustomerEditScreenState extends State<CustomerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _contactInfo;

  @override
  void initState() {
    super.initState();
    _name = widget.customer?.name ?? '';
    _contactInfo = widget.customer?.contactInfo ?? '';
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final controller = Provider.of<OrderController>(context, listen: false);
      final newCustomer = Customer(id: widget.customer?.id, name: _name, contactInfo: _contactInfo);
      bool success = widget.customer == null
          ? await controller.addCustomer(newCustomer)
          : await controller.updateCustomer(newCustomer);

      if (success && mounted) {
        Navigator.of(context).pop();
      } else if (mounted && controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Customer Name'),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name' : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _contactInfo,
                decoration: const InputDecoration(labelText: 'Contact Info'),
                onSaved: (value) => _contactInfo = value ?? '',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(widget.customer == null ? 'Add Customer' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
