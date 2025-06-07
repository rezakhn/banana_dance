import 'package:flutter/foundation.dart';
import '../../../core/database_service.dart';
import '../models/supplier.dart';
import '../models/purchase_invoice.dart';

class PurchaseController with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // Supplier State
  List<Supplier> _suppliers = [];
  List<Supplier> get suppliers => _suppliers;
  Supplier? _selectedSupplier;
  Supplier? get selectedSupplier => _selectedSupplier;

  // Purchase Invoice State
  List<PurchaseInvoice> _purchaseInvoices = [];
  List<PurchaseInvoice> get purchaseInvoices => _purchaseInvoices;
  PurchaseInvoice? _selectedPurchaseInvoice;
  PurchaseInvoice? get selectedPurchaseInvoice => _selectedPurchaseInvoice;

  // Common State
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PurchaseController() {
    // Optionally load initial data
    // fetchSuppliers();
    // fetchPurchaseInvoices();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // --- Supplier Methods ---
  Future<void> fetchSuppliers({String? query}) async {
    _setLoading(true);
    _setError(null);
    try {
      _suppliers = await _dbService.getSuppliers(query: query);
    } catch (e) {
      _setError('Failed to load suppliers: ${e.toString()}');
      _suppliers = [];
    }
    _setLoading(false);
  }

  Future<bool> addSupplier(Supplier supplier) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertSupplier(supplier);
      await fetchSuppliers(); // Refresh list
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add supplier: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<Supplier?> getSupplierById(int id) async {
    _setLoading(true);
    _setError(null);
     try {
      final supplier = await _dbService.getSupplierById(id);
      _setLoading(false);
      return supplier;
    } catch (e) {
      _setError('Failed to get supplier: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.updateSupplier(supplier);
      await fetchSuppliers(); // Refresh list
      if (_selectedSupplier?.id == supplier.id) {
        _selectedSupplier = await _dbService.getSupplierById(supplier.id!);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update supplier: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteSupplier(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.deleteSupplier(id);
      await fetchSuppliers(); // Refresh list
      if (_selectedSupplier?.id == id) {
        _selectedSupplier = null;
        // Also filter invoices if they were related to this supplier
        _purchaseInvoices.removeWhere((invoice) => invoice.supplierId == id);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete supplier: ${e.toString()}. Check if they have associated invoices.');
      _setLoading(false);
      return false;
    }
  }

  void selectSupplier(Supplier? supplier) {
    _selectedSupplier = supplier;
    notifyListeners();
    // Optionally, fetch invoices for this supplier if UI requires it
    // if (supplier != null) {
    //   fetchPurchaseInvoices(supplierId: supplier.id);
    // } else {
    //   fetchPurchaseInvoices(); // Fetch all or clear
    // }
  }

  // --- Purchase Invoice Methods ---
  Future<void> fetchPurchaseInvoices({DateTime? startDate, DateTime? endDate, int? supplierId}) async {
    _setLoading(true);
    _setError(null);
    try {
      _purchaseInvoices = await _dbService.getPurchaseInvoices(
        startDate: startDate,
        endDate: endDate,
        supplierId: supplierId,
      );
    } catch (e) {
      _setError('Failed to load purchase invoices: ${e.toString()}');
      _purchaseInvoices = [];
    }
    _setLoading(false);
  }

  Future<bool> addPurchaseInvoice(PurchaseInvoice invoice) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertPurchaseInvoice(invoice);
      await fetchPurchaseInvoices(); // Refresh list
      // TODO: Trigger inventory update notification if necessary
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add purchase invoice: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<PurchaseInvoice?> getPurchaseInvoiceById(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      final invoice = await _dbService.getPurchaseInvoiceById(id);
      _setLoading(false);
      return invoice;
    } catch (e) {
      _setError('Failed to get purchase invoice: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  Future<bool> updatePurchaseInvoice(PurchaseInvoice invoice) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.updatePurchaseInvoice(invoice);
      await fetchPurchaseInvoices(); // Refresh list
      if (_selectedPurchaseInvoice?.id == invoice.id) {
         _selectedPurchaseInvoice = await _dbService.getPurchaseInvoiceById(invoice.id!);
      }
      // TODO: Trigger inventory update notification if necessary
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update purchase invoice: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deletePurchaseInvoice(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.deletePurchaseInvoice(id);
      await fetchPurchaseInvoices(); // Refresh list
      if (_selectedPurchaseInvoice?.id == id) {
        _selectedPurchaseInvoice = null;
      }
      // TODO: Trigger inventory update notification if necessary
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete purchase invoice: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  void selectPurchaseInvoice(PurchaseInvoice? invoice) {
    _selectedPurchaseInvoice = invoice;
    notifyListeners();
  }
}
