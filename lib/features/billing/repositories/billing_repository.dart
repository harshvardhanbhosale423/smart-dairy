import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/monthly_bill_model.dart';
import '../models/month_bill_summary.dart';
import '../services/billing_engine.dart';
import '../../customers/models/customer_model.dart';
import '../../milk_entry/models/milk_entry_model.dart';
import '../../milk_entry/repositories/milk_entry_repository.dart';
import '../../payments/models/payment_model.dart';
import '../../../core/services/local_database_service.dart';

class BillingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final MilkEntryRepository _milkRepo = MilkEntryRepository();

  /// Check if bill already generated for customer & month
  Future<MonthlyBillModel?> getExistingBill({
    required String customerId,
    required String yearMonth,
  }) async {
    final list = _localDb.query('monthly_bills', where: (b) {
      return b['customerId'] == customerId && b['yearMonth'] == yearMonth;
    });

    if (list.isNotEmpty) {
      final doc = list.first;
      return MonthlyBillModel.fromMap(doc, (doc['id'] ?? '').toString());
    }

    try {
      final snapshot = await _firestore
          .collection('monthly_bills')
          .where('customerId', isEqualTo: customerId)
          .where('yearMonth', isEqualTo: yearMonth)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final bill = MonthlyBillModel.fromMap(doc.data(), doc.id);
        await _localDb.set('monthly_bills', bill.id, doc.data());
        return bill;
      }
    } catch (_) {}

    return null;
  }

  /// Get month-by-month historical breakdown for a customer
  Future<List<MonthBillSummary>> getCustomerMonthlyBreakdown(String customerId) async {
    // 1. Fetch all milk entries for this customer
    final allEntries = await _milkRepo.getEntriesForCustomer(customerId, limit: 1000).first;

    // 2. Group milk entries by 'YYYY-MM'
    final Map<String, List<MilkEntryModel>> monthMap = {};
    for (final e in allEntries) {
      final ym = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
      monthMap.putIfAbsent(ym, () => []).add(e);
    }

    // 3. Fetch all payments for this customer
    final paymentDocs = _localDb.query('payments', where: (p) => p['customerId'] == customerId);
    final Map<String, double> monthPayments = {};
    for (final p in paymentDocs) {
      final dateVal = p['paymentDate'];
      DateTime? d;
      if (dateVal is Timestamp) {
        d = dateVal.toDate();
      } else if (dateVal is DateTime) {
        d = dateVal;
      } else if (dateVal is String) {
        d = DateTime.tryParse(dateVal);
      }
      if (d != null) {
        final ym = '${d.year}-${d.month.toString().padLeft(2, '0')}';
        final amt = (p['amount'] ?? 0.0).toDouble();
        monthPayments[ym] = (monthPayments[ym] ?? 0.0) + amt;
      }
    }

    // 4. Fetch existing bills for this customer
    final billDocs = _localDb.query('monthly_bills', where: (b) => b['customerId'] == customerId);
    final Map<String, MonthlyBillModel> existingBills = {};
    for (final b in billDocs) {
      final bill = MonthlyBillModel.fromMap(b, (b['id'] ?? '').toString());
      existingBills[bill.yearMonth] = bill;
    }

    // 5. Build summary list
    final List<MonthBillSummary> summaries = [];
    final sortedKeys = monthMap.keys.toList()..sort((a, b) => b.compareTo(a)); // Descending order

    for (final ym in sortedKeys) {
      final entries = monthMap[ym]!;
      final parts = ym.split('-');
      final year = int.tryParse(parts[0]) ?? DateTime.now().year;
      final month = int.tryParse(parts[1]) ?? DateTime.now().month;
      final paid = monthPayments[ym] ?? 0.0;
      final existing = existingBills[ym];

      // Calculate applied rate (from first entry or customer default)
      final rate = entries.isNotEmpty ? entries.first.ratePerLitre : 60.0;

      summaries.add(
        MonthBillSummary.fromEntries(
          year: year,
          month: month,
          appliedRate: rate,
          monthEntries: entries,
          paymentsReceived: paid,
          isAlreadyBilled: existing != null,
          existingBillId: existing?.id,
        ),
      );
    }

    return summaries;
  }

  /// Generate or re-generate monthly bill for single customer
  Future<MonthlyBillModel> generateBillForCustomer({
    required CustomerModel customer,
    required int year,
    required int month,
  }) async {
    final ym = '$year-${month.toString().padLeft(2, '0')}';
    final existing = await getExistingBill(customerId: customer.id, yearMonth: ym);
    final billDocId = existing?.id ?? 'bill_${customer.id}_$ym';

    // 1. Fetch milk entries for this month
    final entries = await _milkRepo.getCustomerEntriesForMonth(
      customerId: customer.id,
      year: year,
      month: month,
    );

    // 2. Fetch payments received in this month locally
    final paymentList = _localDb.query('payments', where: (p) {
      if (p['customerId'] != customer.id) return false;
      final dateVal = p['paymentDate'];
      DateTime? d;
      if (dateVal is Timestamp) {
        d = dateVal.toDate();
      } else if (dateVal is DateTime) {
        d = dateVal;
      } else if (dateVal is String) {
        d = DateTime.tryParse(dateVal);
      }
      if (d == null) return false;
      return d.year == year && d.month == month;
    });

    final payments = paymentList.map((d) => PaymentModel.fromMap(d, (d['id'] ?? '').toString())).toList();

    // 3. Opening balance calculation (fixed double-counting bug)
    double previousBalance = 0.0;
    final prevMonthDate = DateTime(year, month - 1, 1);
    final prevYm = '${prevMonthDate.year}-${prevMonthDate.month.toString().padLeft(2, '0')}';
    final prevBill = await getExistingBill(customerId: customer.id, yearMonth: prevYm);

    if (prevBill != null) {
      previousBalance = prevBill.finalPayable;
    } else {
      final thisMonthTotal = entries.fold<double>(0.0, (s, e) => s + e.totalAmount);
      final opening = customer.currentBalance - thisMonthTotal;
      previousBalance = opening > 0 ? opening : 0.0;
    }

    final bill = BillingEngine.calculateCustomerMonthlyBill(
      billId: billDocId,
      customer: customer,
      year: year,
      month: month,
      monthMilkEntries: entries,
      monthPayments: payments,
      previousOutstandingBalance: previousBalance,
    );

    // 4. Save locally
    await _localDb.set('monthly_bills', billDocId, bill.toMap());

    // 5. Cloud sync in background
    try {
      await _firestore.collection('monthly_bills').doc(billDocId).set(bill.toMap());
    } catch (_) {}

    return bill;
  }

  /// Generate a custom combined bill for selected months
  Future<MonthlyBillModel> generateMultiMonthBill({
    required CustomerModel customer,
    required List<MonthBillSummary> selectedMonths,
  }) async {
    if (selectedMonths.isEmpty) {
      throw 'किमान एक महिना निवडणे आवश्यक आहे!';
    }

    // Sort selected months ascending
    selectedMonths.sort((a, b) => a.yearMonth.compareTo(b.yearMonth));

    double totalLitres = 0.0;
    double totalCharges = 0.0;
    double totalPaid = 0.0;
    final allEntries = <MilkEntryModel>[];

    for (final s in selectedMonths) {
      totalLitres += s.totalLitres;
      totalCharges += s.milkCharges;
      totalPaid += s.paymentsReceived;
      allEntries.addAll(s.entries);
    }

    final netPayable = totalCharges - totalPaid;
    final now = DateTime.now();

    String ymTitle;
    int targetMonth = 0;
    int targetYear = selectedMonths.last.year;

    if (selectedMonths.length == 1) {
      ymTitle = selectedMonths.first.yearMonth;
      targetMonth = selectedMonths.first.month;
      targetYear = selectedMonths.first.year;
    } else {
      final first = selectedMonths.first.monthNameMr;
      final last = selectedMonths.last.monthNameMr;
      ymTitle = '$first ते $last';
    }

    final billDocId = 'bill_${customer.id}_${DateTime.now().millisecondsSinceEpoch}';

    final bill = MonthlyBillModel(
      id: billDocId,
      ownerId: customer.ownerId,
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      customerUserId: customer.userId,
      yearMonth: ymTitle,
      month: targetMonth,
      year: targetYear,
      totalMilkLitres: totalLitres,
      appliedRate: customer.milkRate,
      currentMonthMilkCharges: totalCharges,
      previousBalance: 0.0,
      paidAmount: totalPaid,
      finalPayable: netPayable > 0 ? netPayable : 0.0,
      status: netPayable <= 0 ? 'PAID' : (totalPaid > 0 ? 'PARTIALLY PAID' : 'UNPAID'),
      createdAt: now,
      updatedAt: now,
    );

    // Save locally
    await _localDb.set('monthly_bills', billDocId, bill.toMap());

    // Cloud sync in background
    try {
      await _firestore.collection('monthly_bills').doc(billDocId).set(bill.toMap());
    } catch (_) {}

    return bill;
  }

  /// Delete a bill
  Future<void> deleteBill(String billId) async {
    await _localDb.delete('monthly_bills', billId);
    try {
      await _firestore.collection('monthly_bills').doc(billId).delete();
    } catch (_) {}
  }

  /// Stream of all monthly bills for an owner in a specific month or all months
  Stream<List<MonthlyBillModel>> getOwnerBillsStream({
    required String ownerId,
    String? yearMonthFilter,
  }) {
    return _localDb.stream('monthly_bills', where: (b) {
      if (b['ownerId'] != ownerId) return false;
      if (yearMonthFilter != null && yearMonthFilter.isNotEmpty) {
        return b['yearMonth'] == yearMonthFilter;
      }
      return true;
    }).map((list) {
      final bills = list.map((doc) => MonthlyBillModel.fromMap(doc, (doc['id'] ?? '').toString())).toList();
      bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bills;
    });
  }

  /// Stream of bills for a customer
  Stream<List<MonthlyBillModel>> getCustomerBillsStream(String customerId) {
    return _localDb.stream('monthly_bills', where: (b) {
      return b['customerId'] == customerId;
    }).map((list) {
      final bills = list.map((doc) => MonthlyBillModel.fromMap(doc, (doc['id'] ?? '').toString())).toList();
      bills.sort((a, b) => b.yearMonth.compareTo(a.yearMonth));
      return bills;
    });
  }
}
