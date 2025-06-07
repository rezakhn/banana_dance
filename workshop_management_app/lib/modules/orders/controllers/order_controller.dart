import 'package:flutter/foundation.dart';
import '../../../core/database_service.dart';
import '../models/customer.dart';
import '../models/sales_order.dart';
import '../models/order_item.dart';
import '../models/payment.dart';
import '../../parts/models/product.dart'; // For fetching product list for orders
import '../../parts/models/part.dart';    // For checking component part details
import '../../inventory/models/inventory_item.dart'; // For checking stock

class OrderController with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // Customer State
  List<Customer> _customers = [];
  List<Customer> get customers => _customers;
  Customer? _selectedCustomer;
  Customer? get selectedCustomer => _selectedCustomer;

  // Sales Order State
  List<SalesOrder> _salesOrders = [];
  List<SalesOrder> get salesOrders => _salesOrders;
  SalesOrder? _selectedSalesOrder; // Includes items and payments when fully loaded
  SalesOrder? get selectedSalesOrder => _selectedSalesOrder;

  // Product list for populating order item choices
  List<Product> _availableProducts = [];
  List<Product> get availableProducts => _availableProducts;
  Map<int, String> _productIdToNameMap = {}; // For display
  Map<int, String> get productIdToNameMap => _productIdToNameMap;


  // Availability/Shortage Info for selected order
  Map<String, double> _itemShortages = {}; // Key: Part Name, Value: Shortage Quantity
  Map<String, double> get itemShortages => _itemShortages;
  bool _isCheckingStock = false;
  bool get isCheckingStock => _isCheckingStock;


  // Common State
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  OrderController() {
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

  Future<void> _updateProductIdToNameMap(List<Product> productsList) async {
    _productIdToNameMap = {for (var p in productsList) p.id!: p.name};
  }

  // --- Customer Methods ---
  Future<void> fetchCustomers({String? query}) async {
    _setLoading(true); _setError(null);
    try {
      _customers = await _dbService.getCustomers(query: query);
    } catch (e) {
      _setError('Failed to load customers: ${e.toString()}'); _customers = [];
    }
    _setLoading(false);
  }

  Future<bool> addCustomer(Customer customer) async {
    _setLoading(true); _setError(null);
    try {
      await _dbService.insertCustomer(customer);
      await fetchCustomers();
      _setLoading(false); return true;
    } catch (e) {
      _setError('Failed to add customer: ${e.toString()}'); _setLoading(false); return false;
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    _setLoading(true); _setError(null);
    try {
      await _dbService.updateCustomer(customer);
      await fetchCustomers();
      if (_selectedCustomer?.id == customer.id) _selectedCustomer = customer;
      _setLoading(false); return true;
    } catch (e) {
      _setError('Failed to update customer: ${e.toString()}'); _setLoading(false); return false;
    }
  }

  Future<bool> deleteCustomer(int id) async {
    _setLoading(true); _setError(null);
    try {
      await _dbService.deleteCustomer(id);
      await fetchCustomers();
      if (_selectedCustomer?.id == id) _selectedCustomer = null;
      // Also remove/filter sales orders associated with this customer if desired, or let DB restrict
      _salesOrders.removeWhere((order) => order.customerId == id);
      _setLoading(false); return true;
    } catch (e) {
      _setError('Failed to delete customer (may have existing orders): ${e.toString()}');
      _setLoading(false); return false;
    }
  }

  void selectCustomer(Customer? customer){
    _selectedCustomer = customer;
    notifyListeners();
  }

  // --- Product List for Order Items ---
  Future<void> fetchAvailableProducts() async {
    // This could also come from PartController if it manages products,
    // but direct fetch is fine for now.
    _setLoading(true); _setError(null);
    try {
      _availableProducts = await _dbService.getProducts();
      await _updateProductIdToNameMap(_availableProducts);
    } catch (e) {
      _setError('Failed to load available products: ${e.toString()}'); _availableProducts = [];
    }
    _setLoading(false);
  }


  // --- Sales Order Methods ---
  Future<void> fetchSalesOrders({String? status, int? customerId}) async {
    _setLoading(true); _setError(null);
    try {
      _salesOrders = await _dbService.getSalesOrders(status: status, customerId: customerId);
      if(_availableProducts.isEmpty) await fetchAvailableProducts(); // Ensure product names are available
    } catch (e) {
      _setError('Failed to load sales orders: ${e.toString()}'); _salesOrders = [];
    }
    _setLoading(false);
  }

  Future<SalesOrder?> getFullSalesOrderDetails(int orderId) async {
    _setLoading(true); _setError(null);
    try {
      final order = await _dbService.getSalesOrderById(orderId);
      if (order != null && _availableProducts.isEmpty) await fetchAvailableProducts();
       _setLoading(false);
      return order;
    } catch (e) {
      _setError('Failed to load order details: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }


  Future<bool> addSalesOrder(SalesOrder order) async {
    _setLoading(true); _setError(null);
    try {
      // Items should already be part of the order object passed in
      order.calculateTotalAmount();
      await _dbService.insertSalesOrder(order);
      await fetchSalesOrders(); // Refresh list
      _setLoading(false); return true;
    } catch (e) {
      _setError('Failed to add sales order: ${e.toString()}'); _setLoading(false); return false;
    }
  }

  Future<bool> updateSalesOrder(SalesOrder order) async {
    _setLoading(true); _setError(null);
    try {
      order.calculateTotalAmount();
      await _dbService.updateSalesOrder(order);
      await fetchSalesOrders(); // Refresh list
      if (_selectedSalesOrder?.id == order.id) {
        _selectedSalesOrder = await _dbService.getSalesOrderById(order.id!); // Refresh selected
      }
      _setLoading(false); return true;
    } catch (e) {
      _setError('Failed to update sales order: ${e.toString()}'); _setLoading(false); return false;
    }
  }

  Future<bool> updateSalesOrderStatus(int orderId, String newStatus) async {
    _setLoading(true); _setError(null);
    try {
      await _dbService.updateSalesOrderStatus(orderId, newStatus);
      // If completing, inventory is handled by completeSalesOrderAndUpdateInventory
      if (newStatus == "Completed") {
          return await completeSelectedSalesOrder(orderId, true); // Call the specific completion logic
      } else {
        // For other status changes, just refresh data
        final updatedOrder = await _dbService.getSalesOrderById(orderId);
        if (updatedOrder != null) {
          int index = _salesOrders.indexWhere((o) => o.id == orderId);
          if (index != -1) _salesOrders[index] = updatedOrder;
          if (_selectedSalesOrder?.id == orderId) _selectedSalesOrder = updatedOrder;
        }
      }
      _setLoading(false); return true;
    } catch (e) {
      _setError('Failed to update order status: ${e.toString()}'); _setLoading(false); return false;
    }
  }


  Future<bool> deleteSalesOrder(int id) async {
    _setLoading(true); _setError(null);
    try {
      await _dbService.deleteSalesOrder(id);
      await fetchSalesOrders(); // Refresh list
      if (_selectedSalesOrder?.id == id) _selectedSalesOrder = null;
      _setLoading(false); return true;
    } catch (e) {
      _setError('Failed to delete sales order: ${e.toString()}'); _setLoading(false); return false;
    }
  }

  Future<void> selectSalesOrder(int orderId) async {
    _setLoading(true); _setError(null); _itemShortages = {};
    try {
      _selectedSalesOrder = await _dbService.getSalesOrderById(orderId);
      if (_selectedSalesOrder != null) {
        if (_availableProducts.isEmpty) await fetchAvailableProducts();
        // Optionally, immediately check stock for the selected order
        // await checkStockForSelectedOrder();
      }
    } catch (e) {
      _setError('Failed to load selected order: ${e.toString()}');
      _selectedSalesOrder = null;
    }
    _setLoading(false); // This will notify listeners
  }

  // --- Payment Methods ---
  Future<bool> addPayment(Payment payment) async {
    if (_selectedSalesOrder == null || payment.orderId != _selectedSalesOrder!.id) {
      _setError("No order selected or payment order ID mismatch.");
      return false;
    }
    _setLoading(true); _setError(null);
    try {
      await _dbService.insertPayment(payment);
      // Refresh selected order to include new payment
      _selectedSalesOrder = await _dbService.getSalesOrderById(_selectedSalesOrder!.id!);
      // Also update the order in the main list
      int index = _salesOrders.indexWhere((o) => o.id == _selectedSalesOrder!.id);
      if(index != -1) _salesOrders[index] = _selectedSalesOrder!;

      _setLoading(false); return true;
    } catch (e) {
      _setError('Failed to add payment: ${e.toString()}'); _setLoading(false); return false;
    }
  }

  Future<bool> deletePayment(int paymentId) async {
     if (_selectedSalesOrder == null ) {
      _setError("No order selected.");
      return false;
    }
    _setLoading(true); _setError(null);
    try {
      await _dbService.deletePayment(paymentId);
      _selectedSalesOrder = await _dbService.getSalesOrderById(_selectedSalesOrder!.id!);
      int index = _salesOrders.indexWhere((o) => o.id == _selectedSalesOrder!.id);
      if(index != -1) _salesOrders[index] = _selectedSalesOrder!;
      _setLoading(false); return true;
    } catch (e) {
      _setError('Failed to delete payment: ${e.toString()}'); _setLoading(false); return false;
    }
  }


  // --- Order Completion & Inventory ---
  Future<bool> completeSelectedSalesOrder(int orderId, bool calledFromStatusUpdate) async {
    SalesOrder? orderToComplete = _selectedSalesOrder;
    if (orderToComplete == null || orderToComplete.id != orderId) {
        orderToComplete = await _dbService.getSalesOrderById(orderId);
    }

    if (orderToComplete == null) {
      _setError('Order not found for completion.'); return false;
    }
    if (orderToComplete.status == 'Completed' && calledFromStatusUpdate) { // Already handled by status update
        _setLoading(false); // Ensure loading is false if we short-circuit
        return true;
    }
     if (orderToComplete.status == 'Completed' && !calledFromStatusUpdate) {
      _setError('Order is already completed.');
      return false;
    }


    _setLoading(true); _setError(null);
    try {
      await _dbService.completeSalesOrderAndUpdateInventory(orderId);
      // Refresh selected order and list
      _selectedSalesOrder = await _dbService.getSalesOrderById(orderId);
      int index = _salesOrders.indexWhere((o) => o.id == orderId);
      if (index != -1 && _selectedSalesOrder != null) {
        _salesOrders[index] = _selectedSalesOrder!;
      } else if (_selectedSalesOrder == null) { // If it became null for some reason
        await fetchSalesOrders(); // Full refresh
      }
      _setLoading(false); return true;
    } catch (e) {
      _setError('Failed to complete sales order: ${e.toString()}'); _setLoading(false); return false;
    }
  }

  // --- Stock Check for Order ---
  Future<void> checkStockForSelectedOrder() async {
    if (_selectedSalesOrder == null) {
      _itemShortages = {};
      notifyListeners();
      return;
    }
    _isCheckingStock = true;
    _itemShortages = {};
    notifyListeners();

    try {
      for (var orderItem in _selectedSalesOrder!.items) {
        final product = await _dbService.getProductById(orderItem.productId);
        if (product == null) continue;

        final productParts = await _dbService.getPartsForProduct(product.id!);
        if (productParts.isEmpty) { // Product is directly inventoried
            final inventoryItem = await _dbService.getInventoryItemByName(product.name);
            final currentStock = inventoryItem?.quantity ?? 0;
            final requiredForThisOrderItem = orderItem.quantity;
             if (currentStock < requiredForThisOrderItem) {
                _itemShortages[product.name] = (_itemShortages[product.name] ?? 0) + (requiredForThisOrderItem - currentStock);
            }
        } else { // Product is an assembly, check components
            for (var productPartLink in productParts) {
              final part = await _dbService.getPartById(productPartLink.partId);
              if (part == null) continue;

              final inventoryItem = await _dbService.getInventoryItemByName(part.name);
              final currentStock = inventoryItem?.quantity ?? 0;
              // Required quantity of this specific part for one unit of the product, times how many products are ordered
              final requiredForThisOrderItem = productPartLink.quantity * orderItem.quantity;

              if (currentStock < requiredForThisOrderItem) {
                _itemShortages[part.name] = (_itemShortages[part.name] ?? 0) + (requiredForThisOrderItem - currentStock);
              }
            }
        }
      }
    } catch (e) {
      // Set a general error or specific stock check error
      _setError("Error checking stock: ${e.toString()}");
    }
    _isCheckingStock = false;
    notifyListeners();
  }
}
