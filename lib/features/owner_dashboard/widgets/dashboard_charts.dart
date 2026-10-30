import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class DashboardFinancialChart extends StatelessWidget {
  final double billedSales;
  final double cashCollected;
  final double expenses;

  const DashboardFinancialChart({
    super.key,
    required this.billedSales,
    required this.cashCollected,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxVal = [billedSales, cashCollected, expenses, 100.0].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.dividerColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Financial Comparison',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  _legendDot(AppColors.darkGreen, 'Sales'),
                  const SizedBox(width: 8),
                  _legendDot(AppColors.lightGreen, 'Cash'),
                  const SizedBox(width: 8),
                  _legendDot(AppColors.error, 'Expense'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String label;
                      if (group.x == 0) label = 'Billed Sales';
                      else if (group.x == 1) label = 'Cash Received';
                      else label = 'Dairy Expenses';
                      return BarTooltipItem(
                        '$label\n${CurrencyFormatter.format(rod.toY)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        String text = '';
                        switch (val.toInt()) {
                          case 0:
                            text = 'Sales';
                            break;
                          case 1:
                            text = 'Cash In';
                            break;
                          case 2:
                            text = 'Expense';
                            break;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: billedSales,
                        color: AppColors.darkGreen,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: cashCollected,
                        color: AppColors.lightGreen,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: expenses,
                        color: AppColors.error,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}

