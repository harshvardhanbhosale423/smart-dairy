import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repository = CustomerRepository();
  StreamSubscription? _sub;

  List<CustomerModel> _allCustomers = [];
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'paused', 'inactive'
  bool _isLoading = false;
  String? _errorMessage;

  List<CustomerModel> get allCustomers => _allCustomers;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<CustomerModel> get filteredCustomers {
    return _allCustomers.where((c) {
      final matchesSearch = c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            c.phone.contains(_searchQuery) ||
                            c.address.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _statusFilter == 'all' || c.status == _statusFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get activeCount => _allCustomers.where((c) => c.isActive).length;
  int get pausedCount => _allCustomers.where((c) => c.isPaused).length;
  double get totalOutstandingDues => _allCustomers.fold(0.0, (sum, c) => c.currentBalance > 0 ? sum + c.currentBalance : sum);

  void listenToCustomers(String ownerId) {
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();

    _sub = _repository.getCustomersStream(ownerId).listen(
      (customers) {
        _allCustomers = customers;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  Future<bool> addCustomer({
    required String ownerId,
    required String name,
    required String phone,
    String? username,
    String? password,
    required String address,
    required double morningQuota,
    required double eveningQuota,
    required double milkRate,
    required DateTime joiningDate,
    double openingBalance = 0.0,
    String notes = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newCustomer = CustomerModel(
        id: const Uuid().v4(),
        ownerId: ownerId,
        name: name.trim(),
        phone: phone.trim(),
        username: username?.trim(),
        password: password?.trim(),
        address: address.trim(),
        morningQuota: morningQuota,
        eveningQuota: eveningQuota,
        milkRate: milkRate,
        joiningDate: joiningDate,
        status: 'active',
        currentBalance: openingBalance,
        notes: notes.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.addCustomer(newCustomer, openingBalance: openingBalance);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.updateCustomer(customer);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleCustomerPause(CustomerModel customer) async {
    final nextStatus = customer.isActive ? 'paused' : 'active';
    await _repository.updateCustomerStatus(customer.id, nextStatus);
  }

  Future<void> deleteCustomer(CustomerModel customer) async {
    await _repository.deleteCustomer(customer.id, customer.ownerId);
    _allCustomers.removeWhere((c) => c.id == customer.id);
    notifyListeners();
  }

  Future<void> deactivateCustomer(CustomerModel customer) async {
    await deleteCustomer(customer);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

