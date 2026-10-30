class PaymentModel {
  final String id;
  final String ownerId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? customerUserId;
  final String? billId;
  final double amount;
  final String paymentMethod; // 'UPI', 'CASH', 'BANK_TRANSFER'
  final String transactionRef;
  final String status; // 'PAID', 'PENDING', 'FAILED'
  final String verifiedBy; // 'OWNER_MANUAL', 'WEBHOOK_TRUSTED'
  final String notes;
  final DateTime paymentDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentModel({
    required this.id,
    required this.ownerId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerUserId,
    this.billId,
    required this.amount,
    required this.paymentMethod,
    required this.transactionRef,
    required this.status,
    required this.verifiedBy,
    this.notes = '',
    required this.paymentDate,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPaid => status == 'PAID';
  bool get isPending => status == 'PENDING';
  bool get isFailed => status == 'FAILED';

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerUserId: map['customerUserId'],
      billId: map['billId'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'UPI',
      transactionRef: map['transactionRef'] ?? '',
      status: map['status'] ?? 'PENDING',
      verifiedBy: map['verifiedBy'] ?? 'OWNER_MANUAL',
      notes: map['notes'] ?? '',
      paymentDate: map['paymentDate'] != null
          ? (map['paymentDate'] as dynamic).toDate()
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
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
      'billId': billId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'transactionRef': transactionRef,
      'status': status,
      'verifiedBy': verifiedBy,
      'notes': notes,
      'paymentDate': paymentDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

