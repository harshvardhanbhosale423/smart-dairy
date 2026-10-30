class ExpenseModel {
  final String id;
  final String ownerId;
  final String category; // 'cow_feed', 'green_fodder', 'dry_fodder', 'veterinary', 'medicines', etc.
  final double amount;
  final String description;
  final String paymentMethod; // 'CASH', 'UPI', 'BANK'
  final DateTime expenseDate;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.ownerId,
    required this.category,
    required this.amount,
    this.description = '',
    this.paymentMethod = 'CASH',
    required this.expenseDate,
    required this.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      category: map['category'] ?? 'cow_feed',
      amount: (map['amount'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'CASH',
      expenseDate: map['expenseDate'] != null
          ? (map['expenseDate'] as dynamic).toDate()
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'category': category,
      'amount': amount,
      'description': description,
      'paymentMethod': paymentMethod,
      'expenseDate': expenseDate,
      'createdAt': createdAt,
    };
  }
}

