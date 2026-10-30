class DailySalesPoint {
  final DateTime date;
  final double milkLitres;
  final double salesAmount;

  DailySalesPoint({
    required this.date,
    required this.milkLitres,
    required this.salesAmount,
  });
}

class BusinessReportData {
  final DateTime startDate;
  final DateTime endDate;
  final double totalMilkDeliveredLitres;
  final double billedSalesAmount;
  final double actualCashCollected;
  final double outstandingDues;
  final double totalExpenses;
  final double netCashProfit; // actualCashCollected - totalExpenses
  final double netBilledProfit; // billedSalesAmount - totalExpenses
  final Map<String, double> categoryWiseExpenses;
  final List<DailySalesPoint> dailySalesTrend;

  BusinessReportData({
    required this.startDate,
    required this.endDate,
    required this.totalMilkDeliveredLitres,
    required this.billedSalesAmount,
    required this.actualCashCollected,
    required this.outstandingDues,
    required this.totalExpenses,
    required this.netCashProfit,
    required this.netBilledProfit,
    required this.categoryWiseExpenses,
    required this.dailySalesTrend,
  });
}

