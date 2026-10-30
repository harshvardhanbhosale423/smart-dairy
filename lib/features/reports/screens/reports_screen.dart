import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/metric_card.dart';
import '../providers/report_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<ReportProvider>().setThisMonth(user.uid);
      }
    });
  }

  void _shareReport() {
    final report = context.read<ReportProvider>().reportData;
    if (report == null) return;

    final user = context.read<AuthProvider>().currentUser;
    final text = '''
📊 *Smart Dairy - Business Profit & Loss Report*
Period: ${DateFormatter.formatShortDate(report.startDate)} to ${DateFormatter.formatShortDate(report.endDate)}
Owner: ${user?.name ?? 'Dairy Farm'}
----------------------------------------
🥛 Total Milk Distributed: ${report.totalMilkDeliveredLitres.toStringAsFixed(1)} Litres
📈 Billed Milk Sales: ${CurrencyFormatter.format(report.billedSalesAmount)}
💵 Actual Cash/UPI Collected: ${CurrencyFormatter.format(report.actualCashCollected)}
⚠️ Outstanding Pending Dues: ${CurrencyFormatter.format(report.outstandingDues)}
💸 Total Dairy Expenses: ${CurrencyFormatter.format(report.totalExpenses)}
----------------------------------------
💰 *NET CASH PROFIT:* *${CurrencyFormatter.format(report.netCashProfit)}*
(Actual Collections - Total Expenses)
----------------------------------------
Generated via Smart Dairy App
''';
    Share.share(text, subject: 'Smart Dairy Business Report');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reportProvider = context.watch<ReportProvider>();
    final report = reportProvider.reportData;
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('reports')),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Report',
            onPressed: report != null ? _shareReport : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Filter Quick Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: user != null ? () => reportProvider.setThisMonth(user.uid) : null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.darkGreen),
                    ),
                    child: const Text('This Month'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: user != null ? () => reportProvider.setLastMonth(user.uid) : null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.darkGreen),
                    ),
                    child: const Text('Last Month'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Date Range Text
            if (report != null)
              Center(
                child: Text(
                  '${DateFormatter.formatDate(report.startDate)} — ${DateFormatter.formatDate(report.endDate)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                ),
              ),

            const SizedBox(height: 16),

            if (reportProvider.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (report != null) ...[
              // Highlight: Net Cash Profit Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: report.netCashProfit >= 0
                        ? [AppColors.darkGreen, AppColors.primaryGreen]
                        : [AppColors.error.withOpacity(0.85), AppColors.error],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkGreen.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Net Cash Profit (प्रत्यक्ष निव्वळ नफा)',
                      style: TextStyle(color: AppColors.pureWhite.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.format(report.netCashProfit),
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.pureWhite, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cash Collected (${CurrencyFormatter.format(report.actualCashCollected)}) - Expenses (${CurrencyFormatter.format(report.totalExpenses)})',
                      style: TextStyle(color: AppColors.pureWhite.withOpacity(0.85), fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 6 Metrics Grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  MetricCard(
                    title: 'Total Milk Distributed',
                    value: '${report.totalMilkDeliveredLitres.toStringAsFixed(1)} L',
                    subtitle: 'All Deliveries',
                    icon: Icons.water_drop_rounded,
                    iconColor: AppColors.darkGreen,
                  ),
                  MetricCard(
                    title: 'Billed Milk Sales',
                    value: CurrencyFormatter.format(report.billedSalesAmount),
                    subtitle: 'Total Value',
                    icon: Icons.receipt_long_rounded,
                    iconColor: AppColors.darkGreen,
                  ),
                  MetricCard(
                    title: 'Actual Cash Collected',
                    value: CurrencyFormatter.format(report.actualCashCollected),
                    subtitle: 'Cash / UPI in Bank',
                    icon: Icons.account_balance_rounded,
                    iconColor: AppColors.success,
                  ),
                  MetricCard(
                    title: 'Pending Customer Dues',
                    value: CurrencyFormatter.format(report.outstandingDues),
                    subtitle: 'To be Collected',
                    icon: Icons.error_outline_rounded,
                    iconColor: AppColors.error,
                  ),
                  MetricCard(
                    title: 'Total Dairy Expenses',
                    value: CurrencyFormatter.format(report.totalExpenses),
                    subtitle: 'Feed, Vet, Fodder',
                    icon: Icons.shopping_basket_rounded,
                    iconColor: AppColors.cowBlack,
                  ),
                  MetricCard(
                    title: 'Billed Profit',
                    value: CurrencyFormatter.format(report.netBilledProfit),
                    subtitle: 'Billed - Expenses',
                    icon: Icons.analytics_rounded,
                    iconColor: AppColors.info,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Category Breakdown of Expenses
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dividerColor.withOpacity(0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expense Breakdown by Category / खर्च विभागणी',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (report.categoryWiseExpenses.isEmpty)
                      const Text('No expenses recorded for this period', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
                    else
                      ...report.categoryWiseExpenses.entries.map((e) {
                        final percentage = report.totalExpenses > 0 ? (e.value / report.totalExpenses) * 100 : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(context.tr(e.key), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text(
                                    '${CurrencyFormatter.format(e.value)} (${percentage.toStringAsFixed(0)}%)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: AppColors.dividerColor.withOpacity(0.3),
                                color: AppColors.darkGreen,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }
}

