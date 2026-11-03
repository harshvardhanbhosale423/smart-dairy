import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../models/monthly_bill_model.dart';
import '../providers/billing_provider.dart';
import '../repositories/billing_repository.dart';
import '../../auth/providers/auth_provider.dart';
import 'bill_detail_screen.dart';
import 'create_custom_bill_screen.dart';

class MonthlyBillsScreen extends StatefulWidget {
  const MonthlyBillsScreen({super.key});

  @override
  State<MonthlyBillsScreen> createState() => _MonthlyBillsScreenState();
}

class _MonthlyBillsScreenState extends State<MonthlyBillsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<BillingProvider>().listenToOwnerBills(user.uid);
      }
    });
  }

  void _changeMonth(int offset) {
    final billing = context.read<BillingProvider>();
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    var month = billing.selectedMonth + offset;
    var year = billing.selectedYear;
    if (month > 12) {
      month = 1;
      year++;
    } else if (month < 1) {
      month = 12;
      year--;
    }
    billing.setMonth(year, month, user.uid);
  }

  void _openCreateBill([dynamic preCustomer]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCustomBillScreen(preSelectedCustomer: preCustomer),
      ),
    );
  }

  void _deleteBill(MonthlyBillModel bill) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'बिल हटवायचे आहे का?',
      message: '${bill.customerName} यांचे "${bill.yearMonth}" चे हे बिल हटवायचे आहे का?',
      confirmText: 'होय, हटवा',
    );

    if (confirm == true) {
      await BillingRepository().deleteBill(bill.id);
      final user = context.read<AuthProvider>().currentUser;
      if (user != null && mounted) {
        context.read<BillingProvider>().listenToOwnerBills(user.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('बिल यशस्वीरित्या हटवले!'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeProvider = context.watch<LocaleProvider>();
    final billing = context.watch<BillingProvider>();
    final bills = billing.bills;

    final date = DateTime(billing.selectedYear, billing.selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('monthly_bills')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart_rounded, size: 24),
            tooltip: 'महिने निवडून बिल बनवा',
            onPressed: () => _openCreateBill(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.receipt_long_rounded),
        label: const Text(
          'महिने निवडून बिल बनवा',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _openCreateBill(),
      ),
      body: Column(
        children: [
          // Month Selector Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppColors.darkCard : AppColors.softLightGreen.withOpacity(0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  DateFormatter.formatMonthYear(date, isMarathi: localeProvider.isMarathi),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),

          // Financial Summary Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppColors.darkSurface : AppColors.surfaceLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Billed Dues', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(
                      CurrencyFormatter.format(billing.totalBilledAmount),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.error),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Paid: ${billing.paidBillsCount} | Unpaid: ${billing.unpaidBillsCount}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Collected: ${CurrencyFormatter.format(billing.totalCollectedInBills)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bills List
          Expanded(
            child: billing.isLoading
                ? const Center(child: CircularProgressIndicator())
                : bills.isEmpty
                    ? EmptyStateWidget(
                        title: 'या महिन्यासाठी बिल उपलब्ध नाही',
                        message: 'ग्राहकांचे महिने निवडून अचूक व पारदर्शक बिल तयार करण्यासाठी खालील बटनावर टॅप करा.',
                        buttonText: 'महिने निवडून बिल बनवा',
                        onButtonPressed: () => _openCreateBill(),
                        icon: Icons.receipt_long_rounded,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: bills.length,
                        itemBuilder: (ctx, index) {
                          final bill = bills[index];
                          return _buildBillCard(bill, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(MonthlyBillModel bill, bool isDark) {
    Color statusBg;
    Color statusFg;
    if (bill.isPaid) {
      statusBg = AppColors.softLightGreen;
      statusFg = AppColors.success;
    } else if (bill.isPartial) {
      statusBg = AppColors.goldLight;
      statusFg = AppColors.warning;
    } else {
      statusBg = AppColors.error.withOpacity(0.12);
      statusFg = AppColors.error;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BillDetailScreen(bill: bill)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      bill.customerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      bill.status,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusFg),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.textMuted),
                    tooltip: 'बिल हटवा',
                    onPressed: () => _deleteBill(bill),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 8),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'दूध: ${bill.totalMilkLitres.toStringAsFixed(1)}L @ ₹${bill.appliedRate.toStringAsFixed(0)} = ${CurrencyFormatter.format(bill.currentMonthMilkCharges)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'कालावधी: ${bill.yearMonth}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    CurrencyFormatter.format(bill.finalPayable),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: bill.isPaid ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
