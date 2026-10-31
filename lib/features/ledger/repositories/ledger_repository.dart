import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ledger_entry_model.dart';
import '../../../core/services/local_database_service.dart';

class LedgerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService();

  /// Stream of ledger transactions for a customer
  Stream<List<LedgerEntryModel>> getCustomerLedgerStream(String customerId) {
    return _localDb.stream('customer_ledgers', where: (l) => l['customerId'] == customerId).map((list) {
      final entries = list.map((doc) => LedgerEntryModel.fromMap(doc, (doc['id'] ?? '').toString())).toList();
      entries.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return entries;
    });
  }

  /// Record manual adjustment in ledger (e.g. discount, correction)
  Future<void> addAdjustment({
    required String ownerId,
    required String customerId,
    required String customerName,
    required double adjustmentAmount, // positive = discount/credit; negative = additional charge
    required String reason,
  }) async {
    final custDoc = _localDb.get('customers', customerId);
    double currentBal = 0.0;
    if (custDoc != null) {
      currentBal = (custDoc['currentBalance'] ?? 0.0).toDouble();
    }

    final isCredit = adjustmentAmount > 0;
    final newBalance = currentBal - adjustmentAmount;
    final ledgerId = 'ledger_adj_${DateTime.now().millisecondsSinceEpoch}';

    final ledgerData = {
      'id': ledgerId,
      'ownerId': ownerId,
      'customerId': customerId,
      'customerName': customerName,
      'type': isCredit ? 'CREDIT' : 'DEBIT',
      'category': 'ADJUSTMENT',
      'amount': adjustmentAmount.abs(),
      'balanceBefore': currentBal,
      'balanceAfter': newBalance,
      'notes': 'Adjustment: $reason',
      'transactionDate': Timestamp.now(),
    };

    // 1. Save locally
    await _localDb.update('customers', customerId, {
      'currentBalance': newBalance,
      'updatedAt': Timestamp.now(),
    });
    await _localDb.set('customer_ledgers', ledgerId, ledgerData);

    // 2. Cloud sync in background
    try {
      final db = _firestore;
      final custRef = db.collection('customers').doc(customerId);
      final ledgerRef = db.collection('customer_ledgers').doc(ledgerId);

      await db.runTransaction((transaction) async {
        transaction.update(custRef, {
          'currentBalance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(ledgerRef, ledgerData);
      });
    } catch (_) {}
  }
}
