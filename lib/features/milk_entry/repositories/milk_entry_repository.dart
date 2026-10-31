import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/milk_entry_model.dart';
import '../../../core/services/local_database_service.dart';

class MilkEntryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService();

  bool _isSameDay(dynamic dateVal, DateTime target) {
    DateTime? d;
    if (dateVal is Timestamp) {
      d = dateVal.toDate();
    } else if (dateVal is DateTime) {
      d = dateVal;
    } else if (dateVal is String) {
      d = DateTime.tryParse(dateVal);
    }
    if (d == null) return false;
    return d.year == target.year && d.month == target.month && d.day == target.day;
  }

  /// Check if an entry already exists for customer on given date
  Future<MilkEntryModel?> getExistingEntry({
    required String ownerId,
    required String customerId,
    required DateTime date,
  }) async {
    final list = _localDb.query('milk_entries', where: (e) {
      return e['ownerId'] == ownerId &&
          e['customerId'] == customerId &&
          _isSameDay(e['date'], date);
    });

    if (list.isNotEmpty) {
      final doc = list.first;
      return MilkEntryModel.fromMap(doc, (doc['id'] ?? '').toString());
    }

    try {
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
        final entry = MilkEntryModel.fromMap(doc.data(), doc.id);
        await _localDb.set('milk_entries', entry.id, doc.data());
        return entry;
      }
    } catch (_) {}

    return null;
  }

  /// Save daily milk entry (creates or updates, updates customer ledger balance atomically)
  Future<void> saveMilkEntry(MilkEntryModel entry) async {
    // 1. Get existing entry and customer data locally
    final existingDoc = _localDb.get('milk_entries', entry.id);
    final custDoc = _localDb.get('customers', entry.customerId);

    double prevEntryAmount = 0.0;
    if (existingDoc != null) {
      prevEntryAmount = (existingDoc['totalAmount'] ?? 0.0).toDouble();
    }

    double custBalance = 0.0;
    if (custDoc != null) {
      custBalance = (custDoc['currentBalance'] ?? 0.0).toDouble();
    }
    final newBalance = custBalance - prevEntryAmount + entry.totalAmount;

    // 2. Save milk entry locally
    await _localDb.set('milk_entries', entry.id, entry.toMap());

    // 3. Update customer balance locally
    await _localDb.update('customers', entry.customerId, {
      'currentBalance': newBalance,
      'updatedAt': Timestamp.now(),
    });

    // 4. Save ledger entry locally
    final ledgerId = 'ledger_${entry.id}';
    await _localDb.set('customer_ledgers', ledgerId, {
      'id': ledgerId,
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

    // 5. Cloud sync in background
    try {
      final db = _firestore;
      final entryRef = db.collection('milk_entries').doc(entry.id);
      final custRef = db.collection('customers').doc(entry.customerId);
      final ledgerRef = db.collection('customer_ledgers').doc(ledgerId);

      await db.runTransaction((transaction) async {
        transaction.set(entryRef, entry.toMap());
        transaction.update(custRef, {
          'currentBalance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(ledgerRef, {
          'id': ledgerId,
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
          'notes': 'Milk: ${entry.totalQty.toStringAsFixed(1)}L @ ₹${entry.ratePerLitre.toStringAsFixed(0)}/L',
          'transactionDate': entry.date,
        });
      });
    } catch (_) {}
  }

  /// Delete milk entry with full balance reconciliation
  Future<void> deleteMilkEntry(MilkEntryModel entry) async {
    final custDoc = _localDb.get('customers', entry.customerId);
    double custBalance = 0.0;
    if (custDoc != null) {
      custBalance = (custDoc['currentBalance'] ?? 0.0).toDouble();
    }
    final newBalance = custBalance - entry.totalAmount;

    // 1. Delete locally
    await _localDb.delete('milk_entries', entry.id);
    await _localDb.delete('customer_ledgers', 'ledger_${entry.id}');
    await _localDb.update('customers', entry.customerId, {
      'currentBalance': newBalance,
      'updatedAt': Timestamp.now(),
    });

    // 2. Cloud sync in background
    try {
      final db = _firestore;
      final entryRef = db.collection('milk_entries').doc(entry.id);
      final custRef = db.collection('customers').doc(entry.customerId);
      final ledgerRef = db.collection('customer_ledgers').doc('ledger_${entry.id}');

      await db.runTransaction((transaction) async {
        transaction.delete(entryRef);
        transaction.delete(ledgerRef);
        transaction.update(custRef, {
          'currentBalance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (_) {}
  }

  /// Stream of entries for a specific date (for Owner Daily entry screen)
  Stream<List<MilkEntryModel>> getEntriesForDate(String ownerId, DateTime date) {
    return _localDb.stream('milk_entries', where: (e) {
      return e['ownerId'] == ownerId && _isSameDay(e['date'], date);
    }).map((list) {
      return list.map((doc) => MilkEntryModel.fromMap(doc, (doc['id'] ?? '').toString())).toList();
    });
  }

  /// Stream of entries for a specific customer (for Customer screen or Ledger)
  Stream<List<MilkEntryModel>> getEntriesForCustomer(String customerId, {int limit = 60}) {
    return _localDb.stream('milk_entries', where: (e) {
      return e['customerId'] == customerId;
    }).map((list) {
      final entries = list.map((doc) => MilkEntryModel.fromMap(doc, (doc['id'] ?? '').toString())).toList();
      entries.sort((a, b) => b.date.compareTo(a.date));
      if (entries.length > limit) {
        return entries.sublist(0, limit);
      }
      return entries;
    });
  }

  /// Fetch entries for a customer in a given month/year (for Bill generation)
  Future<List<MilkEntryModel>> getCustomerEntriesForMonth({
    required String customerId,
    required int year,
    required int month,
  }) async {
    final list = _localDb.query('milk_entries', where: (e) {
      if (e['customerId'] != customerId) return false;
      final dateVal = e['date'];
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

    final entries = list.map((doc) => MilkEntryModel.fromMap(doc, (doc['id'] ?? '').toString())).toList();
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }
}
