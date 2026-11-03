import '../../milk_entry/models/milk_entry_model.dart';
import '../../../core/utils/date_formatter.dart';

class MonthBillSummary {
  final int year;
  final int month;
  final String yearMonth;
  final String monthNameMr;
  final String monthNameEn;
  final double totalLitres;
  final double appliedRate;
  final double milkCharges;
  final double paymentsReceived;
  final double netBalance;
  final List<MilkEntryModel> entries;
  final bool isAlreadyBilled;
  final String? existingBillId;

  MonthBillSummary({
    required this.year,
    required this.month,
    required this.yearMonth,
    required this.monthNameMr,
    required this.monthNameEn,
    required this.totalLitres,
    required this.appliedRate,
    required this.milkCharges,
    required this.paymentsReceived,
    required this.netBalance,
    required this.entries,
    this.isAlreadyBilled = false,
    this.existingBillId,
  });

  factory MonthBillSummary.fromEntries({
    required int year,
    required int month,
    required double appliedRate,
    required List<MilkEntryModel> monthEntries,
    double paymentsReceived = 0.0,
    bool isAlreadyBilled = false,
    String? existingBillId,
  }) {
    final ym = '$year-${month.toString().padLeft(2, '0')}';
    double totalLitres = 0.0;
    double totalCharges = 0.0;

    for (final e in monthEntries) {
      totalLitres += e.totalQty;
      totalCharges += e.totalAmount;
    }

    final net = totalCharges - paymentsReceived;
    final mrName = (month >= 1 && month <= 12)
        ? '${DateFormatter.marathiMonths[month - 1]} $year'
        : ym;
    final enName = DateFormatter.formatMonthYear(DateTime(year, month));

    return MonthBillSummary(
      year: year,
      month: month,
      yearMonth: ym,
      monthNameMr: mrName,
      monthNameEn: enName,
      totalLitres: totalLitres,
      appliedRate: appliedRate,
      milkCharges: totalCharges,
      paymentsReceived: paymentsReceived,
      netBalance: net > 0 ? net : 0.0,
      entries: monthEntries,
      isAlreadyBilled: isAlreadyBilled,
      existingBillId: existingBillId,
    );
  }
}
