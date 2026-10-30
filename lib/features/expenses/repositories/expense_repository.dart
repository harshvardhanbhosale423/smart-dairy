import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of expenses for an owner
  Stream<List<ExpenseModel>> getExpensesStream(String ownerId) {
    return _firestore
        .collection('expenses')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('expenseDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Add new expense
  Future<void> addExpense(ExpenseModel expense) async {
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
  }

  /// Update expense
  Future<void> updateExpense(ExpenseModel expense) async {
    await _firestore
        .collection('expenses')
        .doc(expense.id)
        .update(expense.toMap());
  }

  /// Delete expense
  Future<void> deleteExpense(ExpenseModel expense) async {
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
  }

  /// Fetch expenses for a specific month
  Future<List<ExpenseModel>> getExpensesForMonth({
    required String ownerId,
    required int year,
    required int month,
  }) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    final snapshot = await _firestore
        .collection('expenses')
        .where('ownerId', isEqualTo: ownerId)
        .where('expenseDate', isGreaterThanOrEqualTo: startOfMonth)
        .where('expenseDate', isLessThanOrEqualTo: endOfMonth)
        .get();

    return snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}

