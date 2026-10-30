class LedgerEntryModel {
  final String id;
  final String ownerId;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerUserId;
  final String type; // 'DEBIT' (Customer owes) or 'CREDIT' (Customer paid)
  final String category; // 'DAILY_MILK', 'MONTHLY_BILL', 'PAYMENT_RECEIVED', 'ADJUSTMENT'
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? paymentMethod; // 'UPI', 'CASH', 'BANK_TRANSFER'
  final String? transactionRef;
  final String? referenceId; // linked milk entry id, bill id or payment id
  final String notes;
  final DateTime transactionDate;

  LedgerEntryModel({
    required this.id,
    required this.ownerId,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerUserId,
    required this.type,
    required this.category,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.paymentMethod,
    this.transactionRef,
    this.referenceId,
    this.notes = '',
    required this.transactionDate,
  });

  bool get isDebit => type == 'DEBIT';
  bool get isCredit => type == 'CREDIT';

  factory LedgerEntryModel.fromMap(Map<String, dynamic> map, String id) {
    return LedgerEntryModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'],
      customerUserId: map['customerUserId'],
      type: map['type'] ?? 'DEBIT',
      category: map['category'] ?? 'DAILY_MILK',
      amount: (map['amount'] ?? 0.0).toDouble(),
      balanceBefore: (map['balanceBefore'] ?? 0.0).toDouble(),
      balanceAfter: (map['balanceAfter'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'],
      transactionRef: map['transactionRef'],
      referenceId: map['referenceId'],
      notes: map['notes'] ?? '',
      transactionDate: map['transactionDate'] != null
          ? (map['transactionDate'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerUserId': customerUserId,
      'type': type,
      'category': category,
      'amount': amount,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'paymentMethod': paymentMethod,
      'transactionRef': transactionRef,
      'referenceId': referenceId,
      'notes': notes,
      'transactionDate': transactionDate,
    };
  }
}

