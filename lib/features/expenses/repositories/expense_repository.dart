import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import '../../../core/services/local_database_service.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService();

  /// Stream of expenses for an owner
  Stream<List<ExpenseModel>> getExpensesStream(String ownerId) {
    return _localDb.stream('expenses', where: (e) => e['ownerId'] == ownerId).map((list) {
      final expenses = list.map((doc) => ExpenseModel.fromMap(doc, (doc['id'] ?? '').toString())).toList();
      expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      return expenses;
    });
  }

  /// Add new expense
  Future<void> addExpense(ExpenseModel expense) async {
    // 1. Save locally
    await _localDb.set('expenses', expense.id, expense.toMap());

    // 2. Safe cloud sync
    try {
      final batch = _firestore.batch();
      final expenseRef = _firestore.collection('expenses').doc(expense.id);
      batch.set(expenseRef, expense.toMap());

      final auditRef = _firestore.collection('audit_logs').doc();
      batch.set(auditRef, {
        'id': auditRef.id,
        'action': 'EXPENSE_ADDED',
        'ownerId': expense.ownerId,
        'amount': expense.amount,
        'details': '${expense.category} expense of ₹${expense.amount}: ${expense.description}',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (_) {}
  }

  /// Update expense
  Future<void> updateExpense(ExpenseModel expense) async {
    await _localDb.update('expenses', expense.id, expense.toMap());

    try {
      await _firestore
          .collection('expenses')
          .doc(expense.id)
          .update(expense.toMap());
    } catch (_) {}
  }

  /// Delete expense
  Future<void> deleteExpense(ExpenseModel expense) async {
    await _localDb.delete('expenses', expense.id);

    try {
      final batch = _firestore.batch();
      batch.delete(_firestore.collection('expenses').doc(expense.id));

      final auditRef = _firestore.collection('audit_logs').doc();
      batch.set(auditRef, {
        'id': auditRef.id,
        'action': 'EXPENSE_DELETED',
        'ownerId': expense.ownerId,
        'amount': expense.amount,
        'details': 'Deleted ${expense.category} expense of ₹${expense.amount}',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (_) {}
  }

  /// Fetch expenses for a specific month
  Future<List<ExpenseModel>> getExpensesForMonth({
    required String ownerId,
    required int year,
    required int month,
  }) async {
    final list = _localDb.query('expenses', where: (e) {
      if (e['ownerId'] != ownerId) return false;
      final dateVal = e['expenseDate'];
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

    final expenses = list.map((doc) => ExpenseModel.fromMap(doc, (doc['id'] ?? '').toString())).toList();
    expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return expenses;
  }
}
