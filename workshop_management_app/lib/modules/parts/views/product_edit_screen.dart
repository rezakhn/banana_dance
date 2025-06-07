import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/part_controller.dart';
import '../models/product.dart';
import '../models/product_part.dart';
import '../models/part.dart'; // For selecting parts

class ProductEditScreen extends StatefulWidget {
  final Product? product;

  const ProductEditScreen({Key? key, this.product}) : super(key: key);

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  List<ProductPart> _productParts = []; // For managing parts of this product

  @override
  void initState() {
    super.initState();
    _name = widget.product?.name ?? '';
    if (widget.product != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller = Provider.of<PartController>(context, listen: false);
        controller.selectProduct(widget.product!.id!).then((_){
            if(mounted){
                setState(() {
                    _productParts = List<ProductPart>.from(controller.selectedProductParts.map((pp) =>
                        ProductPart(id: pp.id, productId: pp.productId, partId: pp.partId, quantity: pp.quantity)
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
      final newProduct = Product(id: widget.product?.id, name: _name);

      bool success = await controller.updateProduct(newProduct, partsToSet: _productParts);

      if (success && mounted) {
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage ?? 'Failed to save product.')),
        );
      }
    }
  }

  Widget _buildProductPartsManagementUI() {
    final controller = Provider.of<PartController>(context, listen: false);
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text('Required Parts for this Product:', style: Theme.of(context).textTheme.titleMedium),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _productParts.length,
          itemBuilder: (context, index) {
            final pp = _productParts[index];
            final partName = controller.partIdToNameMap[pp.partId] ?? 'Unknown Part';
            return ListTile(
              title: Text('$partName (ID: ${pp.partId})'),
              subtitle: Text('Quantity: ${pp.quantity}'),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  setState(() { _productParts.removeAt(index); });
                },
              ),
            );
          },
        ),
        ElevatedButton(onPressed: _showAddProductPartDialog, child: Text("Add Part Requirement"))
      ],
    );
  }

  void _showAddProductPartDialog() {
    final controller = Provider.of<PartController>(context, listen: false);
    if (controller.parts.isEmpty) controller.fetchParts();

    Part? selectedPart;
    final quantityController = TextEditingController();

    showDialog(context: context, builder: (dialogContext){
        return AlertDialog(
            title: Text("Add Required Part"),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setStateDialog) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Part>(
                      hint: Text("Select Part (Component or Assembly)"),
                      value: selectedPart,
                      items: controller.parts.map((Part part) {
                        return DropdownMenuItem<Part>(value: part, child: Text('${part.name} ${part.isAssembly ? "(Assembly)" : "" }'));
                      }).toList(),
                      onChanged: (Part? newValue) {
                        setStateDialog(() { selectedPart = newValue; });
                      },
                       validator: (val) => val == null ? "Part is required" : null,
                    ),
                    TextFormField(controller: quantityController, decoration: InputDecoration(labelText: "Quantity Needed"), keyboardType: TextInputType.number),
                  ],
                );
              }
            ),
            actions: [
                TextButton(onPressed: ()=>Navigator.pop(dialogContext), child: Text("Cancel")),
                ElevatedButton(onPressed: (){
                    if (selectedPart != null && quantityController.text.isNotEmpty) {
                        final quantity = double.tryParse(quantityController.text);
                        if (quantity != null && quantity > 0) {
                            setState(() {
                                _productParts.add(ProductPart(
                                    productId: widget.product?.id ?? 0, // Temp if new
                                    partId: selectedPart!.id!,
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
    Provider.of<PartController>(context, listen: false).fetchParts(); // Ensure parts are available for selection

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add New Product' : 'Edit Product: ${widget.product!.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name' : null,
                onSaved: (value) => _name = value!,
              ),
              _buildProductPartsManagementUI(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(widget.product == null ? 'Add Product' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
