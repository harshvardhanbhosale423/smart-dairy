import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'add_edit_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<ExpenseProvider>().listenToExpenses(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseProvider = context.watch<ExpenseProvider>();
    final expenses = expenseProvider.expenses;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('manage_expenses')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()),
          );
        },
        backgroundColor: AppColors.darkGreen,
        foregroundColor: AppColors.pureWhite,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.tr('add_expense')),
      ),
      body: Column(
        children: [
          // Total Expenses Header Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: isDark ? AppColors.darkCard : AppColors.softLightGreen.withOpacity(0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('total_expenses'),
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(expenseProvider.totalExpenses),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.error),
                    ),
                  ],
                ),
                Text(
                  '${expenses.length} Entries',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),

          // Expenses List
          Expanded(
            child: expenseProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : expenses.isEmpty
                    ? EmptyStateWidget(
                        title: 'No Expenses Recorded',
                        message: 'गोठ्याचा कोणताही खर्च अद्याप नोंदवलेला नाही.\nपशुआहार, चारा, डॉक्टर खर्च नोंदवण्यासाठी खालील बटनावर टॅप करा.',
                        buttonText: context.tr('add_expense'),
                        onButtonPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()));
                        },
                        icon: Icons.account_balance_wallet_rounded,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80, top: 12),
                        itemCount: expenses.length,
                        itemBuilder: (ctx, index) {
                          final exp = expenses[index];
                          return _buildExpenseCard(exp, isDark, expenseProvider);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseModel exp, bool isDark, ExpenseProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.error.withOpacity(0.12),
          child: Icon(_getCategoryIcon(exp.category), color: AppColors.error, size: 20),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.tr(exp.category),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              CurrencyFormatter.format(exp.amount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.error),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exp.description.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(exp.description, style: const TextStyle(fontSize: 12)),
            ],
            const SizedBox(height: 2),
            Text(
              '${DateFormatter.formatDate(exp.expenseDate)} • Paid via ${exp.paymentMethod}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 18),
          onPressed: () async {
            final confirm = await ConfirmationDialog.show(
              context,
              title: 'Delete Expense?',
              message: 'Are you sure you want to delete this expense of ${CurrencyFormatter.format(exp.amount)}?',
              isDestructive: true,
            );
            if (confirm == true) {
              await provider.deleteExpense(exp);
            }
          },
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'cow_feed':
        return Icons.shopping_bag_rounded;
      case 'green_fodder':
      case 'dry_fodder':
        return Icons.grass_rounded;
      case 'veterinary':
      case 'medicines':
        return Icons.medical_services_rounded;
      case 'transportation':
        return Icons.local_shipping_rounded;
      case 'electricity':
        return Icons.bolt_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }
}

