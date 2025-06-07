import 'package:flutter/foundation.dart';
import '../../../core/database_service.dart';
import '../models/part.dart';
import '../models/part_composition.dart';
import '../models/product.dart';
import '../models/product_part.dart';
import '../models/assembly_order.dart';
import '../../inventory/models/inventory_item.dart'; // For checking stock

class PartController with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // Part State
  List<Part> _parts = [];
  List<Part> get parts => _parts;
  List<Part> _rawMaterials = []; // Filtered list for components
  List<Part> get rawMaterials => _rawMaterials;
  List<Part> _assemblies = []; // Filtered list for assemblies
  List<Part> get assemblies => _assemblies;
  Part? _selectedPart;
  Part? get selectedPart => _selectedPart;
  List<PartComposition> _selectedPartComposition = [];
  List<PartComposition> get selectedPartComposition => _selectedPartComposition;
  // For displaying component names in composition list
  Map<int, String> _partIdToNameMap = {};
  Map<int, String> get partIdToNameMap => _partIdToNameMap;


  // Product State
  List<Product> _products = [];
  List<Product> get products => _products;
  Product? _selectedProduct;
  Product? get selectedProduct => _selectedProduct;
  List<ProductPart> _selectedProductParts = [];
  List<ProductPart> get selectedProductParts => _selectedProductParts;

  // Assembly Order State
  List<AssemblyOrder> _assemblyOrders = [];
  List<AssemblyOrder> get assemblyOrders => _assemblyOrders;
  AssemblyOrder? _selectedAssemblyOrder;
  AssemblyOrder? get selectedAssemblyOrder => _selectedAssemblyOrder;
  List<InventoryItem> _requiredComponentsStock = []; // For displaying stock of components for an assembly order
  List<InventoryItem> get requiredComponentsStock => _requiredComponentsStock;


  // Common State
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PartController() {
    // Initial data fetch can be done here or triggered by UI
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> _updatePartIdToNameMap(List<Part> partsList) async {
    _partIdToNameMap = {for (var p in partsList) p.id!: p.name};
  }

  // --- Part Methods ---
  Future<void> fetchParts({String? query}) async {
    _setLoading(true);
    _setError(null);
    try {
      _parts = await _dbService.getParts(query: query);
      _rawMaterials = _parts.where((p) => !p.isAssembly).toList();
      _assemblies = _parts.where((p) => p.isAssembly).toList();
      await _updatePartIdToNameMap(_parts);
    } catch (e) {
      _setError('Failed to load parts: ${e.toString()}');
      _parts = []; _rawMaterials = []; _assemblies = [];
    }
    _setLoading(false);
  }

  Future<Part?> getPartById(int id) async {
    // Primarily for internal use or direct fetching if needed
    _setLoading(true);
    _setError(null);
    try {
      final part = await _dbService.getPartById(id);
      _setLoading(false);
      return part;
    } catch (e) {
      _setError('Failed to get part: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  Future<bool> addPart(Part part) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertPart(part);
      await fetchParts(); // Refresh list
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add part (name might already exist): ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updatePart(Part part, {List<PartComposition>? componentsToSet}) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.updatePart(part);
      if (part.isAssembly && componentsToSet != null) {
        await _dbService.setAssemblyComponents(part.id!, componentsToSet);
      }
      await fetchParts(); // Refresh list
      if (_selectedPart?.id == part.id) {
        await selectPart(part.id!); // Reselect to refresh compositions
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update part (name might already exist): ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deletePart(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.deletePart(id);
      await fetchParts(); // Refresh list
      if (_selectedPart?.id == id) _selectedPart = null; _selectedPartComposition = [];
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete part (it might be in use): ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> selectPart(int partId) async {
    _selectedPart = _parts.firstWhere((p) => p.id == partId, orElse: () => null as Part?);
    if (_selectedPart != null && _selectedPart!.isAssembly) {
      await fetchComponentsForSelectedAssembly();
    } else {
      _selectedPartComposition = [];
    }
    notifyListeners();
  }

  Future<void> fetchComponentsForSelectedAssembly() async {
    if (_selectedPart == null || !_selectedPart!.isAssembly) {
      _selectedPartComposition = [];
      notifyListeners();
      return;
    }
    _setLoading(true);
    _setError(null);
    try {
      _selectedPartComposition = await _dbService.getComponentsForAssembly(_selectedPart!.id!);
    } catch (e) {
      _setError('Failed to load components: ${e.toString()}');
      _selectedPartComposition = [];
    }
    _setLoading(false); // Notifies listeners
  }

  // For managing components of _selectedPart if it's an assembly
  Future<bool> setComponentsForSelectedAssembly(List<PartComposition> components) async {
    if (_selectedPart == null || !_selectedPart!.isAssembly) {
      _setError("No assembly selected or selected part is not an assembly.");
      return false;
    }
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.setAssemblyComponents(_selectedPart!.id!, components);
      await fetchComponentsForSelectedAssembly(); // Refresh
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to set components: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }


  // --- Product Methods ---
  Future<void> fetchProducts({String? query}) async {
    _setLoading(true);
    _setError(null);
    try {
      _products = await _dbService.getProducts(query: query);
    } catch (e) {
      _setError('Failed to load products: ${e.toString()}');
      _products = [];
    }
    _setLoading(false);
  }

  Future<bool> addProduct(Product product) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertProduct(product);
      await fetchProducts(); // Refresh
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add product (name might already exist): ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProduct(Product product, {List<ProductPart>? partsToSet}) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.updateProduct(product);
      if (partsToSet != null) {
        await _dbService.setProductParts(product.id!, partsToSet);
      }
      await fetchProducts(); // Refresh
      if (_selectedProduct?.id == product.id) {
        await selectProduct(product.id!); // Reselect to refresh parts
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update product (name might already exist): ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.deleteProduct(id);
      await fetchProducts(); // Refresh
      if (_selectedProduct?.id == id) _selectedProduct = null; _selectedProductParts = [];
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete product: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> selectProduct(int productId) async {
    _selectedProduct = _products.firstWhere((p) => p.id == productId, orElse: () => null as Product?);
    if (_selectedProduct != null) {
      await fetchPartsForSelectedProduct();
    } else {
      _selectedProductParts = [];
    }
    notifyListeners();
  }

  Future<void> fetchPartsForSelectedProduct() async {
    if (_selectedProduct == null) {
      _selectedProductParts = [];
      notifyListeners();
      return;
    }
    _setLoading(true);
    _setError(null);
    try {
      _selectedProductParts = await _dbService.getPartsForProduct(_selectedProduct!.id!);
    } catch (e) {
      _setError('Failed to load product parts: ${e.toString()}');
      _selectedProductParts = [];
    }
    _setLoading(false); // Notifies listeners
  }

  Future<bool> setPartsForSelectedProduct(List<ProductPart> productParts) async {
    if (_selectedProduct == null) {
      _setError("No product selected.");
      return false;
    }
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.setProductParts(_selectedProduct!.id!, productParts);
      await fetchPartsForSelectedProduct(); // Refresh
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to set product parts: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // --- Assembly Order Methods ---
  Future<void> fetchAssemblyOrders({String? status}) async {
    _setLoading(true);
    _setError(null);
    try {
      _assemblyOrders = await _dbService.getAssemblyOrders(status: status);
       // Fetch all parts to ensure partIdToNameMap is populated for displaying assembly names
      if (_parts.isEmpty) await fetchParts();
    } catch (e) {
      _setError('Failed to load assembly orders: ${e.toString()}');
      _assemblyOrders = [];
    }
    _setLoading(false);
  }

  Future<AssemblyOrder?> getAssemblyOrderById(int id) async {
     _setLoading(true);
    _setError(null);
    try {
      final order = await _dbService.getAssemblyOrderById(id);
      _setLoading(false);
      return order;
    } catch (e) {
      _setError('Failed to get assembly order: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  Future<bool> addAssemblyOrder(AssemblyOrder order) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertAssemblyOrder(order);
      await fetchAssemblyOrders(); // Refresh
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add assembly order: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteAssemblyOrder(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.deleteAssemblyOrder(id);
      await fetchAssemblyOrders(); // Refresh
      if (_selectedAssemblyOrder?.id == id) _selectedAssemblyOrder = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete assembly order: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> selectAssemblyOrder(int orderId) async {
    _selectedAssemblyOrder = _assemblyOrders.firstWhere((o) => o.id == orderId, orElse: () => null as AssemblyOrder?);
    if (_selectedAssemblyOrder != null) {
        await fetchRequiredComponentsForSelectedOrder();
    } else {
        _requiredComponentsStock = [];
    }
    notifyListeners();
  }

  Future<void> fetchRequiredComponentsForSelectedOrder() async {
    if (_selectedAssemblyOrder == null) {
        _requiredComponentsStock = [];
        notifyListeners();
        return;
    }
    _setLoading(true);
    _setError(null);
    try {
        final List<PartComposition> components = await _dbService.getComponentsForAssembly(_selectedAssemblyOrder!.partId);
        List<InventoryItem> stock = [];
        for (var comp in components) {
            final partDetails = await _dbService.getPartById(comp.componentPartId);
            if (partDetails != null) {
                final inventoryItem = await _dbService.getInventoryItemByName(partDetails.name);
                stock.add(inventoryItem ?? InventoryItem(itemName: partDetails.name, quantity: 0, threshold: 0));
            }
        }
        _requiredComponentsStock = stock;
    } catch (e) {
        _setError('Failed to load component stock: ${e.toString()}');
        _requiredComponentsStock = [];
    }
    _setLoading(false);
  }


  Future<bool> completeSelectedAssemblyOrder() async {
    if (_selectedAssemblyOrder == null) {
      _setError('No assembly order selected.');
      return false;
    }
    if (_selectedAssemblyOrder!.status == 'Completed') {
      _setError('Order is already completed.');
      return false;
    }
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.completeAssemblyOrder(_selectedAssemblyOrder!.id!);
      // Refresh the specific order and the list
      final updatedOrder = await _dbService.getAssemblyOrderById(_selectedAssemblyOrder!.id!);
      if (updatedOrder != null) {
        int index = _assemblyOrders.indexWhere((o) => o.id == updatedOrder.id);
        if (index != -1) _assemblyOrders[index] = updatedOrder;
        _selectedAssemblyOrder = updatedOrder;
      } else {
         await fetchAssemblyOrders(); // Full refresh if single fetch fails
      }
      // TODO: Consider refreshing inventory views if they are active
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to complete assembly order: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
}
