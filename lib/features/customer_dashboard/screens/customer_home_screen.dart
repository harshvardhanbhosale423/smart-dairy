import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../core/services/local_database_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/models/customer_model.dart';
import '../../billing/models/monthly_bill_model.dart';
import '../../milk_entry/models/milk_entry_model.dart';
import '../../payments/screens/upi_payment_screen.dart';
import '../../../core/services/app_launcher.dart';

class CustomerHomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const CustomerHomeScreen({super.key, this.onNavigateTab});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  CustomerModel? _customer;
  MonthlyBillModel? _latestBill;
  MilkEntryModel? _lastMilkEntry;
  String _ownerUpiId = '';
  String _dairyName = 'Smart Dairy';
  String _ownerPhone = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || user.customerId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final localDb = LocalDatabaseService();

    // 1. Fetch Customer Record locally first (offline-first)
    final custMap = localDb.get('customers', user.customerId!);
    if (custMap != null) {
      _customer = CustomerModel.fromMap(custMap, user.customerId!);
      var dairyMap = localDb.get('dairy_profiles', _customer!.ownerId);
      if (dairyMap == null && user.dairyId != null && user.dairyId!.isNotEmpty) {
        dairyMap = localDb.get('dairy_profiles', user.dairyId!);
      }
      if (dairyMap == null) {
        final allProfiles = localDb.getAll('dairy_profiles');
        if (allProfiles.isNotEmpty) dairyMap = allProfiles.first;
      }
      if (dairyMap != null) {
        _ownerUpiId = (dairyMap['ownerUpiId'] ?? '').toString();
        _dairyName = (dairyMap['dairyName'] ?? 'Smart Dairy').toString();
        _ownerPhone = (dairyMap['ownerPhone'] ?? '').toString();
      }

      final now = DateTime.now();
      final ym = DateFormatter.toYearMonthKey(now);
      final bills = localDb.query('monthly_bills', where: (b) => b['customerId'] == _customer!.id && b['yearMonth'] == ym);
      if (bills.isNotEmpty) {
        _latestBill = MonthlyBillModel.fromMap(bills.first, (bills.first['id'] ?? '').toString());
      }

      final entries = localDb.query('milk_entries', where: (e) => e['customerId'] == _customer!.id);
      if (entries.isNotEmpty) {
        final sorted = entries.map((d) => MilkEntryModel.fromMap(d, (d['id'] ?? '').toString())).toList();
        sorted.sort((a, b) => b.date.compareTo(a.date));
        _lastMilkEntry = sorted.first;
      }
    }

    final db = FirebaseFirestore.instance;

    try {
      // 2. Fetch Customer Record from cloud in background
      final custDoc = await db.collection('customers').doc(user.customerId!).get();
      if (custDoc.exists && custDoc.data() != null) {
        _customer = CustomerModel.fromMap(custDoc.data()!, custDoc.id);

        // 2. Fetch Dairy Profile info
        final dairyDoc = await db.collection('dairy_profiles').doc(_customer!.ownerId).get();
        if (dairyDoc.exists && dairyDoc.data() != null) {
          final d = dairyDoc.data()!;
          _ownerUpiId = d['ownerUpiId'] ?? '';
          _dairyName = d['dairyName'] ?? 'Smart Dairy';
          _ownerPhone = d['ownerPhone'] ?? '';
        }

        // 3. Fetch Latest Bill
        final now = DateTime.now();
        final ym = DateFormatter.toYearMonthKey(now);
        final billSnap = await db
            .collection('monthly_bills')
            .where('customerId', isEqualTo: _customer!.id)
            .where('yearMonth', isEqualTo: ym)
            .limit(1)
            .get();

        if (billSnap.docs.isNotEmpty) {
          _latestBill = MonthlyBillModel.fromMap(billSnap.docs.first.data(), billSnap.docs.first.id);
        }

        // 4. Fetch Last Milk Entry
        final entrySnap = await db
            .collection('milk_entries')
            .where('customerId', isEqualTo: _customer!.id)
            .orderBy('date', descending: true)
            .limit(1)
            .get();

        if (entrySnap.docs.isNotEmpty) {
          _lastMilkEntry = MilkEntryModel.fromMap(entrySnap.docs.first.data(), entrySnap.docs.first.id);
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  void _callOwner() async {
    if (_ownerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('डेअरी मालकाचा फोन नंबर उपलब्ध नाही'), backgroundColor: AppColors.warning),
      );
      return;
    }
    await AppLauncher.makePhoneCall(context, _ownerPhone);
  }

  void _whatsappOwner() async {
    if (_ownerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('डेअरी मालकाचा व्हॉट्सअ‍ॅप नंबर उपलब्ध नाही'), backgroundColor: AppColors.warning),
      );
      return;
    }
    await AppLauncher.openWhatsApp(
      context: context,
      phone: _ownerPhone,
      message: 'नमस्कार, मी ${_customer?.name ?? 'ग्राहक'} बोलत आहे (Smart Dairy).',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeProvider = context.watch<LocaleProvider>();

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final balanceDue = _customer?.currentBalance ?? 0.0;
    final hasDue = balanceDue > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_dairyName),
        actions: [
          TextButton.icon(
            onPressed: () => localeProvider.toggleLocale(),
            icon: const Icon(Icons.language, size: 16, color: AppColors.pureWhite),
            label: Text(
              localeProvider.isMarathi ? 'English' : 'मराठी',
              style: const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadCustomerData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome card
            Text(
              'Namaskar, ${_customer?.name ?? "Customer"}! 🙏',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome to your personal dairy account / आपले दूध खाते',
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.textLight : AppColors.textMuted),
            ),

            const SizedBox(height: 16),

            // Current Outstanding Balance & Pay Now Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasDue
                      ? [AppColors.darkGreen, AppColors.primaryGreen]
                      : [AppColors.primaryGreen, AppColors.lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkGreen.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    hasDue ? 'Total Outstanding Balance / येणे बाकी' : 'Account Balance / सर्व बिले पूर्ण',
                    style: TextStyle(color: AppColors.pureWhite.withOpacity(0.9), fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(balanceDue.abs()),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pureWhite,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (hasDue)
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_customer != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UpiPaymentScreen(
                                customer: _customer!,
                                bill: _latestBill,
                                payableAmount: balanceDue,
                                ownerUpiId: _ownerUpiId,
                                dairyName: _dairyName,
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.qr_code_rounded, size: 18),
                      label: Text(context.tr('pay_now')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldenYellow,
                        foregroundColor: AppColors.cowBlack,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle_rounded, color: AppColors.pureWhite, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'No pending dues / कोणतीही बाकी शिल्लक नाही',
                          style: TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4 Quick Metrics
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                MetricCard(
                  title: 'Daily Milk Quota',
                  value: '${_customer?.dailyTotalQuota.toStringAsFixed(1) ?? "0"} Litres',
                  subtitle: 'M: ${_customer?.morningQuota ?? 0}L | E: ${_customer?.eveningQuota ?? 0}L',
                  icon: Icons.water_drop_rounded,
                  iconColor: AppColors.darkGreen,
                ),
                MetricCard(
                  title: 'Applicable Rate',
                  value: '₹${_customer?.milkRate.toStringAsFixed(0) ?? "60"} / L',
                  subtitle: 'Pure Cow Milk',
                  icon: Icons.currency_rupee_rounded,
                  iconColor: AppColors.goldenYellow,
                ),
                MetricCard(
                  title: 'This Month Milk',
                  value: '${_latestBill?.totalMilkLitres.toStringAsFixed(1) ?? "0"} L',
                  subtitle: DateFormatter.formatMonthYear(DateTime.now()),
                  icon: Icons.calendar_month_rounded,
                  iconColor: AppColors.lightGreen,
                  onTap: () {
                    if (widget.onNavigateTab != null) widget.onNavigateTab!(1);
                  },
                ),
                MetricCard(
                  title: 'Current Bill Status',
                  value: _latestBill?.status ?? 'No Bill',
                  subtitle: CurrencyFormatter.format(_latestBill?.finalPayable ?? 0.0),
                  icon: Icons.receipt_long_rounded,
                  iconColor: _latestBill?.isPaid == true ? AppColors.success : AppColors.error,
                  onTap: () {
                    if (widget.onNavigateTab != null) widget.onNavigateTab!(2);
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Last Milk Delivery Box
            if (_lastMilkEntry != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dividerColor.withOpacity(0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Last Milk Delivery / शेवटचे दूध वाटप',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormatter.formatDate(_lastMilkEntry!.date),
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _lastMilkEntry!.isZeroMilk
                              ? 'Delivery Holiday / दूध दिले नाही'
                              : 'Morning: ${_lastMilkEntry!.morningQty}L | Evening: ${_lastMilkEntry!.eveningQty}L',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _lastMilkEntry!.isZeroMilk ? '0L' : '${_lastMilkEntry!.totalQty} Litres',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Contact Dairy Owner Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.softLightGreen.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.darkGreen,
                    child: const Icon(Icons.person_rounded, color: AppColors.pureWhite, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_dairyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Phone: $_ownerPhone', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_rounded, color: AppColors.darkGreen),
                    onPressed: _callOwner,
                    tooltip: 'Call Dairy Owner',
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_rounded, color: AppColors.lightGreen),
                    onPressed: _whatsappOwner,
                    tooltip: 'WhatsApp Dairy Owner',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

