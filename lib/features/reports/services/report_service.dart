import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_data.dart';
import '../../milk_entry/models/milk_entry_model.dart';
import '../../payments/models/payment_model.dart';
import '../../expenses/models/expense_model.dart';
import '../../customers/models/customer_model.dart';
import '../../../core/services/local_database_service.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService();

  DateTime? _parseDate(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  /// Generate comprehensive business report for a given date range
  Future<BusinessReportData> generateReport({
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // 1. Fetch Milk Entries in range locally
    final rawMilk = _localDb.query('milk_entries', where: (e) {
      if (e['ownerId'] != ownerId) return false;
      final d = _parseDate(e['date']);
      if (d == null) return false;
      return d.isAfter(start.subtract(const Duration(seconds: 1))) &&
          d.isBefore(end.add(const Duration(seconds: 1)));
    });

    final milkEntries = rawMilk.map((d) => MilkEntryModel.fromMap(d, (d['id'] ?? '').toString())).toList();

    double totalMilkLitres = 0.0;
    double billedSales = 0.0;
    final Map<String, DailySalesPoint> trendMap = {};

    for (final entry in milkEntries) {
      totalMilkLitres += entry.totalQty;
      billedSales += entry.totalAmount;

      final dateKey = '${entry.date.year}-${entry.date.month}-${entry.date.day}';
      if (!trendMap.containsKey(dateKey)) {
        trendMap[dateKey] = DailySalesPoint(
          date: entry.date,
          milkLitres: entry.totalQty,
          salesAmount: entry.totalAmount,
        );
      } else {
        final existing = trendMap[dateKey]!;
        trendMap[dateKey] = DailySalesPoint(
          date: existing.date,
          milkLitres: existing.milkLitres + entry.totalQty,
          salesAmount: existing.salesAmount + entry.totalAmount,
        );
      }
    }

    // 2. Fetch Payments received in range locally
    final rawPayments = _localDb.query('payments', where: (p) {
      if (p['ownerId'] != ownerId) return false;
      final d = _parseDate(p['paymentDate']);
      if (d == null) return false;
      return d.isAfter(start.subtract(const Duration(seconds: 1))) &&
          d.isBefore(end.add(const Duration(seconds: 1)));
    });

    final payments = rawPayments
        .map((d) => PaymentModel.fromMap(d, (d['id'] ?? '').toString()))
        .where((p) => p.isPaid)
        .toList();

    double cashCollected = 0.0;
    for (final p in payments) {
      cashCollected += p.amount;
    }

    // 3. Fetch Expenses in range locally
    final rawExpenses = _localDb.query('expenses', where: (exp) {
      if (exp['ownerId'] != ownerId) return false;
      final d = _parseDate(exp['expenseDate']);
      if (d == null) return false;
      return d.isAfter(start.subtract(const Duration(seconds: 1))) &&
          d.isBefore(end.add(const Duration(seconds: 1)));
    });

    final expenses = rawExpenses.map((d) => ExpenseModel.fromMap(d, (d['id'] ?? '').toString())).toList();

    double totalExpenses = 0.0;
    final Map<String, double> categoryBreakdown = {};

    for (final exp in expenses) {
      totalExpenses += exp.amount;
      categoryBreakdown[exp.category] = (categoryBreakdown[exp.category] ?? 0.0) + exp.amount;
    }

    // 4. Fetch Customers outstanding dues locally
    final rawCustomers = _localDb.query('customers', where: (c) => c['ownerId'] == ownerId);
    final customers = rawCustomers.map((d) => CustomerModel.fromMap(d, (d['id'] ?? '').toString())).toList();

    double totalPendingDues = 0.0;
    for (final c in customers) {
      if (c.currentBalance > 0) {
        totalPendingDues += c.currentBalance;
      }
    }

    final sortedTrend = trendMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));

    return BusinessReportData(
      startDate: startDate,
      endDate: endDate,
      totalMilkLitres: totalMilkLitres,
      totalBilledSales: billedSales,
      totalCashCollected: cashCollected,
      totalExpenses: totalExpenses,
      netProfitOrLoss: cashCollected - totalExpenses,
      outstandingDues: totalPendingDues,
      salesTrend: sortedTrend,
      expenseCategoryBreakdown: categoryBreakdown,
    );
  }
}
