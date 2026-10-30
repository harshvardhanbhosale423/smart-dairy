class MilkEntryModel {
  final String id;
  final String ownerId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? customerUserId;
  final DateTime date;
  final double morningQty;
  final double eveningQty;
  final double totalQty;
  final double ratePerLitre;
  final double totalAmount;
  final bool isZeroMilk;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  MilkEntryModel({
    required this.id,
    required this.ownerId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerUserId,
    required this.date,
    required this.morningQty,
    required this.eveningQty,
    required this.totalQty,
    required this.ratePerLitre,
    required this.totalAmount,
    this.isZeroMilk = false,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory helper that automatically calculates totalQty & totalAmount
  factory MilkEntryModel.create({
    required String id,
    required String ownerId,
    required String customerId,
    required String customerName,
    required String customerPhone,
    String? customerUserId,
    required DateTime date,
    required double morningQty,
    required double eveningQty,
    required double ratePerLitre,
    bool isZeroMilk = false,
    String notes = '',
  }) {
    final effectiveMorning = isZeroMilk ? 0.0 : morningQty;
    final effectiveEvening = isZeroMilk ? 0.0 : eveningQty;
    final total = effectiveMorning + effectiveEvening;
    final amount = isZeroMilk ? 0.0 : (total * ratePerLitre);

    final now = DateTime.now();
    return MilkEntryModel(
      id: id,
      ownerId: ownerId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerUserId: customerUserId,
      date: DateTime(date.year, date.month, date.day),
      morningQty: effectiveMorning,
      eveningQty: effectiveEvening,
      totalQty: total,
      ratePerLitre: ratePerLitre,
      totalAmount: amount,
      isZeroMilk: isZeroMilk,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory MilkEntryModel.fromMap(Map<String, dynamic> map, String id) {
    return MilkEntryModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerUserId: map['customerUserId'],
      date: map['date'] != null
          ? (map['date'] as dynamic).toDate()
          : DateTime.now(),
      morningQty: (map['morningQty'] ?? 0.0).toDouble(),
      eveningQty: (map['eveningQty'] ?? 0.0).toDouble(),
      totalQty: (map['totalQty'] ?? 0.0).toDouble(),
      ratePerLitre: (map['ratePerLitre'] ?? 0.0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      isZeroMilk: map['isZeroMilk'] ?? false,
      notes: map['notes'] ?? '',
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
      'date': date,
      'morningQty': morningQty,
      'eveningQty': eveningQty,
      'totalQty': totalQty,
      'ratePerLitre': ratePerLitre,
      'totalAmount': totalAmount,
      'isZeroMilk': isZeroMilk,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

