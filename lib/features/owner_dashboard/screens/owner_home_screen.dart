import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/metric_card.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_charts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/screens/add_edit_customer_screen.dart';
import '../../customers/screens/customer_list_screen.dart';
import '../../milk_entry/screens/daily_milk_entry_screen.dart';
import '../../billing/screens/monthly_bills_screen.dart';
import '../../payments/screens/record_payment_screen.dart';
import '../../payments/screens/payment_history_screen.dart';
import '../../expenses/screens/expense_list_screen.dart';
import '../../reports/screens/reports_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const OwnerHomeScreen({super.key, this.onNavigateTab});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<DashboardProvider>().loadDashboardMetrics(user.uid);
      }
    });
  }

  Future<void> _refresh() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      await context.read<DashboardProvider>().loadDashboardMetrics(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeProvider = context.watch<LocaleProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.darkGreen,
        child: CustomScrollView(
          slivers: [
            // Custom App Bar Header with Dairy Branding
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: AppColors.darkGreen,
              actions: [
                TextButton.icon(
                  onPressed: () => localeProvider.toggleLocale(),
                  icon: const Icon(Icons.language, size: 16, color: AppColors.pureWhite),
                  label: Text(
                    localeProvider.isMarathi ? 'English' : 'मराठी',
                    style: const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.pureWhite),
                  onPressed: _refresh,
                  tooltip: 'Refresh',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                title: Text(
                  user?.name ?? 'Smart Dairy Farm',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.pureWhite),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.darkGreen, AppColors.primaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 16, top: 40, right: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.agriculture_rounded, color: AppColors.pureWhite, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('app_tagline'),
                            style: TextStyle(color: AppColors.pureWhite.withOpacity(0.85), fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormatter.formatDate(DateTime.now(), isMarathi: localeProvider.isMarathi),
                            style: const TextStyle(color: AppColors.goldenYellow, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // QUICK ACTION BUTTONS
                    Text(
                      context.tr('quick_actions'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _quickActionBtn(
                            icon: Icons.edit_note_rounded,
                            label: context.tr('new_milk_entry'),
                            color: AppColors.darkGreen,
                            onTap: () {
                              if (widget.onNavigateTab != null) {
                                widget.onNavigateTab!(2); // Milk Entry Tab
                              } else {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyMilkEntryScreen()));
                              }
                            },
                          ),
                          _quickActionBtn(
                            icon: Icons.person_add_alt_1_rounded,
                            label: context.tr('add_customer'),
                            color: AppColors.lightGreen,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditCustomerScreen()));
                            },
                          ),
                          _quickActionBtn(
                            icon: Icons.receipt_long_rounded,
                            label: context.tr('generate_bills'),
                            color: AppColors.goldenYellow,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyBillsScreen()));
                            },
                          ),
                          _quickActionBtn(
                            icon: Icons.payments_rounded,
                            label: context.tr('record_payment'),
                            color: AppColors.info,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordPaymentScreen()));
                            },
                          ),
                          _quickActionBtn(
                            icon: Icons.account_balance_wallet_rounded,
                            label: context.tr('manage_expenses'),
                            color: AppColors.cowBlack,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseListScreen()));
                            },
                          ),
                          _quickActionBtn(
                            icon: Icons.analytics_rounded,
                            label: context.tr('business_reports'),
                            color: AppColors.darkGreen,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 8 OPERATIONAL AND FINANCIAL CARDS
                    Text(
                      context.tr('dashboard'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Grid of 8 Cards
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.25,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Card 1: Total Customers
                        MetricCard(
                          title: context.tr('customers'),
                          value: '${dashboard.activeCustomers} Active',
                          subtitle: '${dashboard.totalCustomers} Total',
                          icon: Icons.people_alt_rounded,
                          iconColor: AppColors.darkGreen,
                          onTap: () {
                            if (widget.onNavigateTab != null) {
                              widget.onNavigateTab!(1); // Customers tab
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerListScreen()));
                            }
                          },
                        ),

                        // Card 2: Today's Milk Distribution
                        MetricCard(
                          title: context.tr('today_distribution'),
                          value: '${dashboard.todayTotalMilk.toStringAsFixed(1)} L',
                          subtitle: 'M: ${dashboard.todayMorningMilk.toStringAsFixed(1)}L | E: ${dashboard.todayEveningMilk.toStringAsFixed(1)}L',
                          icon: Icons.water_drop_rounded,
                          iconColor: AppColors.lightGreen,
                          onTap: () {
                            if (widget.onNavigateTab != null) {
                              widget.onNavigateTab!(2);
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyMilkEntryScreen()));
                            }
                          },
                        ),

                        // Card 3: This Month's Milk Sales
                        MetricCard(
                          title: context.tr('this_month_sales'),
                          value: CurrencyFormatter.format(dashboard.thisMonthSalesAmount),
                          subtitle: '${dashboard.thisMonthSalesLitres.toStringAsFixed(1)} Litres',
                          icon: Icons.trending_up_rounded,
                          iconColor: AppColors.darkGreen,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyBillsScreen())),
                        ),

                        // Card 4: Total Monthly Collection
                        MetricCard(
                          title: context.tr('total_collection'),
                          value: CurrencyFormatter.format(dashboard.thisMonthCollection),
                          subtitle: 'Cash / UPI Received',
                          icon: Icons.account_balance_rounded,
                          iconColor: AppColors.success,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen())),
                        ),

                        // Card 5: Pending Customer Payments
                        MetricCard(
                          title: context.tr('pending_dues'),
                          value: CurrencyFormatter.format(dashboard.totalPendingDues),
                          subtitle: 'Outstanding Due',
                          icon: Icons.error_outline_rounded,
                          iconColor: AppColors.error,
                          onTap: () {
                            if (widget.onNavigateTab != null) widget.onNavigateTab!(1);
                          },
                        ),

                        // Card 6: Total Dairy Expenses
                        MetricCard(
                          title: context.tr('total_expenses'),
                          value: CurrencyFormatter.format(dashboard.thisMonthExpenses),
                          subtitle: 'Feed, Vet, Fodder',
                          icon: Icons.shopping_basket_rounded,
                          iconColor: AppColors.cowBlack,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseListScreen())),
                        ),

                        // Card 7: Monthly Income
                        MetricCard(
                          title: 'Monthly Cash Inflow',
                          value: CurrencyFormatter.format(dashboard.thisMonthCollection),
                          subtitle: 'Actual Realized',
                          icon: Icons.savings_rounded,
                          iconColor: AppColors.info,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
                        ),

                        // Card 8: Monthly Net Profit
                        MetricCard(
                          title: context.tr('net_profit'),
                          value: CurrencyFormatter.format(dashboard.monthlyNetProfit),
                          subtitle: dashboard.monthlyNetProfit >= 0 ? 'Profit (Cash)' : 'Deficit',
                          icon: Icons.monetization_on_rounded,
                          iconColor: dashboard.monthlyNetProfit >= 0 ? AppColors.darkGreen : AppColors.error,
                          cardColor: dashboard.monthlyNetProfit >= 0 ? AppColors.softLightGreen.withOpacity(0.5) : AppColors.error.withOpacity(0.08),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Financial Chart
                    DashboardFinancialChart(
                      billedSales: dashboard.thisMonthSalesAmount,
                      cashCollected: dashboard.thisMonthCollection,
                      expenses: dashboard.thisMonthExpenses,
                    ),

                    const SizedBox(height: 24),

                    // Recent Payments Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('recent_activity'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen())),
                          child: Text(context.tr('view_all')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (dashboard.recentPayments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.dividerColor.withOpacity(0.5)),
                        ),
                        child: Center(
                          child: Text(
                            context.tr('no_data'),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ...dashboard.recentPayments.map((p) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: p.isPaid ? AppColors.softLightGreen : AppColors.goldLight,
                            child: Icon(
                              p.isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                              color: p.isPaid ? AppColors.success : AppColors.warning,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            p.customerName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${p.paymentMethod} • ${DateFormatter.formatShortDate(p.paymentDate)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            CurrencyFormatter.format(p.amount),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.success),
                          ),
                        ),
                      )),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 90,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

