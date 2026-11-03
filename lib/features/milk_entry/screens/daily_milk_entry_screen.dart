import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../models/milk_entry_model.dart';
import '../providers/milk_entry_provider.dart';
import '../../customers/models/customer_model.dart';
import '../../customers/providers/customer_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'quick_batch_entry_screen.dart';
import '../../../core/services/sms_service.dart';
import '../../../core/services/local_database_service.dart';

class DailyMilkEntryScreen extends StatefulWidget {
  final CustomerModel? preSelectedCustomer;

  const DailyMilkEntryScreen({super.key, this.preSelectedCustomer});

  @override
  State<DailyMilkEntryScreen> createState() => _DailyMilkEntryScreenState();
}

class _DailyMilkEntryScreenState extends State<DailyMilkEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  CustomerModel? _selectedCustomer;
  late TextEditingController _morningController;
  late TextEditingController _eveningController;
  late TextEditingController _rateController;
  late TextEditingController _notesController;

  bool _isZeroMilk = false;
  double _calculatedTotalQty = 0.0;
  double _calculatedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preSelectedCustomer;

    final morning = _selectedCustomer?.morningQuota ?? 1.0;
    final evening = _selectedCustomer?.eveningQuota ?? 1.0;
    final rate = _selectedCustomer?.milkRate ?? 60.0;

    _morningController = TextEditingController(text: morning.toString());
    _eveningController = TextEditingController(text: evening.toString());
    _rateController = TextEditingController(text: rate.toString());
    _notesController = TextEditingController();

    _updateCalculations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<MilkEntryProvider>().listenToDailyEntries(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _morningController.dispose();
    _eveningController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onCustomerChanged(CustomerModel? customer) {
    if (customer == null) return;
    setState(() {
      _selectedCustomer = customer;
      _morningController.text = customer.morningQuota.toString();
      _eveningController.text = customer.eveningQuota.toString();
      _rateController.text = customer.milkRate.toString();
      _isZeroMilk = false;
      _updateCalculations();
    });
  }

  void _updateCalculations() {
    if (_isZeroMilk) {
      setState(() {
        _calculatedTotalQty = 0.0;
        _calculatedAmount = 0.0;
      });
      return;
    }

    final morning = double.tryParse(_morningController.text.trim()) ?? 0.0;
    final evening = double.tryParse(_eveningController.text.trim()) ?? 0.0;
    final rate = double.tryParse(_rateController.text.trim()) ?? 0.0;

    setState(() {
      _calculatedTotalQty = morning + evening;
      _calculatedAmount = _calculatedTotalQty * rate;
    });
  }

  Future<void> _selectDate() async {
    final entryProvider = context.read<MilkEntryProvider>();
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: entryProvider.selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null) {
      entryProvider.setDate(picked, user.uid);
    }
  }

  void _changeDateBy(int days) {
    final entryProvider = context.read<MilkEntryProvider>();
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final newDate = entryProvider.selectedDate.add(Duration(days: days));
    entryProvider.setDate(newDate, user.uid);
  }

  void _onSaveEntry() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('select_customer')), backgroundColor: AppColors.error),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final entryProvider = context.read<MilkEntryProvider>();
    final morning = _isZeroMilk ? 0.0 : (double.tryParse(_morningController.text.trim()) ?? 0.0);
    final evening = _isZeroMilk ? 0.0 : (double.tryParse(_eveningController.text.trim()) ?? 0.0);
    final rate = double.tryParse(_rateController.text.trim()) ?? 60.0;

    final success = await entryProvider.saveEntry(
      ownerId: user.uid,
      customer: _selectedCustomer!,
      date: entryProvider.selectedDate,
      morningQty: morning,
      eveningQty: evening,
      rate: rate,
      isZeroMilk: _isZeroMilk,
      notes: _notesController.text.trim(),
    );

    if (success && mounted) {
      final savedEntry = MilkEntryModel.create(
        id: 'entry_${DateTime.now().millisecondsSinceEpoch}',
        ownerId: user.uid,
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        customerPhone: _selectedCustomer!.phone,
        date: entryProvider.selectedDate,
        morningQty: morning,
        eveningQty: evening,
        ratePerLitre: rate,
        isZeroMilk: _isZeroMilk,
        notes: _notesController.text.trim(),
      );

      final localDb = LocalDatabaseService();
      final dairyProfile = localDb.get('dairy_profiles', user.uid);
      final dairyName = (dairyProfile?['dairyName'] ?? user.name ?? 'Smart Dairy').toString();

      // Automatic SMS via owner's SIM daily recharge
      SmsService.sendMilkEntrySms(
        customer: _selectedCustomer!,
        entry: savedEntry,
        dairyName: dairyName,
        context: context,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('दूध नोंद जतन झाली व ग्राहकाला SMS पाठवला! 🥛📩'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
      _notesController.clear();
    } else if (entryProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(entryProvider.errorMessage!), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeProvider = context.watch<LocaleProvider>();
    final entryProvider = context.watch<MilkEntryProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final activeCustomers = customerProvider.allCustomers.where((c) => c.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('milk_entry')),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            tooltip: context.tr('quick_batch_entry'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuickBatchEntryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Date Selector Bar with Previous/Next Arrows
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? AppColors.darkCard : AppColors.softLightGreen.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                    onPressed: () => _changeDateBy(-1),
                    tooltip: 'Previous Day',
                  ),
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.darkGreen),
                          const SizedBox(width: 8),
                          Text(
                            DateFormatter.formatDate(entryProvider.selectedDate, isMarathi: localeProvider.isMarathi),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppColors.darkGreen),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    onPressed: () => _changeDateBy(1),
                    tooltip: 'Next Day',
                  ),
                ],
              ),
            ),

            // Daily Milk Totals Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? AppColors.darkSurface : AppColors.surfaceLight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today: ${entryProvider.todayGrandTotalLitres.toStringAsFixed(1)} Litres (M: ${entryProvider.todayMorningTotal.toStringAsFixed(1)}L | E: ${entryProvider.todayEveningTotal.toStringAsFixed(1)}L)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    CurrencyFormatter.format(entryProvider.todayGrandTotalAmount),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // MANUAL ENTRY NOTICE
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.goldenYellow.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.goldenYellow, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr('manual_entry_note'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Customer Dropdown Picker
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${context.tr('select_customer')} *', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<CustomerModel>(
                          value: _selectedCustomer,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person_rounded, size: 20),
                          ),
                          hint: Text(context.tr('select_customer')),
                          items: activeCustomers.map((cust) {
                            return DropdownMenuItem<CustomerModel>(
                              value: cust,
                              child: Text(
                                '${cust.name} (${cust.dailyTotalQuota}L @ ₹${cust.milkRate.toStringAsFixed(0)})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _onCustomerChanged,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Zero Milk / Delivery Holiday Checkbox
                    CheckboxListTile(
                      value: _isZeroMilk,
                      onChanged: (val) {
                        setState(() {
                          _isZeroMilk = val ?? false;
                          _updateCalculations();
                        });
                      },
                      title: Text(
                        context.tr('is_zero_milk'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('खंड / सुट्टी असल्यास निवडा', style: TextStyle(fontSize: 11)),
                      activeColor: AppColors.darkGreen,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    const SizedBox(height: 8),

                    if (!_isZeroMilk) ...[
                      // Morning & Evening Quantities
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _morningController,
                              label: '${context.tr('morning')} (L) *',
                              hint: '1.0',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              prefixIcon: Icons.wb_sunny_rounded,
                              onChanged: (_) => _updateCalculations(),
                              validator: (v) => _isZeroMilk ? null : Validators.validateNumber(v, 'Morning Milk'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _eveningController,
                              label: '${context.tr('evening')} (L) *',
                              hint: '1.0',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              prefixIcon: Icons.nights_stay_rounded,
                              onChanged: (_) => _updateCalculations(),
                              validator: (v) => _isZeroMilk ? null : Validators.validateNumber(v, 'Evening Milk'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Rate per Litre
                      CustomTextField(
                        controller: _rateController,
                        label: '${context.tr('rate_per_litre')} *',
                        hint: '60',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.currency_rupee_rounded,
                        onChanged: (_) => _updateCalculations(),
                        validator: (v) => Validators.validateNumber(v, 'Rate', allowZero: false),
                      ),

                      const SizedBox(height: 16),
                    ],

                    // Total Calculation Preview Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.softLightGreen.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr('total_milk'), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              Text(
                                '${_calculatedTotalQty.toStringAsFixed(1)} Litres',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(context.tr('daily_amount'), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              Text(
                                CurrencyFormatter.format(_calculatedAmount),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _notesController,
                      label: context.tr('notes'),
                      hint: 'उदा. सणासाठी १ लिटर जास्त दिले / Special note',
                      prefixIcon: Icons.comment_rounded,
                    ),

                    const SizedBox(height: 24),

                    CustomButton(
                      text: context.tr('save'),
                      icon: Icons.check_circle_rounded,
                      isLoading: entryProvider.isLoading,
                      onPressed: _onSaveEntry,
                    ),

                    const SizedBox(height: 32),

                    // Daily Entries Table for Selected Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Entries on this date (${entryProvider.dailyEntries.length})',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (entryProvider.dailyEntries.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.dividerColor.withOpacity(0.5)),
                        ),
                        child: Center(
                          child: Text(
                            'No entries saved yet for this date.\nया तारखेला कोणतीही नोंद नाही.',
                            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ...entryProvider.dailyEntries.map((e) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: e.isZeroMilk ? AppColors.dividerColor : AppColors.softLightGreen,
                            child: Text(
                              e.isZeroMilk ? '0L' : '${e.totalQty.toStringAsFixed(1)}L',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: e.isZeroMilk ? AppColors.textMuted : AppColors.darkGreen,
                              ),
                            ),
                          ),
                          title: Text(
                            e.customerName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            e.isZeroMilk ? 'Holiday' : 'M: ${e.morningQty}L | E: ${e.eveningQty}L (${CurrencyFormatter.format(e.totalAmount)})',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                            onPressed: () async {
                              final confirm = await ConfirmationDialog.show(
                                context,
                                title: 'Delete Entry?',
                                message: 'Are you sure you want to delete this milk entry of ${e.totalQty}L for ${e.customerName}?\nरक्कम खतावणीतून वजा केली जाईल.',
                                isDestructive: true,
                              );
                              if (confirm == true) {
                                await entryProvider.deleteEntry(e);
                              }
                            },
                          ),
                        ),
                      )),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

