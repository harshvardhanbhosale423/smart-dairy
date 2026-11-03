import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../customers/models/customer_model.dart';
import '../../customers/providers/customer_provider.dart';
import '../models/month_bill_summary.dart';
import '../repositories/billing_repository.dart';
import 'bill_detail_screen.dart';

class CreateCustomBillScreen extends StatefulWidget {
  final CustomerModel? preSelectedCustomer;

  const CreateCustomBillScreen({super.key, this.preSelectedCustomer});

  @override
  State<CreateCustomBillScreen> createState() => _CreateCustomBillScreenState();
}

class _CreateCustomBillScreenState extends State<CreateCustomBillScreen> {
  CustomerModel? _selectedCustomer;
  List<MonthBillSummary> _summaries = [];
  final Set<String> _selectedYearMonths = {};
  bool _isLoading = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedCustomer != null) {
      _selectedCustomer = widget.preSelectedCustomer;
      _loadCustomerBreakdown(widget.preSelectedCustomer!.id);
    }
  }

  Future<void> _loadCustomerBreakdown(String customerId) async {
    setState(() {
      _isLoading = true;
      _summaries = [];
      _selectedYearMonths.clear();
    });

    final breakdown = await BillingRepository().getCustomerMonthlyBreakdown(customerId);

    setState(() {
      _summaries = breakdown;
      // By default, select all unbilled months, or the first month if all billed
      for (final s in _summaries) {
        if (!s.isAlreadyBilled) {
          _selectedYearMonths.add(s.yearMonth);
        }
      }
      if (_selectedYearMonths.isEmpty && _summaries.isNotEmpty) {
        _selectedYearMonths.add(_summaries.first.yearMonth);
      }
      _isLoading = false;
    });
  }

  double get _totalLitres {
    double sum = 0.0;
    for (final s in _summaries) {
      if (_selectedYearMonths.contains(s.yearMonth)) {
        sum += s.totalLitres;
      }
    }
    return sum;
  }

  double get _totalMilkCharges {
    double sum = 0.0;
    for (final s in _summaries) {
      if (_selectedYearMonths.contains(s.yearMonth)) {
        sum += s.milkCharges;
      }
    }
    return sum;
  }

  double get _totalPaid {
    double sum = 0.0;
    for (final s in _summaries) {
      if (_selectedYearMonths.contains(s.yearMonth)) {
        sum += s.paymentsReceived;
      }
    }
    return sum;
  }

  double get _finalPayable => _totalMilkCharges - _totalPaid;

  void _onGenerateBill() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया प्रथम ग्राहक निवडा!'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_selectedYearMonths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया किमान एक महिना निवडा!'), backgroundColor: AppColors.warning),
      );
      return;
    }

    final selectedList = _summaries.where((s) => _selectedYearMonths.contains(s.yearMonth)).toList();

    setState(() => _isGenerating = true);

    try {
      final bill = await BillingRepository().generateMultiMonthBill(
        customer: _selectedCustomer!,
        selectedMonths: selectedList,
      );

      setState(() => _isGenerating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('मासिक बिल यशस्वीरित्या तयार झाले! 🧾'),
            backgroundColor: AppColors.success,
          ),
        );

        // Replace with BillDetailScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BillDetailScreen(bill: bill)),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('बिल तयार करताना त्रुटी: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allCustomers = context.watch<CustomerProvider>().allCustomers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('महिने निवडून बिल बनवा'),
      ),
      body: Column(
        children: [
          // 1. Customer Selector Card
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppColors.darkCard : AppColors.softLightGreen.withOpacity(0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ग्राहक निवडा (Select Customer):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CustomerModel>(
                  value: _selectedCustomer != null
                      ? allCustomers.firstWhere((c) => c.id == _selectedCustomer!.id, orElse: () => _selectedCustomer!)
                      : null,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : AppColors.pureWhite,
                    prefixIcon: const Icon(Icons.person_rounded, color: AppColors.darkGreen),
                  ),
                  hint: const Text('ग्राहक निवडा...'),
                  items: allCustomers.map((c) {
                    return DropdownMenuItem<CustomerModel>(
                      value: c,
                      child: Text(
                        '${c.name} (${c.phone})',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (cust) {
                    if (cust != null) {
                      setState(() => _selectedCustomer = cust);
                      _loadCustomerBreakdown(cust.id);
                    }
                  },
                ),
              ],
            ),
          ),

          // 2. Month Breakdown List
          Expanded(
            child: _selectedCustomer == null
                ? const Center(
                    child: Text(
                      'बिल बनवण्यासाठी वरील यादीतून ग्राहक निवडा.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                    ),
                  )
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _summaries.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.inbox_rounded, size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  Text(
                                    'या ग्राहकाची कोणतीही दूध नोंद उपलब्ध नाही.',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'कृपया प्रथम दैनिक दूध नोंद करा, मग येथे मासिक बिल तयार होईल.',
                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _summaries.length,
                            itemBuilder: (ctx, index) {
                              final s = _summaries[index];
                              final isSelected = _selectedYearMonths.contains(s.yearMonth);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.darkGreen : AppColors.dividerColor.withOpacity(0.4),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedYearMonths.remove(s.yearMonth);
                                      } else {
                                        _selectedYearMonths.add(s.yearMonth);
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Checkbox(
                                          value: isSelected,
                                          activeColor: AppColors.darkGreen,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedYearMonths.add(s.yearMonth);
                                              } else {
                                                _selectedYearMonths.remove(s.yearMonth);
                                              }
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    s.monthNameMr,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  if (s.isAlreadyBilled)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue.shade50,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        'आधी बिल बनवले आहे',
                                                        style: TextStyle(fontSize: 10, color: Colors.blue.shade800),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'दूध: ${s.totalLitres.toStringAsFixed(1)}L @ ₹${s.appliedRate.toStringAsFixed(0)}/L',
                                                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'रक्कम: ${CurrencyFormatter.format(s.milkCharges)}',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                  ),
                                                  Text(
                                                    'बाकी: ${CurrencyFormatter.format(s.netBalance)}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.darkGreen,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),

          // 3. Live Total & Generate Bill Button (Bottom Sheet Bar)
          if (_selectedCustomer != null && _summaries.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.pureWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'निवडलेले महिने: ${_selectedYearMonths.length} (${_totalLitres.toStringAsFixed(1)} L)',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                        Text(
                          'एकूण: ${CurrencyFormatter.format(_finalPayable)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _selectedYearMonths.isEmpty || _isGenerating ? null : _onGenerateBill,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.receipt_rounded, size: 20),
                        label: Text(
                          _isGenerating
                              ? 'बिल तयार होत आहे...'
                              : 'निवडलेल्या ${_selectedYearMonths.length} महिन्यांचे बिल तयार करा',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
