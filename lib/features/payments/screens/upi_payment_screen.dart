import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/upi_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/payment_provider.dart';
import '../../billing/models/monthly_bill_model.dart';
import '../../customers/models/customer_model.dart';

class UpiPaymentScreen extends StatefulWidget {
  final CustomerModel customer;
  final MonthlyBillModel? bill;
  final double payableAmount;
  final String ownerUpiId;
  final String dairyName;

  const UpiPaymentScreen({
    super.key,
    required this.customer,
    this.bill,
    required this.payableAmount,
    required this.ownerUpiId,
    required this.dairyName,
  });

  @override
  State<UpiPaymentScreen> createState() => _UpiPaymentScreenState();
}

class _UpiPaymentScreenState extends State<UpiPaymentScreen> {
  final _txnIdController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _txnIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _upiUri {
    return UpiService.buildUpiUri(
      upiId: widget.ownerUpiId,
      payeeName: widget.dairyName,
      amount: widget.payableAmount,
      transactionNote: 'Milk-Bill-${widget.customer.name}',
    );
  }

  void _launchApp(String appScheme) async {
    final success = await UpiService.launchSpecificApp(
      upiId: widget.ownerUpiId,
      payeeName: widget.dairyName,
      amount: widget.payableAmount,
      transactionNote: 'Milk-Bill-${widget.customer.name}',
      appScheme: appScheme,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('UPI App not installed or could not be launched. Please scan the QR code above.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _onSubmitVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final paymentProvider = context.read<PaymentProvider>();
    final paymentId = await paymentProvider.submitCustomerPayment(
      ownerId: widget.customer.ownerId,
      customerId: widget.customer.id,
      customerName: widget.customer.name,
      customerPhone: widget.customer.phone,
      customerUserId: widget.customer.userId,
      billId: widget.bill?.id,
      amount: widget.payableAmount,
      transactionRef: _txnIdController.text.trim(),
      notes: _notesController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (paymentId != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Payment Submitted for Verification'),
          content: const Text(
            'आपला UPI Transaction Ref ID डेअरी मालकाकडे पडताळणीसाठी पाठवला आहे. मालकाने खात्री केल्यानंतर आपले खाते जमा केले जाईल.\n\nThank you for choosing Smart Dairy!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen),
              child: const Text('OK / ठीक आहे'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('pay_now')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.softLightGreen.withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Text(
                    'Total Payable Amount / भरावयाची रक्कम',
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.textLight : AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(widget.payableAmount),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'To: ${widget.dairyName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'UPI ID: ${widget.ownerUpiId}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Dynamic UPI QR Code
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: _upiUri,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scan with Any UPI App to Pay',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // UPI Apps Chooser
            const Text(
              'Or Pay Directly with App / थेट ॲप निवडा:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _appButton('Google Pay', Icons.payment, Colors.blue, () => _launchApp('tez')),
                _appButton('PhonePe', Icons.account_balance_wallet, Colors.purple, () => _launchApp('phonepe')),
                _appButton('Paytm', Icons.qr_code, Colors.lightBlue, () => _launchApp('paytmmp')),
                _appButton('BHIM', Icons.security, Colors.green, () => _launchApp('bhim')),
              ],
            ),

            const SizedBox(height: 32),

            // Verification Reference Form
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.pureWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.dividerColor.withOpacity(0.6)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Payment Confirmation / पेमेंट माहिती नोंदवा',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'पेमेंट केल्यावर UPI ॲपमधील १२ अंकी UTR किंवा Transaction Ref ID खाली टाका:',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _txnIdController,
                      label: 'UPI UTR / Transaction ID *',
                      hint: 'उदा. 429812345678',
                      prefixIcon: Icons.receipt_long_rounded,
                      validator: (v) => Validators.validateRequired(v, 'Transaction ID'),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _notesController,
                      label: 'Optional Note / टीप',
                      hint: 'Paid from Rahul GPay',
                      prefixIcon: Icons.notes_rounded,
                    ),
                    const SizedBox(height: 18),
                    CustomButton(
                      text: 'Submit for Owner Approval',
                      icon: Icons.send_rounded,
                      isLoading: _isSubmitting,
                      onPressed: _onSubmitVerification,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _appButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

