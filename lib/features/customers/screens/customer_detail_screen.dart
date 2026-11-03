import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../models/customer_model.dart';
import '../providers/customer_provider.dart';
import 'add_edit_customer_screen.dart';
import '../../ledger/screens/customer_ledger_screen.dart';
import '../../milk_entry/repositories/milk_entry_repository.dart';
import '../../milk_entry/models/milk_entry_model.dart';
import '../../milk_entry/screens/daily_milk_entry_screen.dart';
import '../../payments/screens/record_payment_screen.dart';
import '../../../core/services/app_launcher.dart';

class CustomerDetailScreen extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailScreen({super.key, required this.customer});

  void _call(BuildContext context, String phone) async {
    await AppLauncher.makePhoneCall(context, phone);
  }

  void _whatsapp(BuildContext context, String phone) async {
    await AppLauncher.openWhatsApp(context: context, phone: phone);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customerProvider = context.watch<CustomerProvider>();
    final currentCustomer = customerProvider.allCustomers.firstWhere(
      (c) => c.id == customer.id,
      orElse: () => customer,
    );

    final hasDue = currentCustomer.currentBalance > 0;
    final isAdvance = currentCustomer.currentBalance < 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentCustomer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: context.tr('edit'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditCustomerScreen(customer: currentCustomer)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Outstanding Balance Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasDue
                      ? [AppColors.error.withOpacity(0.85), AppColors.error]
                      : [AppColors.darkGreen, AppColors.primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (hasDue ? AppColors.error : AppColors.darkGreen).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isAdvance ? 'Advance Balance / जमा रक्कम' : context.tr('current_balance'),
                    style: TextStyle(
                      color: AppColors.pureWhite.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(currentCustomer.currentBalance.abs()),
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecordPaymentScreen(preSelectedCustomer: currentCustomer),
                            ),
                          );
                        },
                        icon: const Icon(Icons.payment_rounded, size: 16),
                        label: Text(context.tr('record_payment')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pureWhite,
                          foregroundColor: hasDue ? AppColors.error : AppColors.darkGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerLedgerScreen(customer: currentCustomer),
                            ),
                          );
                        },
                        icon: const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.pureWhite),
                        label: Text(context.tr('ledger'), style: const TextStyle(color: AppColors.pureWhite)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.pureWhite, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Profile info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.pureWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.dividerColor.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  _infoRow(
                    icon: Icons.phone_android_rounded,
                    label: context.tr('phone_number'),
                    value: currentCustomer.phone,
                    action: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.call, color: AppColors.darkGreen, size: 18),
                          onPressed: () => _call(context, currentCustomer.phone),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat, color: AppColors.lightGreen, size: 18),
                          onPressed: () => _whatsapp(context, currentCustomer.phone),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                  _infoRow(
                    icon: Icons.location_on_rounded,
                    label: context.tr('address'),
                    value: currentCustomer.address.isNotEmpty ? currentCustomer.address : 'Not specified',
                  ),
                  const Divider(height: 16),
                  _infoRow(
                    icon: Icons.local_drink_rounded,
                    label: 'Daily Quota',
                    value: 'Morning: ${currentCustomer.morningQuota}L | Evening: ${currentCustomer.eveningQuota}L (Total: ${currentCustomer.dailyTotalQuota}L)',
                  ),
                  const Divider(height: 16),
                  _infoRow(
                    icon: Icons.currency_rupee_rounded,
                    label: context.tr('milk_rate'),
                    value: '₹${currentCustomer.milkRate.toStringAsFixed(0)} / Litre',
                  ),
                  const Divider(height: 16),
                  _infoRow(
                    icon: Icons.calendar_today_rounded,
                    label: context.tr('joining_date'),
                    value: DateFormatter.formatShortDate(currentCustomer.joiningDate),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // App Credentials Card & WhatsApp Share
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.softCream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.vpn_key_rounded, color: AppColors.darkGreen, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'ग्राहक ॲप लॉगिन माहिती (Login Details)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('युझरनेम (Username):', style: TextStyle(fontWeight: FontWeight.w500)),
                      SelectableText(
                        currentCustomer.username ?? currentCustomer.phone,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('पासवर्ड (Password):', style: TextStyle(fontWeight: FontWeight.w500)),
                      SelectableText(
                        currentCustomer.password ?? '123456',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final u = currentCustomer.username ?? currentCustomer.phone;
                        final p = currentCustomer.password ?? '123456';
                        final msg = 'नमस्कार ${currentCustomer.name},\nस्मार्ट डेअरी ॲपमध्ये आपले स्वागत आहे! 🥛\n\nआपले लॉगिन तपशील:\nयुझरनेम: $u\nपासवर्ड: $p\n\nॲप डाऊनलोड करा:\nhttps://github.com/harshvardhanbhosale423/smart-dairy/releases/download/v1.0.5/app-release.apk';
                        AppLauncher.openWhatsApp(
                          context: context,
                          phone: currentCustomer.phone,
                          message: msg,
                        );
                      },
                      icon: const Icon(Icons.share_rounded, color: AppColors.darkGreen, size: 18),
                      label: const Text(
                        'WhatsApp वर लॉगिन माहिती पाठवा',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.darkGreen),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Customer Status Toggle & Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await ConfirmationDialog.show(
                        context,
                        title: currentCustomer.isActive ? 'Pause Delivery?' : 'Resume Delivery?',
                        message: currentCustomer.isActive
                            ? 'दूध वाटप तात्पुरते थांबवायचे आहे का?'
                            : 'दूध वाटप पुन्हा सुरू करायचे आहे का?',
                        confirmText: context.tr('confirm'),
                      );
                      if (confirm == true) {
                        await customerProvider.toggleCustomerPause(currentCustomer);
                      }
                    },
                    icon: Icon(currentCustomer.isActive ? Icons.pause_circle_rounded : Icons.play_circle_rounded, size: 18),
                    label: Text(currentCustomer.isActive ? context.tr('pause_delivery') : context.tr('resume_delivery')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentCustomer.isActive ? AppColors.warning : AppColors.darkGreen,
                      foregroundColor: AppColors.pureWhite,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Milk Delivery History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Milk Entries / अलीकडील दूध नोंद',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyMilkEntryScreen(preSelectedCustomer: currentCustomer),
                      ),
                    );
                  },
                  child: const Text('Add Entry'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            StreamBuilder<List<MilkEntryModel>>(
              stream: MilkEntryRepository().getEntriesForCustomer(currentCustomer.id, limit: 10),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                }
                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'No milk entries recorded yet.\nदैनिक दूध नोंद करण्यासाठी वरील बटनावर टॅप करा.',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return Column(
                  children: entries.map((e) => Card(
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
                        DateFormatter.formatDate(e.date),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        e.isZeroMilk ? 'Holiday / No delivery' : 'M: ${e.morningQty}L | E: ${e.eveningQty}L @ ₹${e.ratePerLitre.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        CurrencyFormatter.format(e.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  )).toList(),
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? action,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.darkGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (action != null) action,
      ],
    );
  }
}

