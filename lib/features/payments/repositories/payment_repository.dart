import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Customer submits payment intent / txn reference for verification
  Future<String> submitPaymentIntent({
    required String ownerId,
    required String customerId,
    required String customerName,
    required String customerPhone,
    String? customerUserId,
    String? billId,
    required double amount,
    required String paymentMethod,
    required String transactionRef,
    String notes = '',
  }) async {
    final paymentDoc = _firestore.collection('payments').doc();
    final payment = PaymentModel(
      id: paymentDoc.id,
      ownerId: ownerId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerUserId: customerUserId,
      billId: billId,
      amount: amount,
      paymentMethod: paymentMethod,
      transactionRef: transactionRef,
      status: 'PENDING',
      verifiedBy: 'PENDING_VERIFICATION',
      notes: notes,
      paymentDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await paymentDoc.set(payment.toMap());
    return paymentDoc.id;
  }

  /// Owner records verified payment (Cash or UPI confirmed by Owner)
  /// Atomically credits customer ledger, updates balance and bill status
  Future<void> recordAndVerifyPayment({
    required String ownerId,
    required String customerId,
    required String customerName,
    required String customerPhone,
    String? customerUserId,
    String? billId,
    required double amount,
    required String paymentMethod,
    required String transactionRef,
    String notes = '',
  }) async {
    final db = _firestore;
    final paymentDoc = db.collection('payments').doc();
    final custRef = db.collection('customers').doc(customerId);

    await db.runTransaction((transaction) async {
      final custDoc = await transaction.get(custRef);
      if (!custDoc.exists) throw Exception('Customer not found');

      final currentBalance = (custDoc.data()?['currentBalance'] ?? 0.0).toDouble();
      final newBalance = currentBalance - amount;

      // 1. Create Verified Payment record
      final now = DateTime.now();
      transaction.set(paymentDoc, {
        'id': paymentDoc.id,
        'ownerId': ownerId,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerUserId': customerUserId,
        'billId': billId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'transactionRef': transactionRef,
        'status': 'PAID',
        'verifiedBy': 'OWNER_MANUAL',
        'notes': notes,
        'paymentDate': now,
        'createdAt': now,
        'updatedAt': now,
      });

      // 2. Update Customer Balance
      transaction.update(custRef, {
        'currentBalance': newBalance,
        'lastPaymentDate': now,
        'lastPaymentAmount': amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Create Immutable Ledger Credit Entry
      final ledgerRef = db.collection('customer_ledgers').doc('ledger_pay_${paymentDoc.id}');
      transaction.set(ledgerRef, {
        'id': ledgerRef.id,
        'ownerId': ownerId,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerUserId': customerUserId,
        'type': 'CREDIT',
        'category': 'PAYMENT_RECEIVED',
        'amount': amount,
        'balanceBefore': currentBalance,
        'balanceAfter': newBalance,
        'paymentMethod': paymentMethod,
        'transactionRef': transactionRef,
        'referenceId': paymentDoc.id,
        'notes': 'Payment Received via $paymentMethod (Ref: $transactionRef). $notes',
        'transactionDate': now,
      });

      // 4. Update Bill if linked
      if (billId != null && billId.isNotEmpty) {
        final billRef = db.collection('monthly_bills').doc(billId);
        final billDoc = await transaction.get(billRef);
        if (billDoc.exists) {
          final billData = billDoc.data()!;
          final currentPaid = (billData['paidAmount'] ?? 0.0).toDouble();
          final finalPayable = (billData['finalPayable'] ?? 0.0).toDouble();
          final newPaid = currentPaid + amount;
          final remaining = finalPayable - newPaid;
          final newStatus = remaining <= 0 ? 'PAID' : 'PARTIALLY PAID';

          transaction.update(billRef, {
            'paidAmount': newPaid,
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 5. Audit Log
      final auditRef = db.collection('audit_logs').doc();
      transaction.set(auditRef, {
        'id': auditRef.id,
        'action': 'PAYMENT_RECORDED',
        'ownerId': ownerId,
        'customerId': customerId,
        'amount': amount,
        'details': 'Recorded $paymentMethod payment of ₹$amount for $customerName',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Owner approves a pending payment intent after bank check
  Future<void> approvePendingPayment(PaymentModel payment) async {
    final db = _firestore;
    final paymentRef = db.collection('payments').doc(payment.id);
    final custRef = db.collection('customers').doc(payment.customerId);

    await db.runTransaction((transaction) async {
      final custDoc = await transaction.get(custRef);
      if (!custDoc.exists) throw Exception('Customer not found');

      final currentBal = (custDoc.data()?['currentBalance'] ?? 0.0).toDouble();
      final newBal = currentBal - payment.amount;

      // 1. Mark as PAID
      transaction.update(paymentRef, {
        'status': 'PAID',
        'verifiedBy': 'OWNER_VERIFIED',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update Customer Balance
      transaction.update(custRef, {
        'currentBalance': newBal,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Ledger Entry
      final ledgerRef = db.collection('customer_ledgers').doc('ledger_pay_${payment.id}');
      transaction.set(ledgerRef, {
        'id': ledgerRef.id,
        'ownerId': payment.ownerId,
        'customerId': payment.customerId,
        'customerName': payment.customerName,
        'customerPhone': payment.customerPhone,
        'customerUserId': payment.customerUserId,
        'type': 'CREDIT',
        'category': 'PAYMENT_RECEIVED',
        'amount': payment.amount,
        'balanceBefore': currentBal,
        'balanceAfter': newBal,
        'paymentMethod': payment.paymentMethod,
        'transactionRef': payment.transactionRef,
        'referenceId': payment.id,
        'notes': 'Online UPI Payment verified by owner (Ref: ${payment.transactionRef})',
        'transactionDate': DateTime.now(),
      });
    });
  }

  /// Stream of all payments for owner
  Stream<List<PaymentModel>> getOwnerPaymentsStream(String ownerId) {
    return _firestore
        .collection('payments')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream of payments for a customer
  Stream<List<PaymentModel>> getCustomerPaymentsStream(String customerId) {
    return _firestore
        .collection('payments')
        .where('customerId', isEqualTo: customerId)
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}

