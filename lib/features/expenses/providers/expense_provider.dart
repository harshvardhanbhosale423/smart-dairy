import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();
  StreamSubscription? _sub;

  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalExpenses => _expenses.fold(0.0, (s, e) => s + e.amount);

  void listenToExpenses(String ownerId) {
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();

    _sub = _repository.getExpensesStream(ownerId).listen(
      (list) {
        _expenses = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> addExpense({
    required String ownerId,
    required String category,
    required double amount,
    required String description,
    required String paymentMethod,
    required DateTime date,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final expense = ExpenseModel(
        id: const Uuid().v4(),
        ownerId: ownerId,
        category: category,
        amount: amount,
        description: description.trim(),
        paymentMethod: paymentMethod,
        expenseDate: date,
        createdAt: DateTime.now(),
      );

      await _repository.addExpense(expense);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpense(ExpenseModel expense) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.updateExpense(expense);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(ExpenseModel expense) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteExpense(expense);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

