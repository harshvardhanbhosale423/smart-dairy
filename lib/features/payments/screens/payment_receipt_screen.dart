import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/payment_model.dart';

class PaymentReceiptScreen extends StatelessWidget {
  final PaymentModel payment;

  const PaymentReceiptScreen({super.key, required this.payment});

  void _shareReceipt() {
    final text = '''
🧾 *Smart Dairy - Payment Receipt / जमा पावती*
----------------------------------------
Customer: *${payment.customerName}*
Amount: *${CurrencyFormatter.format(payment.amount)}*
Status: *PAID (खात्रीशीर जमा)*
Date: ${DateFormatter.formatDate(payment.paymentDate)}
Method: ${payment.paymentMethod}
Ref No: ${payment.transactionRef}
----------------------------------------
Thank you for your payment! 🙏
''';
    Share.share(text, subject: 'Payment Receipt - ${payment.customerName}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Receipt / पावती'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareReceipt,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: CustomButton(
          text: 'Share Receipt / पावती पाठवा',
          icon: Icons.share_rounded,
          onPressed: _shareReceipt,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.pureWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.dividerColor.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkGreen.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Success Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.softLightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Payment Successful!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'रक्कम खात्रीशीर जमा झाली आहे',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 18),

                Text(
                  CurrencyFormatter.format(payment.amount),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                const Divider(),
                const SizedBox(height: 12),

                _receiptRow('Customer Name:', payment.customerName),
                _receiptRow('Phone:', payment.customerPhone),
                _receiptRow('Date & Time:', '${DateFormatter.formatDate(payment.paymentDate)} ${DateFormatter.formatTime(payment.paymentDate)}'),
                _receiptRow('Payment Method:', payment.paymentMethod),
                _receiptRow('Transaction Ref:', payment.transactionRef),
                _receiptRow('Verification:', payment.verifiedBy),
                if (payment.notes.isNotEmpty) _receiptRow('Note:', payment.notes),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.verified_user_rounded, size: 16, color: AppColors.darkGreen),
                    SizedBox(width: 6),
                    Text(
                      'Verified Digital Dairy Khata Receipt',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

