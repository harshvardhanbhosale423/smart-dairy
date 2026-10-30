import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../payments/models/payment_model.dart';
import '../../payments/repositories/payment_repository.dart';
import '../../payments/screens/payment_receipt_screen.dart';

class CustomerPaymentsScreen extends StatelessWidget {
  const CustomerPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final customerId = user?.customerId;

    if (customerId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('payments'))),
        body: const Center(child: Text('Customer profile not linked')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('payments')),
      ),
      body: StreamBuilder<List<PaymentModel>>(
        stream: PaymentRepository().getCustomerPaymentsStream(customerId),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final payments = snapshot.data ?? [];
          if (payments.isEmpty) {
            return EmptyStateWidget(
              title: 'No Payments Yet',
              message: 'आपण केलेले सर्व पेमेंट व पावत्या येथे दिसतील.\nYour payment history and receipts will be displayed here.',
              icon: Icons.payments_rounded,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (ctx, index) {
              final p = payments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
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
                    CurrencyFormatter.format(p.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    '${DateFormatter.formatDate(p.paymentDate)} • ${p.paymentMethod}\nStatus: ${p.status}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: p.isPaid
                      ? OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              ctx,
                              MaterialPageRoute(builder: (_) => PaymentReceiptScreen(payment: p)),
                            );
                          },
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                          child: const Text('Receipt', style: TextStyle(fontSize: 11)),
                        )
                      : const Text('Pending Approval', style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

