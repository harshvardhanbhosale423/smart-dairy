import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/payment_provider.dart';
import '../../customers/models/customer_model.dart';
import '../../customers/providers/customer_provider.dart';
import '../../billing/models/monthly_bill_model.dart';
import '../../auth/providers/auth_provider.dart';

class RecordPaymentScreen extends StatefulWidget {
  final CustomerModel? preSelectedCustomer;
  final MonthlyBillModel? preSelectedBill;

  const RecordPaymentScreen({
    super.key,
    this.preSelectedCustomer,
    this.preSelectedBill,
  });

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  CustomerModel? _selectedCustomer;
  late TextEditingController _amountController;
  late TextEditingController _txnRefController;
  late TextEditingController _notesController;

  String _paymentMethod = 'CASH'; // 'CASH', 'UPI', 'BANK_TRANSFER'

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preSelectedCustomer;

    final initialAmount = widget.preSelectedBill?.finalPayable ??
        (widget.preSelectedCustomer != null && widget.preSelectedCustomer!.currentBalance > 0
            ? widget.preSelectedCustomer!.currentBalance
            : 0.0);

    _amountController = TextEditingController(text: initialAmount > 0 ? initialAmount.toStringAsFixed(0) : '');
    _txnRefController = TextEditingController(text: 'CASH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _txnRefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSavePayment() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('select_customer')), backgroundColor: AppColors.error),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final paymentProvider = context.read<PaymentProvider>();

    final success = await paymentProvider.recordPayment(
      ownerId: user.uid,
      customer: _selectedCustomer!,
      billId: widget.preSelectedBill?.id,
      amount: amount,
      paymentMethod: _paymentMethod,
      transactionRef: _txnRefController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('पेमेंट जमा नोंद यशस्वी झाली! / Received ${CurrencyFormatter.format(amount)}'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (paymentProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(paymentProvider.errorMessage!), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final customers = customerProvider.allCustomers;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('record_payment')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Customer Selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${context.tr('select_customer')} *', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<CustomerModel>(
                      value: _selectedCustomer,
                      isExpanded: true,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.person_rounded, size: 20)),
                      hint: Text(context.tr('select_customer')),
                      items: customers.map((c) {
                        return DropdownMenuItem<CustomerModel>(
                          value: c,
                          child: Text('${c.name} (Due: ${CurrencyFormatter.format(c.currentBalance)})'),
                        );
                      }).toList(),
                      onChanged: (c) {
                        setState(() {
                          _selectedCustomer = c;
                          if (c != null && c.currentBalance > 0) {
                            _amountController.text = c.currentBalance.toStringAsFixed(0);
                          }
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Amount
                CustomTextField(
                  controller: _amountController,
                  label: '${context.tr('amount')} (₹) *',
                  hint: '1000',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.currency_rupee_rounded,
                  validator: (v) => Validators.validateNumber(v, context.tr('amount'), allowZero: false),
                ),

                const SizedBox(height: 16),

                // Payment Method Selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('payment_method'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _methodChip('CASH', 'Cash (रोख)', Icons.money_rounded),
                        const SizedBox(width: 8),
                        _methodChip('UPI', 'UPI', Icons.qr_code_rounded),
                        const SizedBox(width: 8),
                        _methodChip('BANK_TRANSFER', 'Bank', Icons.account_balance_rounded),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Transaction Ref / Receipt No
                CustomTextField(
                  controller: _txnRefController,
                  label: '${context.tr('txn_reference')} *',
                  hint: 'UPI-123456789 or Receipt #',
                  prefixIcon: Icons.receipt_rounded,
                  validator: (v) => Validators.validateRequired(v, 'Reference ID'),
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: _notesController,
                  label: context.tr('notes'),
                  hint: 'उदा. रोख रक्कम घरी आणून दिली',
                  prefixIcon: Icons.note_rounded,
                  maxLines: 2,
                ),

                const SizedBox(height: 28),

                CustomButton(
                  text: 'Confirm & Credit Ledger / जमा नोंद करा',
                  icon: Icons.check_circle_rounded,
                  isLoading: paymentProvider.isLoading,
                  onPressed: _onSavePayment,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _methodChip(String methodKey, String label, IconData icon) {
    final isSelected = _paymentMethod == methodKey;
    return Expanded(
      child: ChoiceChip(
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.darkGreen : AppColors.textMuted),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            setState(() {
              _paymentMethod = methodKey;
              if (methodKey == 'CASH') {
                _txnRefController.text = 'CASH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
              } else {
                _txnRefController.clear();
              }
            });
          }
        },
        selectedColor: AppColors.softLightGreen,
      ),
    );
  }
}

