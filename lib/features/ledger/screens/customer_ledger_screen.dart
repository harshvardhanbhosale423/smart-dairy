import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../models/ledger_entry_model.dart';
import '../providers/ledger_provider.dart';
import '../../customers/models/customer_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../payments/screens/record_payment_screen.dart';

class CustomerLedgerScreen extends StatefulWidget {
  final CustomerModel customer;

  const CustomerLedgerScreen({super.key, required this.customer});

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedgerProvider>().listenToCustomerLedger(widget.customer.id);
    });
  }

  void _showAdjustmentDialog() {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    bool isCredit = true; // Credit reduces balance (discount/bonus), Debit increases charge

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Account Adjustment / दुरुस्ती नोंद'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('सूट / जमा (Credit -)'),
                        selected: isCredit,
                        onSelected: (val) => setDialogState(() => isCredit = true),
                        selectedColor: AppColors.softLightGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('आकारणी (Debit +)'),
                        selected: !isCredit,
                        onSelected: (val) => setDialogState(() => isCredit = false),
                        selectedColor: AppColors.goldLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: amountController,
                  label: 'Adjustment Amount / रक्कम (₹)',
                  hint: '100',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.currency_rupee_rounded,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: reasonController,
                  label: 'Reason / कारण',
                  hint: 'उदा. सणाचे बिल डिस्काउंट / विशेष सूट',
                  prefixIcon: Icons.edit_note_rounded,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (amt <= 0) return;
                final user = context.read<AuthProvider>().currentUser;
                if (user == null) return;

                final effectiveAmount = isCredit ? amt : -amt;
                final success = await context.read<LedgerProvider>().addAdjustment(
                  ownerId: user.uid,
                  customerId: widget.customer.id,
                  customerName: widget.customer.name,
                  amount: effectiveAmount,
                  reason: reasonController.text.trim(),
                );
                if (success && mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Adjustment recorded successfully'), backgroundColor: AppColors.success),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen),
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ledgerProvider = context.watch<LedgerProvider>();
    final transactions = ledgerProvider.transactions;
    final hasDue = widget.customer.currentBalance > 0;
    final isAdvance = widget.customer.currentBalance < 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.customer.name} - ${context.tr('ledger')}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Add Adjustment',
            onPressed: _showAdjustmentDialog,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
          boxShadow: [
            BoxShadow(
              color: AppColors.darkGreen.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: context.tr('record_payment'),
                icon: Icons.payments_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecordPaymentScreen(preSelectedCustomer: widget.customer),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Outstanding Balance Card Header
          Container(
            padding: const EdgeInsets.all(16),
            color: hasDue
                ? AppColors.error.withOpacity(0.08)
                : (isAdvance ? AppColors.success.withOpacity(0.08) : AppColors.softLightGreen.withOpacity(0.3)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.customer.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      widget.customer.phone,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isAdvance ? 'Advance / जमा आगाऊ' : 'Current Due / येणे बाकी',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    Text(
                      CurrencyFormatter.format(widget.customer.currentBalance.abs()),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: hasDue ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total Debits vs Credits summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkCard : AppColors.surfaceLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Billed/Milk: ${CurrencyFormatter.format(ledgerProvider.totalDebited)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error),
                ),
                Text(
                  'Total Paid: ${CurrencyFormatter.format(ledgerProvider.totalCredited)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                ),
              ],
            ),
          ),

          // Ledger Entries List
          Expanded(
            child: ledgerProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : transactions.isEmpty
                    ? EmptyStateWidget(
                        title: 'No Ledger Entries Yet',
                        message: 'या ग्राहकाचे अद्याप कोणतेही व्यवहार झालेले नाहीत.\nदूध नोंद झाल्यावर किंवा पेमेंट जमा झाल्यावर आपोआप खतावणी तयार होते.',
                        icon: Icons.menu_book_rounded,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: transactions.length,
                        itemBuilder: (ctx, index) {
                          final item = transactions[index];
                          return _buildLedgerCard(item, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerCard(LedgerEntryModel item, bool isDark) {
    final isCredit = item.isCredit;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCredit ? AppColors.success.withOpacity(0.3) : AppColors.dividerColor.withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCredit ? AppColors.softLightGreen : AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: isCredit ? AppColors.success : AppColors.error,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCredit ? 'जमा (Payment Received)' : 'नावे (Milk Delivered)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isCredit ? AppColors.success : AppColors.error,
                        ),
                      ),
                      Text(
                        DateFormatter.formatDate(item.transactionDate),
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.notes.isNotEmpty ? item.notes : (isCredit ? 'Payment via ${item.paymentMethod}' : 'Daily Milk'),
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Balance After: ${CurrencyFormatter.format(item.balanceAfter)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isCredit ? "-" : "+"}${CurrencyFormatter.format(item.amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isCredit ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

