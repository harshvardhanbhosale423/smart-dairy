import 'dart:async';
import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';
import '../../customers/models/customer_model.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentRepository _repository = PaymentRepository();
  StreamSubscription? _sub;

  List<PaymentModel> _payments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<PaymentModel> get pendingPayments => _payments.where((p) => p.isPending).toList();
  double get totalCollected => _payments.where((p) => p.isPaid).fold(0.0, (s, p) => s + p.amount);

  void listenToOwnerPayments(String ownerId) {
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();

    _sub = _repository.getOwnerPaymentsStream(ownerId).listen(
      (list) {
        _payments = list;
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

  /// Owner records verified payment (Cash or UPI)
  Future<bool> recordPayment({
    required String ownerId,
    required CustomerModel customer,
    String? billId,
    required double amount,
    required String paymentMethod,
    required String transactionRef,
    String notes = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.recordAndVerifyPayment(
        ownerId: ownerId,
        customerId: customer.id,
        customerName: customer.name,
        customerPhone: customer.phone,
        customerUserId: customer.userId,
        billId: billId,
        amount: amount,
        paymentMethod: paymentMethod,
        transactionRef: transactionRef,
        notes: notes,
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

  /// Customer submits payment intent
  Future<String?> submitCustomerPayment({
    required String ownerId,
    required String customerId,
    required String customerName,
    required String customerPhone,
    String? customerUserId,
    String? billId,
    required double amount,
    required String transactionRef,
    String notes = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = await _repository.submitPaymentIntent(
        ownerId: ownerId,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerUserId: customerUserId,
        billId: billId,
        amount: amount,
        paymentMethod: 'UPI',
        transactionRef: transactionRef,
        notes: notes,
      );
      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Owner approves pending payment
  Future<bool> approvePayment(PaymentModel payment) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.approvePendingPayment(payment);
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

