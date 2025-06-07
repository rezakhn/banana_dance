import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/part_controller.dart';
import '../models/assembly_order.dart';
import '../models/part.dart';

class AssemblyOrderEditScreen extends StatefulWidget {
  final AssemblyOrder? order;

  const AssemblyOrderEditScreen({Key? key, this.order}) : super(key: key);

  @override
  State<AssemblyOrderEditScreen> createState() => _AssemblyOrderEditScreenState();
}

class _AssemblyOrderEditScreenState extends State<AssemblyOrderEditScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedAssemblyPartId;
  late double _quantityToProduce;
  DateTime _selectedDate = DateTime.now();
  late TextEditingController _dateController;
  // Status is usually 'Pending' for new, or existing for edit (but not editable here directly)

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: DateFormat.yMMMd().format(_selectedDate));
    Provider.of<PartController>(context, listen: false).fetchParts(isAssembly: true); // Fetch only assemblies

    if (widget.order != null) {
      _selectedAssemblyPartId = widget.order!.partId;
      _quantityToProduce = widget.order!.quantityToProduce;
      _selectedDate = widget.order!.date;
      _dateController.text = DateFormat.yMMMd().format(_selectedDate);
    } else {
      _quantityToProduce = 1.0; // Default
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context, initialDate: _selectedDate,
        firstDate: DateTime(2000), lastDate: DateTime(2101));
    if (picked != null && picked != _selectedDate) {
      setState(() { _selectedDate = picked; _dateController.text = DateFormat.yMMMd().format(_selectedDate); });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_selectedAssemblyPartId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an assembly to produce.')));
        return;
      }

      final controller = Provider.of<PartController>(context, listen: false);
      final newOrder = AssemblyOrder(
        id: widget.order?.id,
        partId: _selectedAssemblyPartId!,
        quantityToProduce: _quantityToProduce,
        date: _selectedDate,
        status: widget.order?.status ?? 'Pending', // Keep existing status or default to Pending
      );

      bool success;
      // Note: PartController doesn't have updateAssemblyOrder, only status update.
      // Full edit might not be supported or needed if only status changes post-creation.
      // For now, only adding is fully supported by this form.
      if (widget.order == null) {
        success = await controller.addAssemblyOrder(newOrder);
      } else {
        // Placeholder for update logic if controller supported it
        // success = await controller.updateAssemblyOrder(newOrder);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Editing existing orders is not fully supported by this form yet, only status changes via process screen.')));
        success = false; // Or pop without saving if edit is not the intent here
        // If only status can change, this form shouldn't be used for "edit" in that way.
        // This screen is primarily for ADDING.
         Navigator.of(context).pop(); // Just pop for now if it's an edit attempt
         return;
      }


      if (success && mounted) {
        Navigator.of(context).pop();
      } else if (mounted && controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage!)),
        );
      }
    }
  }

  @override
  void dispose(){
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partController = Provider.of<PartController>(context); // Can listen for assemblies list

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order == null ? 'New Assembly Order' : 'Edit Assembly Order'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              DropdownButtonFormField<int>(
                value: _selectedAssemblyPartId,
                hint: const Text('Select Assembly to Produce'),
                items: partController.assemblies.map((Part assembly) {
                  return DropdownMenuItem<int>(value: assembly.id, child: Text(assembly.name));
                }).toList(),
                onChanged: widget.order != null ? null : (int? newValue) { // Disable if editing
                  setState(() { _selectedAssemblyPartId = newValue; });
                },
                validator: (value) => value == null ? 'Please select an assembly' : null,
                decoration: InputDecoration(labelText: 'Assembly', filled: widget.order != null, fillColor: widget.order != null ? Colors.grey[200] : null),
              ),
              TextFormField(
                initialValue: _quantityToProduce.toString(),
                decoration: const InputDecoration(labelText: 'Quantity to Produce'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
                onSaved: (value) => _quantityToProduce = double.parse(value!),
                readOnly: widget.order != null, // Readonly if editing
              ),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Order Date', suffixIcon: Icon(Icons.calendar_today)),
                readOnly: true,
                onTap: widget.order != null ? null : () => _pickDate(context), // Disable if editing
              ),
              const SizedBox(height: 20),
               if (widget.order == null) // Only show Add button for new orders
                ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Create Assembly Order'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
