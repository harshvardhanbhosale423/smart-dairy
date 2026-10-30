import '../../core/utils/date_formatter.dart';

class MonthlyBillModel {
  final String id;
  final String ownerId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? customerUserId;
  final String yearMonth; // '2026-10'
  final int month;
  final int year;
  final double totalMilkLitres;
  final double appliedRate;
  final double currentMonthMilkCharges;
  final double previousBalance;
  final double paidAmount;
  final double finalPayable; // Previous + Current - Paid
  final String status; // 'PAID', 'UNPAID', 'PARTIALLY PAID'
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyBillModel({
    required this.id,
    required this.ownerId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerUserId,
    required this.yearMonth,
    required this.month,
    required this.year,
    required this.totalMilkLitres,
    required this.appliedRate,
    required this.currentMonthMilkCharges,
    required this.previousBalance,
    required this.paidAmount,
    required this.finalPayable,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPaid => status == 'PAID';
  bool get isUnpaid => status == 'UNPAID';
  bool get isPartial => status == 'PARTIALLY PAID';

  String get monthNameMr => '${DateFormatter.marathiMonths[month - 1]} $year';
  String get monthNameEn => '${DateFormatter.formatMonthYear(DateTime(year, month))}';

  factory MonthlyBillModel.calculate({
    required String id,
    required String ownerId,
    required String customerId,
    required String customerName,
    required String customerPhone,
    String? customerUserId,
    required int year,
    required int month,
    required double totalMilkLitres,
    required double appliedRate,
    required double previousBalance,
    required double paidAmount,
  }) {
    final charges = totalMilkLitres * appliedRate;
    final totalPayable = previousBalance + charges - paidAmount;
    final status = totalPayable <= 0
        ? 'PAID'
        : (paidAmount > 0 ? 'PARTIALLY PAID' : 'UNPAID');

    final ym = '$year-${month.toString().padLeft(2, '0')}';
    final now = DateTime.now();

    return MonthlyBillModel(
      id: id,
      ownerId: ownerId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerUserId: customerUserId,
      yearMonth: ym,
      month: month,
      year: year,
      totalMilkLitres: totalMilkLitres,
      appliedRate: appliedRate,
      currentMonthMilkCharges: charges,
      previousBalance: previousBalance,
      paidAmount: paidAmount,
      finalPayable: totalPayable > 0 ? totalPayable : 0.0,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory MonthlyBillModel.fromMap(Map<String, dynamic> map, String id) {
    return MonthlyBillModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerUserId: map['customerUserId'],
      yearMonth: map['yearMonth'] ?? '',
      month: (map['month'] ?? 1).toInt(),
      year: (map['year'] ?? 2026).toInt(),
      totalMilkLitres: (map['totalMilkLitres'] ?? 0.0).toDouble(),
      appliedRate: (map['appliedRate'] ?? 0.0).toDouble(),
      currentMonthMilkCharges: (map['currentMonthMilkCharges'] ?? 0.0).toDouble(),
      previousBalance: (map['previousBalance'] ?? 0.0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0.0).toDouble(),
      finalPayable: (map['finalPayable'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'UNPAID',
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
      'yearMonth': yearMonth,
      'month': month,
      'year': year,
      'totalMilkLitres': totalMilkLitres,
      'appliedRate': appliedRate,
      'currentMonthMilkCharges': currentMonthMilkCharges,
      'previousBalance': previousBalance,
      'paidAmount': paidAmount,
      'finalPayable': finalPayable,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

