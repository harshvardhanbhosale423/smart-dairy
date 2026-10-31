import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/monthly_bill_model.dart';
import '../services/billing_engine.dart';
import '../../customers/models/customer_model.dart';
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

    // 3. Find previous bill to get opening balance
    double previousBalance = 0.0;
    final prevMonthDate = DateTime(year, month - 1, 1);
    final prevYm = '${prevMonthDate.year}-${prevMonthDate.month.toString().padLeft(2, '0')}';
    final prevBill = await getExistingBill(customerId: customer.id, yearMonth: prevYm);

    if (prevBill != null) {
      previousBalance = prevBill.finalPayable;
    } else {
      previousBalance = customer.currentBalance;
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

  /// Auto-generate monthly bills for all active customers of owner
  Future<List<MonthlyBillModel>> generateBillsForAllCustomers({
    required String ownerId,
    required List<CustomerModel> customers,
    required int year,
    required int month,
  }) async {
    final generatedBills = <MonthlyBillModel>[];

    for (final cust in customers) {
      if (cust.isActive || cust.isPaused) {
        final bill = await generateBillForCustomer(
          customer: cust,
          year: year,
          month: month,
        );
        generatedBills.add(bill);
      }
    }

    return generatedBills;
  }

  /// Stream of all monthly bills for an owner in a specific month
  Stream<List<MonthlyBillModel>> getOwnerBillsForMonthStream({
    required String ownerId,
    required String yearMonth,
  }) {
    return _localDb.stream('monthly_bills', where: (b) {
      return b['ownerId'] == ownerId && b['yearMonth'] == yearMonth;
    }).map((list) {
      return list.map((doc) => MonthlyBillModel.fromMap(doc, (doc['id'] ?? '').toString())).toList();
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
