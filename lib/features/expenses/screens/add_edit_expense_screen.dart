import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/expense_provider.dart';
import '../../auth/providers/auth_provider.dart';

class AddEditExpenseScreen extends StatefulWidget {
  const AddEditExpenseScreen({super.key});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  String _category = 'cow_feed';
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _paymentMethod = 'CASH';
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final provider = context.read<ExpenseProvider>();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final success = await provider.addExpense(
      ownerId: user.uid,
      category: _category,
      amount: amount,
      description: _descController.text.trim(),
      paymentMethod: _paymentMethod,
      date: _date,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('खर्च नोंद यशस्वीरित्या जतन झाली / Expense Saved!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('add_expense')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category Picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${context.tr('expense_category')} *', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _category,
                      isExpanded: true,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.category_rounded, size: 20)),
                      items: AppConstants.expenseCategories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(context.tr(cat)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Amount
                CustomTextField(
                  controller: _amountController,
                  label: '${context.tr('amount')} (₹) *',
                  hint: '500',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.currency_rupee_rounded,
                  validator: (v) => Validators.validateNumber(v, context.tr('amount'), allowZero: false),
                ),

                const SizedBox(height: 16),

                // Date Picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('date'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.dividerColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormatter.formatShortDate(_date)),
                            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.darkGreen),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Payment Method
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('payment_method'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _methodChip('CASH', 'Cash'),
                        const SizedBox(width: 8),
                        _methodChip('UPI', 'UPI'),
                        const SizedBox(width: 8),
                        _methodChip('BANK', 'Bank Transfer'),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Description
                CustomTextField(
                  controller: _descController,
                  label: 'Description / शेरा',
                  hint: 'उदा. १ गोणी सरकी ढेप / २० लिटर डिझेल',
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 2,
                ),

                const SizedBox(height: 28),

                CustomButton(
                  text: context.tr('save'),
                  icon: Icons.check_circle_rounded,
                  isLoading: provider.isLoading,
                  onPressed: _onSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _methodChip(String methodKey, String label) {
    final isSelected = _paymentMethod == methodKey;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
        selected: isSelected,
        onSelected: (val) {
          if (val) setState(() => _paymentMethod = methodKey);
        },
        selectedColor: AppColors.softLightGreen,
      ),
    );
  }
}

