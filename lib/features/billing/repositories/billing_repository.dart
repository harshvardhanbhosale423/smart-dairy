import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/monthly_bill_model.dart';
import '../services/billing_engine.dart';
import '../../customers/models/customer_model.dart';
import '../../milk_entry/repositories/milk_entry_repository.dart';
import '../../payments/models/payment_model.dart';

class BillingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MilkEntryRepository _milkRepo = MilkEntryRepository();

  /// Check if bill already generated for customer & month
  Future<MonthlyBillModel?> getExistingBill({
    required String customerId,
    required String yearMonth,
  }) async {
    final snapshot = await _firestore
        .collection('monthly_bills')
        .where('customerId', isEqualTo: customerId)
        .where('yearMonth', isEqualTo: yearMonth)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return MonthlyBillModel.fromMap(doc.data(), doc.id);
    }
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

    // 2. Fetch payments received in this month
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    final paymentSnap = await _firestore
        .collection('payments')
        .where('customerId', isEqualTo: customer.id)
        .where('paymentDate', isGreaterThanOrEqualTo: startOfMonth)
        .where('paymentDate', isLessThanOrEqualTo: endOfMonth)
        .get();

    final payments = paymentSnap.docs
        .map((d) => PaymentModel.fromMap(d.data(), d.id))
        .toList();

    // 3. Find previous bill to get opening balance (or use customer's previous balance)
    double previousBalance = 0.0;
    final prevMonthDate = DateTime(year, month - 1, 1);
    final prevYm = '$prevMonthDate.year-${prevMonthDate.month.toString().padLeft(2, '0')}';
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

    // Save to Firestore
    await _firestore.collection('monthly_bills').doc(billDocId).set(bill.toMap());

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
    return _firestore
        .collection('monthly_bills')
        .where('ownerId', isEqualTo: ownerId)
        .where('yearMonth', isEqualTo: yearMonth)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MonthlyBillModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream of bills for a customer
  Stream<List<MonthlyBillModel>> getCustomerBillsStream(String customerId) {
    return _firestore
        .collection('monthly_bills')
        .where('customerId', isEqualTo: customerId)
        .orderBy('yearMonth', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MonthlyBillModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}

