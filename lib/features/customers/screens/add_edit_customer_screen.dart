import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../models/customer_model.dart';
import '../providers/customer_provider.dart';
import '../../auth/providers/auth_provider.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final CustomerModel? customer;

  const AddEditCustomerScreen({super.key, this.customer});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _morningController;
  late TextEditingController _eveningController;
  late TextEditingController _rateController;
  late TextEditingController _openingBalanceController;
  late TextEditingController _notesController;

  late DateTime _joiningDate;
  String _status = 'active';

  bool get isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _morningController = TextEditingController(text: c?.morningQuota.toString() ?? '1.0');
    _eveningController = TextEditingController(text: c?.eveningQuota.toString() ?? '1.0');
    _rateController = TextEditingController(text: c?.milkRate.toString() ?? '60');
    _openingBalanceController = TextEditingController(text: c?.currentBalance.toString() ?? '0');
    _notesController = TextEditingController(text: c?.notes ?? '');
    _joiningDate = c?.joiningDate ?? DateTime.now();
    _status = c?.status ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _morningController.dispose();
    _eveningController.dispose();
    _rateController.dispose();
    _openingBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectJoiningDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _joiningDate = picked);
    }
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final provider = context.read<CustomerProvider>();
    final morning = double.tryParse(_morningController.text.trim()) ?? 1.0;
    final evening = double.tryParse(_eveningController.text.trim()) ?? 1.0;
    final rate = double.tryParse(_rateController.text.trim()) ?? 60.0;
    final openingBal = double.tryParse(_openingBalanceController.text.trim()) ?? 0.0;

    bool success;
    if (isEditing) {
      final updated = widget.customer!.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        morningQuota: morning,
        eveningQuota: evening,
        milkRate: rate,
        joiningDate: _joiningDate,
        status: _status,
        notes: _notesController.text.trim(),
      );
      success = await provider.updateCustomer(updated);
    } else {
      success = await provider.addCustomer(
        ownerId: user.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        morningQuota: morning,
        eveningQuota: evening,
        milkRate: rate,
        joiningDate: _joiningDate,
        openingBalance: openingBal,
        notes: _notesController.text.trim(),
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Customer updated successfully' : 'Customer added successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (provider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage!), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? context.tr('edit') : context.tr('add_customer')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _nameController,
                  label: '${context.tr('name')} *',
                  hint: 'उदा. राहुल पाटील',
                  prefixIcon: Icons.person_rounded,
                  validator: (v) => Validators.validateRequired(v, context.tr('name')),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _phoneController,
                  label: '${context.tr('phone_number')} *',
                  hint: '9822XXXXXX',
                  prefixIcon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _addressController,
                  label: context.tr('address'),
                  hint: 'उदा. घर नं १२, मारुती गल्ली',
                  prefixIcon: Icons.home_rounded,
                ),
                const SizedBox(height: 16),

                // Morning & Evening Quota
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _morningController,
                        label: '${context.tr('morning_quota')} *',
                        hint: '1.0',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.wb_sunny_rounded,
                        validator: (v) => Validators.validateNumber(v, 'Morning Quota'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _eveningController,
                        label: '${context.tr('evening_quota')} *',
                        hint: '1.0',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.nights_stay_rounded,
                        validator: (v) => Validators.validateNumber(v, 'Evening Quota'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Rate per Litre
                CustomTextField(
                  controller: _rateController,
                  label: '${context.tr('milk_rate')} *',
                  hint: '60',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.currency_rupee_rounded,
                  validator: (v) => Validators.validateNumber(v, context.tr('milk_rate'), allowZero: false),
                ),
                const SizedBox(height: 16),

                // Joining Date Picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('joining_date'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _selectJoiningDate,
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
                            Text(DateFormatter.formatShortDate(_joiningDate)),
                            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.darkGreen),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Opening Balance (Only shown on new customer add)
                if (!isEditing) ...[
                  CustomTextField(
                    controller: _openingBalanceController,
                    label: 'Opening Balance / सुरुवातीची येणे बाकी (₹)',
                    hint: '0',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.account_balance_wallet_rounded,
                    validator: (v) => Validators.validateNumber(v, 'Opening Balance'),
                  ),
                  const SizedBox(height: 16),
                ],

                // Status Dropdown
                if (isEditing) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('status'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        items: [
                          DropdownMenuItem(value: 'active', child: Text(context.tr('status_active'))),
                          DropdownMenuItem(value: 'paused', child: Text(context.tr('status_paused'))),
                          DropdownMenuItem(value: 'inactive', child: Text(context.tr('status_inactive'))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                CustomTextField(
                  controller: _notesController,
                  label: context.tr('notes'),
                  hint: 'उदा. विशेष सूचना किंवा माहिती',
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

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

