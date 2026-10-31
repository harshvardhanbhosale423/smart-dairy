import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../customers/models/customer_model.dart';
import '../../milk_entry/models/milk_entry_model.dart';
import '../../payments/models/payment_model.dart';
import '../../expenses/models/expense_model.dart';
import '../../../core/services/local_database_service.dart';

class DashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService();

  bool _isLoading = false;
  String? _errorMessage;

  // Metrics
  int _totalCustomers = 0;
  int _activeCustomers = 0;
  double _todayMorningMilk = 0.0;
  double _todayEveningMilk = 0.0;
  double _todayTotalMilk = 0.0;
  double _thisMonthSalesLitres = 0.0;
  double _thisMonthSalesAmount = 0.0;
  double _thisMonthCollection = 0.0;
  double _totalPendingDues = 0.0;
  double _thisMonthExpenses = 0.0;
  double _monthlyNetProfit = 0.0;

  List<MilkEntryModel> _todayEntries = [];
  List<PaymentModel> _recentPayments = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalCustomers => _totalCustomers;
  int get activeCustomers => _activeCustomers;
  double get todayMorningMilk => _todayMorningMilk;
  double get todayEveningMilk => _todayEveningMilk;
  double get todayTotalMilk => _todayTotalMilk;
  double get thisMonthSalesLitres => _thisMonthSalesLitres;
  double get thisMonthSalesAmount => _thisMonthSalesAmount;
  double get thisMonthCollection => _thisMonthCollection;
  double get totalPendingDues => _totalPendingDues;
  double get thisMonthExpenses => _thisMonthExpenses;
  double get monthlyNetProfit => _monthlyNetProfit;

  List<MilkEntryModel> get todayEntries => _todayEntries;
  List<PaymentModel> get recentPayments => _recentPayments;

  DateTime? _parseDate(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  Future<void> loadDashboardMetrics(String ownerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();

      // 1. Customers metrics from local DB
      final custDocs = _localDb.query('customers', where: (c) => c['ownerId'] == ownerId);
      _totalCustomers = custDocs.length;
      _activeCustomers = custDocs.where((d) => d['status'] == 'active').length;
      _totalPendingDues = custDocs.fold(0.0, (s, d) {
        final bal = (d['currentBalance'] ?? 0.0).toDouble();
        return bal > 0 ? s + bal : s;
      });

      // 2. Today's Milk Distribution from local DB
      final todayEntriesList = _localDb.query('milk_entries', where: (e) {
        if (e['ownerId'] != ownerId) return false;
        final d = _parseDate(e['date']);
        if (d == null) return false;
        return d.year == now.year && d.month == now.month && d.day == now.day;
      });

      _todayEntries = todayEntriesList.map((d) => MilkEntryModel.fromMap(d, (d['id'] ?? '').toString())).toList();
      _todayMorningMilk = _todayEntries.fold(0.0, (s, e) => s + e.morningQty);
      _todayEveningMilk = _todayEntries.fold(0.0, (s, e) => s + e.eveningQty);
      _todayTotalMilk = _todayMorningMilk + _todayEveningMilk;

      // 3. This Month's Milk Sales
      final monthMilkEntries = _localDb.query('milk_entries', where: (e) {
        if (e['ownerId'] != ownerId) return false;
        final d = _parseDate(e['date']);
        if (d == null) return false;
        return d.year == now.year && d.month == now.month;
      });

      _thisMonthSalesLitres = monthMilkEntries.fold(0.0, (s, d) => s + (d['totalQty'] ?? 0.0).toDouble());
      _thisMonthSalesAmount = monthMilkEntries.fold(0.0, (s, d) => s + (d['totalAmount'] ?? 0.0).toDouble());

      // 4. This Month's Collection (Payments)
      final monthPayments = _localDb.query('payments', where: (p) {
        if (p['ownerId'] != ownerId) return false;
        final d = _parseDate(p['paymentDate']);
        if (d == null) return false;
        return d.year == now.year && d.month == now.month;
      });

      _thisMonthCollection = monthPayments.fold(0.0, (s, d) {
        if (d['status'] == 'PAID') {
          return s + (d['amount'] ?? 0.0).toDouble();
        }
        return s;
      });

      final allPayments = _localDb.query('payments', where: (p) => p['ownerId'] == ownerId);
      final sortedPayments = allPayments.map((d) => PaymentModel.fromMap(d, (d['id'] ?? '').toString())).toList();
      sortedPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      _recentPayments = sortedPayments.take(5).toList();

      // 5. This Month's Expenses
      final monthExpenses = _localDb.query('expenses', where: (e) {
        if (e['ownerId'] != ownerId) return false;
        final d = _parseDate(e['expenseDate']);
        if (d == null) return false;
        return d.year == now.year && d.month == now.month;
      });

      _thisMonthExpenses = monthExpenses.fold(0.0, (s, d) => s + (d['amount'] ?? 0.0).toDouble());

      // 6. Monthly Net Profit
      _monthlyNetProfit = _thisMonthCollection - _thisMonthExpenses;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Dashboard calculation note: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
}
