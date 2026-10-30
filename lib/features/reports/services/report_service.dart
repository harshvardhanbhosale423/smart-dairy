import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_data.dart';
import '../../milk_entry/models/milk_entry_model.dart';
import '../../payments/models/payment_model.dart';
import '../../expenses/models/expense_model.dart';
import '../../customers/models/customer_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate comprehensive business report for a given date range
  Future<BusinessReportData> generateReport({
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // 1. Fetch Milk Entries in range
    final milkSnap = await _firestore
        .collection('milk_entries')
        .where('ownerId', isEqualTo: ownerId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .get();

    final milkEntries = milkSnap.docs
        .map((d) => MilkEntryModel.fromMap(d.data(), d.id))
        .toList();

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

    // 2. Fetch Payments received in range
    final paymentSnap = await _firestore
        .collection('payments')
        .where('ownerId', isEqualTo: ownerId)
        .where('paymentDate', isGreaterThanOrEqualTo: start)
        .where('paymentDate', isLessThanOrEqualTo: end)
        .get();

    final payments = paymentSnap.docs
        .map((d) => PaymentModel.fromMap(d.data(), d.id))
        .where((p) => p.isPaid)
        .toList();

    double cashCollected = 0.0;
    for (final p in payments) {
      cashCollected += p.amount;
    }

    // 3. Fetch Expenses in range
    final expenseSnap = await _firestore
        .collection('expenses')
        .where('ownerId', isEqualTo: ownerId)
        .where('expenseDate', isGreaterThanOrEqualTo: start)
        .where('expenseDate', isLessThanOrEqualTo: end)
        .get();

    final expenses = expenseSnap.docs
        .map((d) => ExpenseModel.fromMap(d.data(), d.id))
        .toList();

    double totalExpenses = 0.0;
    final Map<String, double> categoryBreakdown = {};

    for (final exp in expenses) {
      totalExpenses += exp.amount;
      categoryBreakdown[exp.category] = (categoryBreakdown[exp.category] ?? 0.0) + exp.amount;
    }

    // 4. Fetch Customers outstanding dues
    final custSnap = await _firestore
        .collection('customers')
        .where('ownerId', isEqualTo: ownerId)
        .get();

    double totalOutstanding = 0.0;
    for (final d in custSnap.docs) {
      final bal = (d.data()['currentBalance'] ?? 0.0).toDouble();
      if (bal > 0) totalOutstanding += bal;
    }

    // 5. Profit calculations
    final netCashProfit = cashCollected - totalExpenses;
    final netBilledProfit = billedSales - totalExpenses;

    final trendList = trendMap.values.toList();
    trendList.sort((a, b) => a.date.compareTo(b.date));

    return BusinessReportData(
      startDate: start,
      endDate: end,
      totalMilkDeliveredLitres: totalMilkLitres,
      billedSalesAmount: billedSales,
      actualCashCollected: cashCollected,
      outstandingDues: totalOutstanding,
      totalExpenses: totalExpenses,
      netCashProfit: netCashProfit,
      netBilledProfit: netBilledProfit,
      categoryWiseExpenses: categoryBreakdown,
      dailySalesTrend: trendList,
    );
  }
}

