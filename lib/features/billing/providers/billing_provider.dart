import 'dart:async';
import 'package:flutter/material.dart';
import '../models/monthly_bill_model.dart';
import '../repositories/billing_repository.dart';
import '../../customers/models/customer_model.dart';

class BillingProvider extends ChangeNotifier {
  final BillingRepository _repository = BillingRepository();
  StreamSubscription? _billsSub;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  List<MonthlyBillModel> _bills = [];
  bool _isLoading = false;
  String? _errorMessage;

  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  String get currentYearMonth => '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}';
  List<MonthlyBillModel> get bills => _bills;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalBilledAmount => _bills.fold(0.0, (s, b) => s + b.finalPayable);
  double get totalCollectedInBills => _bills.fold(0.0, (s, b) => s + b.paidAmount);
  int get paidBillsCount => _bills.where((b) => b.isPaid).length;
  int get unpaidBillsCount => _bills.where((b) => b.isUnpaid).length;

  void setMonth(int year, int month, String ownerId) {
    _selectedYear = year;
    _selectedMonth = month;
    notifyListeners();
    listenToOwnerBills(ownerId);
  }

  void listenToOwnerBills(String ownerId) {
    _billsSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _billsSub = _repository.getOwnerBillsForMonthStream(
      ownerId: ownerId,
      yearMonth: currentYearMonth,
    ).listen(
      (list) {
        _bills = list;
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

  /// Auto-generate monthly bills for all active/paused customers
  Future<int> generateAllBills({
    required String ownerId,
    required List<CustomerModel> customers,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final generated = await _repository.generateBillsForAllCustomers(
        ownerId: ownerId,
        customers: customers,
        year: _selectedYear,
        month: _selectedMonth,
      );

      _isLoading = false;
      notifyListeners();
      return generated.length;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return 0;
    }
  }

  /// Generate or refresh bill for a single customer
  Future<MonthlyBillModel?> generateSingleBill(CustomerModel customer) async {
    _isLoading = true;
    notifyListeners();

    try {
      final bill = await _repository.generateBillForCustomer(
        customer: customer,
        year: _selectedYear,
        month: _selectedMonth,
      );
      _isLoading = false;
      notifyListeners();
      return bill;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _billsSub?.cancel();
    super.dispose();
  }
}

