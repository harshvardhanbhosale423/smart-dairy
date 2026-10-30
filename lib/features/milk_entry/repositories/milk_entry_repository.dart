import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/milk_entry_model.dart';

class MilkEntryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if an entry already exists for customer on given date
  Future<MilkEntryModel?> getExistingEntry({
    required String ownerId,
    required String customerId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection('milk_entries')
        .where('ownerId', isEqualTo: ownerId)
        .where('customerId', isEqualTo: customerId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return MilkEntryModel.fromMap(doc.data(), doc.id);
    }
    return null;
  }

  /// Save daily milk entry (creates or updates, updates customer ledger balance atomically)
  Future<void> saveMilkEntry(MilkEntryModel entry) async {
    final db = _firestore;
    final entryRef = db.collection('milk_entries').doc(entry.id);
    final custRef = db.collection('customers').doc(entry.customerId);

    await db.runTransaction((transaction) async {
      final existingDoc = await transaction.get(entryRef);
      final custDoc = await transaction.get(custRef);

      double prevEntryAmount = 0.0;
      if (existingDoc.exists) {
        prevEntryAmount = (existingDoc.data()?['totalAmount'] ?? 0.0).toDouble();
      }

      // Customer current balance adjustment:
      // Remove prevEntryAmount, add new entry.totalAmount
      double custBalance = 0.0;
      if (custDoc.exists) {
        custBalance = (custDoc.data()?['currentBalance'] ?? 0.0).toDouble();
      }
      final newBalance = custBalance - prevEntryAmount + entry.totalAmount;

      // 1. Write milk entry
      transaction.set(entryRef, entry.toMap());

      // 2. Update customer balance
      transaction.update(custRef, {
        'currentBalance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Create or update Ledger entry
      final ledgerRef = db.collection('customer_ledgers').doc('ledger_${entry.id}');
      transaction.set(ledgerRef, {
        'id': ledgerRef.id,
        'ownerId': entry.ownerId,
        'customerId': entry.customerId,
        'customerName': entry.customerName,
        'customerPhone': entry.customerPhone,
        'customerUserId': entry.customerUserId,
        'type': 'DEBIT',
        'category': 'DAILY_MILK',
        'amount': entry.totalAmount,
        'balanceBefore': custBalance,
        'balanceAfter': newBalance,
        'referenceId': entry.id,
        'notes': 'Milk: ${entry.totalQty.toStringAsFixed(1)}L @ ₹${entry.ratePerLitre.toStringAsFixed(0)}/L (${entry.notes})',
        'transactionDate': entry.date,
      });

      // 4. Audit Log
      final auditRef = db.collection('audit_logs').doc();
      transaction.set(auditRef, {
        'id': auditRef.id,
        'action': existingDoc.exists ? 'MILK_ENTRY_UPDATED' : 'MILK_ENTRY_CREATED',
        'ownerId': entry.ownerId,
        'customerId': entry.customerId,
        'amount': entry.totalAmount,
        'details': 'Entry for ${entry.customerName} on ${entry.date}: ${entry.totalQty}L',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Delete milk entry with full balance reconciliation and audit record
  Future<void> deleteMilkEntry(MilkEntryModel entry) async {
    final db = _firestore;
    final entryRef = db.collection('milk_entries').doc(entry.id);
    final custRef = db.collection('customers').doc(entry.customerId);
    final ledgerRef = db.collection('customer_ledgers').doc('ledger_${entry.id}');

    await db.runTransaction((transaction) async {
      final custDoc = await transaction.get(custRef);
      double custBalance = 0.0;
      if (custDoc.exists) {
        custBalance = (custDoc.data()?['currentBalance'] ?? 0.0).toDouble();
      }
      final newBalance = custBalance - entry.totalAmount;

      transaction.delete(entryRef);
      transaction.delete(ledgerRef);

      transaction.update(custRef, {
        'currentBalance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final auditRef = db.collection('audit_logs').doc();
      transaction.set(auditRef, {
        'id': auditRef.id,
        'action': 'MILK_ENTRY_DELETED',
        'ownerId': entry.ownerId,
        'customerId': entry.customerId,
        'amount': entry.totalAmount,
        'details': 'Deleted entry of ${entry.totalQty}L for ${entry.customerName} on ${entry.date}',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Stream of entries for a specific date (for Owner Daily entry screen)
  Stream<List<MilkEntryModel>> getEntriesForDate(String ownerId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('milk_entries')
        .where('ownerId', isEqualTo: ownerId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MilkEntryModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream of entries for a specific customer (for Customer screen or Ledger)
  Stream<List<MilkEntryModel>> getEntriesForCustomer(String customerId, {int limit = 60}) {
    return _firestore
        .collection('milk_entries')
        .where('customerId', isEqualTo: customerId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MilkEntryModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Fetch entries for a customer in a given month/year (for Bill generation)
  Future<List<MilkEntryModel>> getCustomerEntriesForMonth({
    required String customerId,
    required int year,
    required int month,
  }) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    final snapshot = await _firestore
        .collection('milk_entries')
        .where('customerId', isEqualTo: customerId)
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThanOrEqualTo: endOfMonth)
        .orderBy('date', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => MilkEntryModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}

