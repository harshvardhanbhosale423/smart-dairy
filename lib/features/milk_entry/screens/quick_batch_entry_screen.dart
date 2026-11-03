import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/milk_entry_provider.dart';
import '../../customers/models/customer_model.dart';
import '../../customers/providers/customer_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/milk_entry_model.dart';
import '../../../core/services/sms_service.dart';
import '../../../core/services/local_database_service.dart';

class QuickBatchEntryScreen extends StatefulWidget {
  const QuickBatchEntryScreen({super.key});

  @override
  State<QuickBatchEntryScreen> createState() => _QuickBatchEntryScreenState();
}

class _QuickBatchEntryScreenState extends State<QuickBatchEntryScreen> {
  final Map<String, TextEditingController> _morningControllers = {};
  final Map<String, TextEditingController> _eveningControllers = {};
  final Map<String, bool> _zeroMilkFlags = {};

  bool _isSavingAll = false;

  @override
  void initState() {
    super.initState();
    final customers = context.read<CustomerProvider>().allCustomers.where((c) => c.isActive).toList();
    for (final c in customers) {
      _morningControllers[c.id] = TextEditingController(text: c.morningQuota.toString());
      _eveningControllers[c.id] = TextEditingController(text: c.eveningQuota.toString());
      _zeroMilkFlags[c.id] = false;
    }
  }

  @override
  void dispose() {
    for (final c in _morningControllers.values) c.dispose();
    for (final c in _eveningControllers.values) c.dispose();
    super.dispose();
  }

  void _onSaveAll() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final entryProvider = context.read<MilkEntryProvider>();
    final customers = context.read<CustomerProvider>().allCustomers.where((c) => c.isActive).toList();

    setState(() => _isSavingAll = true);

    final localDb = LocalDatabaseService();
    final profile = localDb.get('dairy_profiles', user.uid);
    final dairyName = (profile?['dairyName'] ?? user.name ?? 'Smart Dairy').toString();

    int count = 0;
    for (final c in customers) {
      final isZero = _zeroMilkFlags[c.id] ?? false;
      final morning = isZero ? 0.0 : (double.tryParse(_morningControllers[c.id]?.text.trim() ?? '') ?? c.morningQuota);
      final evening = isZero ? 0.0 : (double.tryParse(_eveningControllers[c.id]?.text.trim() ?? '') ?? c.eveningQuota);

      await entryProvider.saveEntry(
        ownerId: user.uid,
        customer: c,
        date: entryProvider.selectedDate,
        morningQty: morning,
        eveningQty: evening,
        rate: c.milkRate,
        isZeroMilk: isZero,
      );

      // Automatic SMS
      final savedEntry = MilkEntryModel.create(
        id: 'entry_${DateTime.now().millisecondsSinceEpoch}_${c.id}',
        ownerId: user.uid,
        customerId: c.id,
        customerName: c.name,
        customerPhone: c.phone,
        date: entryProvider.selectedDate,
        morningQty: morning,
        eveningQty: evening,
        ratePerLitre: c.milkRate,
        isZeroMilk: isZero,
      );
      SmsService.sendMilkEntrySms(
        customer: c,
        entry: savedEntry,
        dairyName: dairyName,
      );

      count++;
    }

    setState(() => _isSavingAll = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count ग्राहकांची दूध नोंद जतन झाली व SMS पाठवला! 🥛📩'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entryProvider = context.watch<MilkEntryProvider>();
    final customers = context.watch<CustomerProvider>().allCustomers.where((c) => c.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('quick_batch_entry')),
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
        child: CustomButton(
          text: 'Save All Today\'s Milk / सर्व नोंदी जतन करा (${customers.length})',
          icon: Icons.done_all_rounded,
          isLoading: _isSavingAll,
          onPressed: customers.isEmpty ? null : _onSaveAll,
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppColors.darkCard : AppColors.softLightGreen.withOpacity(0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: ${DateFormatter.formatDate(entryProvider.selectedDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${customers.length} Active Customers',
                  style: const TextStyle(fontSize: 12, color: AppColors.darkGreen, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: customers.length,
              itemBuilder: (ctx, index) {
                final customer = customers[index];
                final isZero = _zeroMilkFlags[customer.id] ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              customer.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              '₹${customer.milkRate.toStringAsFixed(0)}/L',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.darkGreen),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _morningControllers[customer.id],
                                enabled: !isZero,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Morn (L)',
                                  isDense: true,
                                  prefixIcon: Icon(Icons.wb_sunny_rounded, size: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _eveningControllers[customer.id],
                                enabled: !isZero,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Eve (L)',
                                  isDense: true,
                                  prefixIcon: Icon(Icons.nights_stay_rounded, size: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _zeroMilkFlags[customer.id] = !isZero;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isZero ? AppColors.error.withOpacity(0.12) : AppColors.dividerColor.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isZero ? AppColors.error : AppColors.dividerColor,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isZero ? 'Zero' : 'Absent?',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isZero ? AppColors.error : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

