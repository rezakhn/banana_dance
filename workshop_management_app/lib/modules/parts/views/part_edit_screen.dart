import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/part_controller.dart';
import '../models/part.dart';
import '../models/part_composition.dart'; // For later use

class PartEditScreen extends StatefulWidget {
  final Part? part;

  const PartEditScreen({Key? key, this.part}) : super(key: key);

  @override
  State<PartEditScreen> createState() => _PartEditScreenState();
}

class _PartEditScreenState extends State<PartEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late bool _isAssembly;
  List<PartComposition> _components = []; // For managing components if it's an assembly

  @override
  void initState() {
    super.initState();
    _name = widget.part?.name ?? '';
    _isAssembly = widget.part?.isAssembly ?? false;
    if (widget.part != null && widget.part!.isAssembly) {
      // Fetch existing components if editing an assembly
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller = Provider.of<PartController>(context, listen: false);
        controller.selectPart(widget.part!.id!).then((_) {
            if (mounted) {
                 setState(() {
                    _components = List<PartComposition>.from(controller.selectedPartComposition.map((pc) =>
                        PartComposition(id: pc.id, assemblyId: pc.assemblyId, componentPartId: pc.componentPartId, quantity: pc.quantity)
                    ));
                 });
            }
        });
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final controller = Provider.of<PartController>(context, listen: false);

      final newPart = Part(id: widget.part?.id, name: _name, isAssembly: _isAssembly);
      bool success;

      if (widget.part == null) {
        success = await controller.addPart(newPart);
        // If it's a new assembly and components were added, they need to be saved
        // This requires getting the newPart.id after it's inserted.
        // For simplicity, component management for new parts might be a two-step process in UI.
      } else {
        success = await controller.updatePart(newPart, componentsToSet: _isAssembly ? _components : null);
      }

      if (success && mounted) {
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage ?? 'Failed to save part.')),
        );
      }
    }
  }

  // Placeholder for component management UI
  Widget _buildComponentManagementUI() {
    if (!_isAssembly) return const SizedBox.shrink();
    final controller = Provider.of<PartController>(context, listen: false); // For accessing raw materials list

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text('Components for this Assembly:', style: Theme.of(context).textTheme.titleMedium),
        // TODO: UI to add/remove components from _components list
        // This would involve a dropdown of other parts (raw materials/sub-assemblies) and a quantity field
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _components.length,
          itemBuilder: (context, index) {
            final comp = _components[index];
            final compName = controller.partIdToNameMap[comp.componentPartId] ?? 'Unknown Part';
            return ListTile(
              title: Text('$compName (ID: ${comp.componentPartId})'),
              subtitle: Text('Quantity: ${comp.quantity}'),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  setState(() {
                    _components.removeAt(index);
                  });
                },
              ),
            );
          },
        ),
        ElevatedButton(onPressed: _showAddComponentDialog, child: Text("Add Component"))
      ],
    );
  }

  void _showAddComponentDialog() {
    final controller = Provider.of<PartController>(context, listen: false);
    if (controller.parts.isEmpty) controller.fetchParts(); // Ensure parts are loaded for dropdown

    final componentIdController = TextEditingController(); // Or use a dropdown
    final quantityController = TextEditingController();
    Part? selectedComponentPart;


    showDialog(context: context, builder: (dialogContext){
        return AlertDialog(
            title: Text("Add Component"),
            content: StatefulBuilder( // To update dropdown inside dialog
              builder: (BuildContext context, StateSetter setStateDialog) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Part>(
                      hint: Text("Select Component Part"),
                      value: selectedComponentPart,
                      items: controller.parts // Filter out current assembly part if widget.part exists
                          .where((p) => widget.part == null || p.id != widget.part!.id)
                          .map((Part part) {
                        return DropdownMenuItem<Part>(value: part, child: Text(part.name));
                      }).toList(),
                      onChanged: (Part? newValue) {
                        setStateDialog(() { // Use StateSetter for dialog's own state
                           selectedComponentPart = newValue;
                        });
                      },
                      validator: (val) => val == null ? "Component is required" : null,
                    ),
                    TextFormField(controller: quantityController, decoration: InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number),
                  ],
                );
              }
            ),
            actions: [
                TextButton(onPressed: ()=>Navigator.pop(dialogContext), child: Text("Cancel")),
                ElevatedButton(onPressed: (){
                    if (selectedComponentPart != null && quantityController.text.isNotEmpty) {
                        final quantity = double.tryParse(quantityController.text);
                        if (quantity != null && quantity > 0) {
                            setState(() { // This updates the main screen's state
                                _components.add(PartComposition(
                                    assemblyId: widget.part?.id ?? 0, // Temporary if new part
                                    componentPartId: selectedComponentPart!.id!,
                                    quantity: quantity
                                ));
                            });
                            Navigator.pop(dialogContext);
                        }
                    }
                }, child: Text("Add"))
            ],
        );
    });
  }


  @override
  Widget build(BuildContext context) {
    // Ensure parts list is available for component selection dropdown
    Provider.of<PartController>(context, listen: false).fetchParts();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.part == null ? 'Add New Part' : 'Edit Part: ${widget.part!.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Part Name'),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name' : null,
                onSaved: (value) => _name = value!,
              ),
              SwitchListTile(
                title: const Text('Is this an Assembly?'),
                value: _isAssembly,
                onChanged: (bool value) {
                  setState(() {
                    _isAssembly = value;
                  });
                },
              ),
              if (_isAssembly) _buildComponentManagementUI(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(widget.part == null ? 'Add Part' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
