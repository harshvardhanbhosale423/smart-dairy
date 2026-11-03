import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/app_launcher.dart';
import '../../../core/services/local_database_service.dart';
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
  late String _activeUpiId;
  late String _activeDairyName;
  String _ownerPhone = '';

  @override
  void initState() {
    super.initState();
    _activeUpiId = widget.ownerUpiId.trim();
    _activeDairyName = widget.dairyName.trim();
    _resolveRealOwnerDetails();
  }

  void _resolveRealOwnerDetails() {
    final localDb = LocalDatabaseService();
    // 1. Try owner ID from bill or customer
    final targetOwnerId = widget.bill?.ownerId ?? widget.customer.ownerId;
    var profile = localDb.get('dairy_profiles', targetOwnerId);

    if (profile == null) {
      final allProfiles = localDb.getAll('dairy_profiles');
      if (allProfiles.isNotEmpty) profile = allProfiles.first;
    }

    if (profile != null) {
      final loadedUpi = (profile['ownerUpiId'] ?? '').toString().trim();
      final loadedDairy = (profile['dairyName'] ?? '').toString().trim();
      final holderName = (profile['accountHolderName'] ?? profile['ownerName'] ?? '').toString().trim();
      final loadedPhone = (profile['ownerPhone'] ?? '').toString().trim();

      setState(() {
        if (loadedUpi.isNotEmpty && UpiService.isValidUpiId(loadedUpi)) {
          _activeUpiId = loadedUpi;
        }
        if (holderName.isNotEmpty) {
          _activeDairyName = '$loadedDairy ($holderName)';
        } else if (loadedDairy.isNotEmpty) {
          _activeDairyName = loadedDairy;
        }
        _ownerPhone = loadedPhone;
      });
    }
  }

  @override
  void dispose() {
    _txnIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isUpiConfigured => UpiService.isValidUpiId(_activeUpiId);

  String get _upiUri {
    return UpiService.buildUpiUri(
      upiId: _activeUpiId,
      payeeName: _activeDairyName,
      amount: widget.payableAmount,
      transactionNote: 'Milk-${widget.customer.name}',
    );
  }

  void _launchGenericUpi() async {
    if (!_isUpiConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('डेअरी मालकाचा UPI ID अद्याप सेट केलेला नाही.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final success = await UpiService.launchUpiIntent(upiUri: _upiUri);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('UPI ॲप सुरू करता आले नाही. कृपया खालील QR कोड स्कॅन करा.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _launchApp(String appScheme) async {
    if (!_isUpiConfigured) return;

    final success = await UpiService.launchSpecificApp(
      upiId: _activeUpiId,
      payeeName: _activeDairyName,
      amount: widget.payableAmount,
      transactionNote: 'Milk-${widget.customer.name}',
      appScheme: appScheme,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('हे UPI ॲप सापडले नाही. कृपया खालील QR कोड स्कॅन करा किंवा इतर ॲप वापरा.'),
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
          title: const Text('पेमेंट माहिती मालकाकडे पाठवली!'),
          content: const Text(
            'आपला UPI Transaction Ref ID / UTR डेअरी मालकाकडे पडताळणीसाठी पाठवला आहे. मालकाने खात्री केल्यानंतर आपले खाते जमा केले जाईल.\n\nधन्यवाद! (Smart Dairy)',
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
            // Amount & Payee Summary Card
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
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppColors.darkGreen, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'पैसे कोणाला जमा होतील: $_activeDairyName',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  if (_isUpiConfigured) ...[
                    const SizedBox(height: 4),
                    Text(
                      'मालकाचा UPI ID: $_activeUpiId',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Warning if Owner UPI is not configured
            if (!_isUpiConfigured) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade700, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'पेमेंट सुरक्षा तपासणी / Alert',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'डेअरी मालकांचा UPI ID अद्याप जोडलेला नाही. पैसे भलत्याच खात्यात जाऊ नयेत म्हणून ऑनलाइन पेमेंट थांबवले आहे.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'मालकांसाठी: Settings > UPI Settings मध्ये जाऊन स्वतःचा अचूक UPI ID भरा.',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black54),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => AppLauncher.makePhoneCall(context, _ownerPhone),
                            icon: const Icon(Icons.call, size: 18),
                            label: const Text('मालकांना कॉल करा'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => AppLauncher.openWhatsApp(
                              context: context,
                              phone: _ownerPhone,
                              message: 'नमस्कार, Smart Dairy ॲपमध्ये पेमेंट करण्यासाठी कृपया आपला UPI ID द्या.',
                            ),
                            icon: const Icon(Icons.chat, size: 18),
                            label: const Text('WhatsApp'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              // Big Direct Payment Button
              ElevatedButton.icon(
                onPressed: _launchGenericUpi,
                icon: const Icon(Icons.account_balance_wallet_rounded, size: 22),
                label: const Text(
                  'कोणत्याही UPI ॲपने पैसे भरा (Pay via UPI)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 20),

              // Specific UPI Apps Chooser
              const Text(
                'किंवा खालीलपैकी एक ॲप निवडा:',
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
                  _appButton('BHIM UPI', Icons.security, Colors.green, () => _launchApp('bhim')),
                ],
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
                      Text(
                        'Scan to Pay directly to $_activeDairyName',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

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
                      'Payment Confirmation / पावती नोंदवा',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'पेमेंट केल्यावर UPI ॲपमधील १२ अंकी UTR / Transaction Ref ID किंवा रोख दिले असल्यास पावती नोंद खाली टाका:',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _txnIdController,
                      label: 'UPI UTR / Transaction ID *',
                      hint: 'उदा. 429812345678 किंवा CASH',
                      prefixIcon: Icons.receipt_long_rounded,
                      validator: (v) => Validators.validateRequired(v, 'Transaction ID'),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _notesController,
                      label: 'Optional Note / टीप',
                      hint: 'उदा. PhonePe वरून दिले / रोख दिले',
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
