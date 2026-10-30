import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'record_payment_screen.dart';
import 'payment_receipt_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<PaymentProvider>().listenToOwnerPayments(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paymentProvider = context.watch<PaymentProvider>();
    final allPayments = paymentProvider.payments;
    final verifiedPayments = allPayments.where((p) => p.isPaid).toList();
    final pendingPayments = allPayments.where((p) => p.isPending).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments & Collections'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldenYellow,
          labelColor: AppColors.pureWhite,
          unselectedLabelColor: AppColors.pureWhite.withOpacity(0.7),
          tabs: [
            Tab(text: 'Verified Payments (${verifiedPayments.length})'),
            Tab(text: 'Pending Approvals (${pendingPayments.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: context.tr('record_payment'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecordPaymentScreen()),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Verified Payments
          paymentProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : verifiedPayments.isEmpty
                  ? EmptyStateWidget(
                      title: 'No Payments Recorded Yet',
                      message: 'कोणतीही जमा पावती अद्याप नोंदवलेली नाही.',
                      buttonText: context.tr('record_payment'),
                      onButtonPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordPaymentScreen()));
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: verifiedPayments.length,
                      itemBuilder: (ctx, index) {
                        final p = verifiedPayments[index];
                        return _buildPaymentCard(p, isDark);
                      },
                    ),

          // Tab 2: Pending Approvals
          pendingPayments.isEmpty
              ? const EmptyStateWidget(
                  title: 'No Pending Payments',
                  message: 'ग्राहकांकडून कोणतेही प्रलंबित पेमेंट नाही.\nAll online payments are verified!',
                  icon: Icons.verified_rounded,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendingPayments.length,
                  itemBuilder: (ctx, index) {
                    final p = pendingPayments[index];
                    return _buildPendingCard(p, isDark, paymentProvider);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(PaymentModel p, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.softLightGreen,
          child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
        ),
        title: Text(
          p.customerName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          '${p.paymentMethod} • Ref: ${p.transactionRef}\n${DateFormatter.formatDate(p.paymentDate)}',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(p.amount),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success),
            ),
            const SizedBox(height: 2),
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentReceiptScreen(payment: p)));
              },
              child: const Text('Receipt >', style: TextStyle(fontSize: 11, color: AppColors.darkGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(PaymentModel p, bool isDark, PaymentProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.warning.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  p.customerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  CurrencyFormatter.format(p.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.warning),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'UPI Ref ID: ${p.transactionRef}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              'Date: ${DateFormatter.formatDate(p.paymentDate)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            if (p.notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Note: ${p.notes}', style: const TextStyle(fontSize: 12)),
            ],
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await ConfirmationDialog.show(
                      context,
                      title: 'Verify Payment?',
                      message: 'Have you verified receipt of ${CurrencyFormatter.format(p.amount)} in your bank account?\nखात्यात रक्कम जमा झाल्याची खात्री केली आहे का?',
                      confirmText: 'Verify & Credit Ledger',
                    );
                    if (confirm == true) {
                      await provider.approvePayment(p);
                    }
                  },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Verify & Credit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGreen,
                    foregroundColor: AppColors.pureWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

