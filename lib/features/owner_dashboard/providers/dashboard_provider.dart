import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../customers/models/customer_model.dart';
import '../../milk_entry/models/milk_entry_model.dart';
import '../../payments/models/payment_model.dart';
import '../../expenses/models/expense_model.dart';

class DashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<void> loadDashboardMetrics(String ownerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // 1. Customers metrics
      final custSnap = await _firestore
          .collection('customers')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      _totalCustomers = custSnap.docs.length;
      _activeCustomers = custSnap.docs.where((d) => d.data()['status'] == 'active').length;
      _totalPendingDues = custSnap.docs.fold(0.0, (s, d) {
        final bal = (d.data()['currentBalance'] ?? 0.0).toDouble();
        return bal > 0 ? s + bal : s;
      });

      // 2. Today's Milk Distribution
      final todaySnap = await _firestore
          .collection('milk_entries')
          .where('ownerId', isEqualTo: ownerId)
          .where('date', isGreaterThanOrEqualTo: startOfToday)
          .where('date', isLessThanOrEqualTo: endOfToday)
          .get();

      _todayEntries = todaySnap.docs
          .map((d) => MilkEntryModel.fromMap(d.data(), d.id))
          .toList();

      _todayMorningMilk = _todayEntries.fold(0.0, (s, e) => s + e.morningQty);
      _todayEveningMilk = _todayEntries.fold(0.0, (s, e) => s + e.eveningQty);
      _todayTotalMilk = _todayMorningMilk + _todayEveningMilk;

      // 3. This Month's Milk Sales
      final monthMilkSnap = await _firestore
          .collection('milk_entries')
          .where('ownerId', isEqualTo: ownerId)
          .where('date', isGreaterThanOrEqualTo: startOfMonth)
          .where('date', isLessThanOrEqualTo: endOfMonth)
          .get();

      _thisMonthSalesLitres = monthMilkSnap.docs.fold(
          0.0, (s, d) => s + (d.data()['totalQty'] ?? 0.0).toDouble());
      _thisMonthSalesAmount = monthMilkSnap.docs.fold(
          0.0, (s, d) => s + (d.data()['totalAmount'] ?? 0.0).toDouble());

      // 4. This Month's Collection (Payments)
      final monthPaySnap = await _firestore
          .collection('payments')
          .where('ownerId', isEqualTo: ownerId)
          .where('paymentDate', isGreaterThanOrEqualTo: startOfMonth)
          .where('paymentDate', isLessThanOrEqualTo: endOfMonth)
          .get();

      _thisMonthCollection = monthPaySnap.docs.fold(0.0, (s, d) {
        if (d.data()['status'] == 'PAID') {
          return s + (d.data()['amount'] ?? 0.0).toDouble();
        }
        return s;
      });

      // Recent 5 payments
      _recentPayments = monthPaySnap.docs
          .map((d) => PaymentModel.fromMap(d.data(), d.id))
          .take(5)
          .toList();

      // 5. This Month's Expenses
      final monthExpSnap = await _firestore
          .collection('expenses')
          .where('ownerId', isEqualTo: ownerId)
          .where('expenseDate', isGreaterThanOrEqualTo: startOfMonth)
          .where('expenseDate', isLessThanOrEqualTo: endOfMonth)
          .get();

      _thisMonthExpenses = monthExpSnap.docs.fold(
          0.0, (s, d) => s + (d.data()['amount'] ?? 0.0).toDouble());

      // 6. Monthly Net Profit = Cash Collection - Expenses
      _monthlyNetProfit = _thisMonthCollection - _thisMonthExpenses;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}

