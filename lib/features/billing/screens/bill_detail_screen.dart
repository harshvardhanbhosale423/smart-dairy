import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/monthly_bill_model.dart';
import '../../customers/models/customer_model.dart';
import '../../customers/providers/customer_provider.dart';
import '../../milk_entry/repositories/milk_entry_repository.dart';
import '../../milk_entry/models/milk_entry_model.dart';
import '../../settings/models/dairy_settings_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../payments/screens/record_payment_screen.dart';
import '../../../core/services/local_database_service.dart';
import '../../../core/services/app_launcher.dart';

class BillDetailScreen extends StatefulWidget {
  final MonthlyBillModel bill;

  const BillDetailScreen({super.key, required this.bill});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  List<MilkEntryModel> _monthEntries = [];
  bool _isLoadingEntries = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    List<MilkEntryModel> entries;
    if (widget.bill.month > 0) {
      entries = await MilkEntryRepository().getCustomerEntriesForMonth(
        customerId: widget.bill.customerId,
        year: widget.bill.year,
        month: widget.bill.month,
      );
    } else {
      // Multi-month bill: fetch customer entries
      entries = await MilkEntryRepository().getEntriesForCustomer(widget.bill.customerId, limit: 500).first;
    }
    if (mounted) {
      setState(() {
        _monthEntries = entries;
        _isLoadingEntries = false;
      });
    }
  }

  void _onShareWhatsApp({bool isMarathi = true}) async {
    final customer = context.read<CustomerProvider>().allCustomers.firstWhere(
      (c) => c.id == widget.bill.customerId,
      orElse: () => CustomerModel(
        id: widget.bill.customerId,
        ownerId: widget.bill.ownerId,
        name: widget.bill.customerName,
        phone: widget.bill.customerPhone,
        joiningDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final user = context.read<AuthProvider>().currentUser;
    final localDb = LocalDatabaseService();
    final profile = localDb.get('dairy_profiles', widget.bill.ownerId) ??
        (user != null ? localDb.get('dairy_profiles', user.uid) : null);
    final dairyName = (profile?['dairyName'] ?? user?.name ?? 'Smart Dairy').toString();
    final ownerUpi = (profile?['ownerUpiId'] ?? '').toString();

    final message = isMarathi
        ? WhatsAppService.formatMarathiBillMessage(
            customer: customer,
            bill: widget.bill,
            dairyName: dairyName,
            ownerUpiId: ownerUpi,
          )
        : WhatsAppService.formatEnglishBillMessage(
            customer: customer,
            bill: widget.bill,
            dairyName: dairyName,
            ownerUpiId: ownerUpi,
          );

    await AppLauncher.openWhatsApp(
      context: context,
      phone: widget.bill.customerPhone,
      message: message,
    );
  }

  void _onDownloadPdf() async {
    final customer = context.read<CustomerProvider>().allCustomers.firstWhere(
      (c) => c.id == widget.bill.customerId,
      orElse: () => CustomerModel(
        id: widget.bill.customerId,
        ownerId: widget.bill.ownerId,
        name: widget.bill.customerName,
        phone: widget.bill.customerPhone,
        joiningDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final user = context.read<AuthProvider>().currentUser;
    final isMarathi = context.read<LocaleProvider>().isMarathi;
    final localDb = LocalDatabaseService();
    final profile = localDb.get('dairy_profiles', widget.bill.ownerId) ??
        (user != null ? localDb.get('dairy_profiles', user.uid) : null);

    final dairy = DairySettingsModel(
      id: widget.bill.ownerId,
      ownerId: widget.bill.ownerId,
      dairyName: (profile?['dairyName'] ?? user?.name ?? 'Smart Dairy Farm').toString(),
      ownerName: (profile?['ownerName'] ?? user?.name ?? 'Dairy Owner').toString(),
      ownerPhone: (profile?['ownerPhone'] ?? user?.phone ?? '').toString(),
      ownerUpiId: (profile?['ownerUpiId'] ?? '').toString(),
      updatedAt: DateTime.now(),
    );

    try {
      final pdfFile = await PdfService.generateMonthlyBillPdf(
        customer: customer,
        bill: widget.bill,
        dairy: dairy,
        monthEntries: _monthEntries,
        isMarathi: isMarathi,
      );

      await Printing.layoutPdf(
        onLayout: (_) => pdfFile.readAsBytes(),
        name: 'Bill_${customer.name}_${widget.bill.yearMonth}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeProvider = context.watch<LocaleProvider>();
    final isMarathi = localeProvider.isMarathi;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bill.customerName} - Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: context.tr('download_pdf'),
            onPressed: _onDownloadPdf,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: context.tr('share_whatsapp'),
            onPressed: () => _onShareWhatsApp(isMarathi: isMarathi),
          ),
        ],
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
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: context.tr('share_whatsapp'),
                icon: Icons.chat_rounded,
                backgroundColor: AppColors.lightGreen,
                onPressed: () => _onShareWhatsApp(isMarathi: isMarathi),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: context.tr('record_payment'),
                icon: Icons.payments_rounded,
                onPressed: () {
                  final customer = context.read<CustomerProvider>().allCustomers.firstWhere(
                    (c) => c.id == widget.bill.customerId,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecordPaymentScreen(
                        preSelectedCustomer: customer,
                        preSelectedBill: widget.bill,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bill Header Card
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.bill.customerName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.bill.customerPhone,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: widget.bill.isPaid
                              ? AppColors.softLightGreen
                              : (widget.bill.isPartial ? AppColors.goldLight : AppColors.error.withOpacity(0.12)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.bill.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: widget.bill.isPaid
                                ? AppColors.success
                                : (widget.bill.isPartial ? AppColors.warning : AppColors.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Billing Month: ${isMarathi ? widget.bill.monthNameMr : widget.bill.monthNameEn}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Bill Date: ${DateFormatter.formatShortDate(widget.bill.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Billing Formula Calculation Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.softLightGreen.withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Billing Formula Breakdown / हिशोब तपशील',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                  ),
                  const SizedBox(height: 12),
                  _calcRow('Total Milk Delivered:', '${widget.bill.totalMilkLitres.toStringAsFixed(1)} Litres'),
                  _calcRow('Applied Rate:', '₹${widget.bill.appliedRate.toStringAsFixed(0)} / Litre'),
                  const Divider(height: 16),
                  _calcRow('Current Month Milk Charges (+):', CurrencyFormatter.format(widget.bill.currentMonthMilkCharges)),
                  _calcRow('Previous Balance / मागील येणे बाकी (+):', CurrencyFormatter.format(widget.bill.previousBalance)),
                  _calcRow('Payments Deducted / जमा रक्कम (-):', CurrencyFormatter.format(widget.bill.paidAmount), color: AppColors.success),
                  const Divider(height: 16, thickness: 1.5),
                  _calcRow(
                    'Final Payable / एकूण भरावयाची बाकी:',
                    CurrencyFormatter.format(widget.bill.finalPayable),
                    isBold: true,
                    color: widget.bill.isPaid ? AppColors.success : AppColors.error,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Daily Milk Breakdown Table
            const Text(
              'Daily Milk Entries / दैनंदिन दूध नोंद तपशील',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (_isLoadingEntries)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_monthEntries.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('No daily entries recorded for this month', style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            else
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Morn (L)')),
                      DataColumn(label: Text('Eve (L)')),
                      DataColumn(label: Text('Total (L)')),
                      DataColumn(label: Text('Amount')),
                    ],
                    rows: _monthEntries.map((e) => DataRow(
                      cells: [
                        DataCell(Text(DateFormatter.formatShortDate(e.date))),
                        DataCell(Text(e.morningQty.toStringAsFixed(1))),
                        DataCell(Text(e.eveningQty.toStringAsFixed(1))),
                        DataCell(Text(e.totalQty.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(CurrencyFormatter.format(e.totalAmount))),
                      ],
                    )).toList(),
                  ),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _calcRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

