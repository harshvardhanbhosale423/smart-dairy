import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import '../../../core/services/local_database_service.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService();

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
    final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
    final payment = PaymentModel(
      id: paymentId,
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

    // 1. Save locally
    await _localDb.set('payments', paymentId, payment.toMap());

    // 2. Safe cloud sync
    try {
      await _firestore.collection('payments').doc(paymentId).set(payment.toMap());
    } catch (_) {}

    return paymentId;
  }

  /// Owner records verified payment (Cash or UPI confirmed by Owner)
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
    final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
    final custDoc = _localDb.get('customers', customerId);

    double currentBalance = 0.0;
    if (custDoc != null) {
      currentBalance = (custDoc['currentBalance'] ?? 0.0).toDouble();
    }
    final newBalance = currentBalance - amount;
    final now = DateTime.now();

    final paymentData = {
      'id': paymentId,
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
    };

    // 1. Save locally
    await _localDb.set('payments', paymentId, paymentData);
    await _localDb.update('customers', customerId, {
      'currentBalance': newBalance,
      'lastPaymentDate': now,
      'lastPaymentAmount': amount,
      'updatedAt': Timestamp.now(),
    });

    final ledgerId = 'ledger_pay_$paymentId';
    await _localDb.set('customer_ledgers', ledgerId, {
      'id': ledgerId,
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
      'referenceId': paymentId,
      'notes': 'Payment Received via $paymentMethod (Ref: $transactionRef). $notes',
      'transactionDate': now,
    });

    if (billId != null && billId.isNotEmpty) {
      final billDoc = _localDb.get('monthly_bills', billId);
      if (billDoc != null) {
        final currentPaid = (billDoc['paidAmount'] ?? 0.0).toDouble();
        final finalPayable = (billDoc['finalPayable'] ?? 0.0).toDouble();
        final newPaid = currentPaid + amount;
        final remaining = finalPayable - newPaid;
        final newStatus = remaining <= 0 ? 'PAID' : 'PARTIALLY PAID';

        await _localDb.update('monthly_bills', billId, {
          'paidAmount': newPaid,
          'status': newStatus,
          'updatedAt': Timestamp.now(),
        });
      }
    }

    // 2. Safe cloud sync
    try {
      final db = _firestore;
      final paymentDoc = db.collection('payments').doc(paymentId);
      final custRef = db.collection('customers').doc(customerId);
      final ledgerRef = db.collection('customer_ledgers').doc(ledgerId);

      await db.runTransaction((transaction) async {
        transaction.set(paymentDoc, paymentData);
        transaction.update(custRef, {
          'currentBalance': newBalance,
          'lastPaymentDate': now,
          'lastPaymentAmount': amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(ledgerRef, {
          'id': ledgerId,
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
          'referenceId': paymentId,
          'notes': 'Payment Received via $paymentMethod (Ref: $transactionRef). $notes',
          'transactionDate': now,
        });
      });
    } catch (_) {}
  }

  /// Owner approves a pending payment intent after bank check
  Future<void> approvePendingPayment(PaymentModel payment) async {
    final custDoc = _localDb.get('customers', payment.customerId);
    double currentBal = 0.0;
    if (custDoc != null) {
      currentBal = (custDoc['currentBalance'] ?? 0.0).toDouble();
    }
    final newBal = currentBal - payment.amount;

    // 1. Update locally
    await _localDb.update('payments', payment.id, {
      'status': 'PAID',
      'verifiedBy': 'OWNER_VERIFIED',
      'updatedAt': Timestamp.now(),
    });

    await _localDb.update('customers', payment.customerId, {
      'currentBalance': newBal,
      'updatedAt': Timestamp.now(),
    });

    final ledgerId = 'ledger_pay_${payment.id}';
    await _localDb.set('customer_ledgers', ledgerId, {
      'id': ledgerId,
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

    // 2. Cloud sync
    try {
      final db = _firestore;
      final paymentRef = db.collection('payments').doc(payment.id);
      final custRef = db.collection('customers').doc(payment.customerId);
      final ledgerRef = db.collection('customer_ledgers').doc(ledgerId);

      await db.runTransaction((transaction) async {
        transaction.update(paymentRef, {
          'status': 'PAID',
          'verifiedBy': 'OWNER_VERIFIED',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(custRef, {
          'currentBalance': newBal,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(ledgerRef, {
          'id': ledgerId,
          'ownerId': payment.ownerId,
          'customerId': payment.customerId,
          'customerName': payment.customerName,
          'type': 'CREDIT',
          'category': 'PAYMENT_RECEIVED',
          'amount': payment.amount,
          'balanceBefore': currentBal,
          'balanceAfter': newBal,
          'transactionDate': DateTime.now(),
        });
      });
    } catch (_) {}
  }

  /// Stream of all payments for owner
  Stream<List<PaymentModel>> getOwnerPaymentsStream(String ownerId) {
    return _localDb.stream('payments', where: (p) => p['ownerId'] == ownerId).map((list) {
      final payments = list.map((doc) => PaymentModel.fromMap(doc, (doc['id'] ?? '').toString())).toList();
      payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      return payments;
    });
  }

  /// Stream of payments for a customer
  Stream<List<PaymentModel>> getCustomerPaymentsStream(String customerId) {
    return _localDb.stream('payments', where: (p) => p['customerId'] == customerId).map((list) {
      final payments = list.map((doc) => PaymentModel.fromMap(doc, (doc['id'] ?? '').toString())).toList();
      payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      return payments;
    });
  }
}
