import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ledger_entry_model.dart';

class LedgerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of ledger transactions for a customer
  Stream<List<LedgerEntryModel>> getCustomerLedgerStream(String customerId) {
    return _firestore
        .collection('customer_ledgers')
        .where('customerId', isEqualTo: customerId)
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LedgerEntryModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Record manual adjustment in ledger (e.g. discount, correction)
  Future<void> addAdjustment({
    required String ownerId,
    required String customerId,
    required String customerName,
    required double adjustmentAmount, // positive = discount/credit; negative = additional charge
    required String reason,
  }) async {
    final db = _firestore;
    final custRef = db.collection('customers').doc(customerId);
    final ledgerRef = db.collection('customer_ledgers').doc();
    final auditRef = db.collection('audit_logs').doc();

    await db.runTransaction((transaction) async {
      final custDoc = await transaction.get(custRef);
      double currentBal = 0.0;
      if (custDoc.exists) {
        currentBal = (custDoc.data()?['currentBalance'] ?? 0.0).toDouble();
      }

      // If adjustmentAmount > 0 (discount/credit), new balance is currentBal - adjustmentAmount
      final isCredit = adjustmentAmount > 0;
      final newBalance = currentBal - adjustmentAmount;

      transaction.update(custRef, {
        'currentBalance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(ledgerRef, {
        'id': ledgerRef.id,
        'ownerId': ownerId,
        'customerId': customerId,
        'customerName': customerName,
        'type': isCredit ? 'CREDIT' : 'DEBIT',
        'category': 'ADJUSTMENT',
        'amount': adjustmentAmount.abs(),
        'balanceBefore': currentBal,
        'balanceAfter': newBalance,
        'notes': 'Adjustment: $reason',
        'transactionDate': FieldValue.serverTimestamp(),
      });

      transaction.set(auditRef, {
        'id': auditRef.id,
        'action': 'LEDGER_ADJUSTMENT',
        'ownerId': ownerId,
        'customerId': customerId,
        'amount': adjustmentAmount,
        'details': 'Reason: $reason. Bal before: $currentBal, after: $newBalance',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }
}

