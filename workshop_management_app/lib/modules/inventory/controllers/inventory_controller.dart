import 'package:flutter/foundation.dart';
import '../../../core/database_service.dart';
import '../models/inventory_item.dart';

class InventoryController with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<InventoryItem> _inventoryItems = [];
  List<InventoryItem> get inventoryItems => _inventoryItems;

  List<InventoryItem> _lowStockItems = [];
  List<InventoryItem> get lowStockItems => _lowStockItems;

  InventoryItem? _selectedInventoryItem;
  InventoryItem? get selectedInventoryItem => _selectedInventoryItem;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  InventoryController() {
    // Optionally fetch items on initialization
    // fetchInventoryItems();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> fetchInventoryItems({String? query}) async {
    _setLoading(true);
    _setError(null);
    try {
      // Assuming DatabaseService will have a method like getAllInventoryItems or similar
      // For now, let's plan for a method that can take a query for item name.
      // If query is null/empty, it should fetch all.
      // This method is not yet defined in DatabaseService plan step, will add it there.
      _inventoryItems = await _dbService.getAllInventoryItems(query: query);
      _filterLowStockItems();
    } catch (e) {
      _setError('Failed to load inventory items: ${e.toString()}');
      _inventoryItems = [];
      _lowStockItems = [];
    }
    _setLoading(false);
  }

  void _filterLowStockItems() {
    _lowStockItems = _inventoryItems.where((item) => item.quantity < item.threshold).toList();
    // No notifyListeners() here as it's called by the public methods that trigger this.
  }

  void selectInventoryItem(InventoryItem? item) {
    _selectedInventoryItem = item;
    notifyListeners();
  }

  Future<InventoryItem?> getInventoryItemDetails(String itemName) async {
    _setLoading(true);
    _setError(null);
    try {
      final item = await _dbService.getInventoryItemByName(itemName);
      _setLoading(false);
      return item;
    } catch (e) {
       _setError('Failed to fetch item details: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }


  Future<bool> updateItemThreshold(String itemName, double newThreshold) async {
    _setLoading(true);
    _setError(null);
    try {
      // DatabaseService needs a method for this: updateInventoryItemThreshold
      await _dbService.updateInventoryItemThreshold(itemName, newThreshold);
      // Refresh the specific item or the whole list
      final index = _inventoryItems.indexWhere((item) => item.itemName == itemName);
      if (index != -1) {
        // Fetch updated item to get potentially new quantity if other operations happened
        final updatedItem = await _dbService.getInventoryItemByName(itemName);
        if(updatedItem != null){
             _inventoryItems[index] = updatedItem;
        } else {
            _inventoryItems.removeAt(index); // Item might have been deleted by another process
        }
      } else {
        // If item was not in list (e.g. new item threshold set), fetch all
        await fetchInventoryItems();
      }
      _filterLowStockItems(); // Re-filter based on new threshold
      _setLoading(false);
      // Update selected item if it's the one being changed
      if (_selectedInventoryItem?.itemName == itemName) {
          _selectedInventoryItem = _inventoryItems.firstWhere((i) => i.itemName == itemName, orElse: () => null as InventoryItem?);
      }
      notifyListeners(); // Ensure UI updates for selected item if necessary
      return true;
    } catch (e) {
      _setError('Failed to update threshold for $itemName: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // If manual adjustment is ever needed (not in current plan for direct UI use):
  // Future<bool> manuallyAdjustItemQuantity(String itemName, double newQuantity) async {
  //   _setLoading(true);
  //   _setError(null);
  //   try {
  //     // DatabaseService needs a method for this
  //     await _dbService.manuallyAdjustInventoryItemQuantity(itemName, newQuantity);
  //     // Refresh item or list
  //     // ...
  //     _filterLowStockItems();
  //     _setLoading(false);
  //     return true;
  //   } catch (e) {
  //     _setError('Failed to adjust quantity for $itemName: ${e.toString()}');
  //     _setLoading(false);
  //     return false;
  //   }
  // }
}
