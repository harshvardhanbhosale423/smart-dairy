import 'dart:async';
import 'package:flutter/material.dart';
import '../models/ledger_entry_model.dart';
import '../repositories/ledger_repository.dart';

class LedgerProvider extends ChangeNotifier {
  final LedgerRepository _repository = LedgerRepository();
  StreamSubscription? _sub;

  List<LedgerEntryModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<LedgerEntryModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalDebited => _transactions
      .where((t) => t.isDebit)
      .fold(0.0, (s, t) => s + t.amount);

  double get totalCredited => _transactions
      .where((t) => t.isCredit)
      .fold(0.0, (s, t) => s + t.amount);

  void listenToCustomerLedger(String customerId) {
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();

    _sub = _repository.getCustomerLedgerStream(customerId).listen(
      (list) {
        _transactions = list;
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

  Future<bool> addAdjustment({
    required String ownerId,
    required String customerId,
    required String customerName,
    required double amount,
    required String reason,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.addAdjustment(
        ownerId: ownerId,
        customerId: customerId,
        customerName: customerName,
        adjustmentAmount: amount,
        reason: reason,
      );
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

