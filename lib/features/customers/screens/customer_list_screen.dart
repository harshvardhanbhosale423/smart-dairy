import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../models/customer_model.dart';
import '../providers/customer_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'add_edit_customer_screen.dart';
import 'customer_detail_screen.dart';
import '../../ledger/screens/customer_ledger_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<CustomerProvider>().listenToCustomers(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _callCustomer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _whatsappCustomer(String phone) async {
    var cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length == 10) cleanPhone = '91$cleanPhone';
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customerProvider = context.watch<CustomerProvider>();
    final customers = customerProvider.filteredCustomers;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('customers')),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: context.tr('add_customer'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditCustomerScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditCustomerScreen()),
          );
        },
        backgroundColor: AppColors.darkGreen,
        foregroundColor: AppColors.pureWhite,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.tr('add_customer')),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
            child: Column(
              children: [
                // Search TextField
                TextField(
                  controller: _searchController,
                  onChanged: customerProvider.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: '${context.tr('search')} (Name, Phone, Address)',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              customerProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', context.tr('all'), customerProvider),
                      const SizedBox(width: 8),
                      _buildFilterChip('active', context.tr('status_active'), customerProvider),
                      const SizedBox(width: 8),
                      _buildFilterChip('paused', context.tr('status_paused'), customerProvider),
                      const SizedBox(width: 8),
                      _buildFilterChip('inactive', context.tr('status_inactive'), customerProvider),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Total counts bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkCard : AppColors.surfaceLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${customers.length} ${context.tr('customers')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'Total Due: ${CurrencyFormatter.format(customerProvider.totalOutstandingDues)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.error),
                ),
              ],
            ),
          ),

          // Customer List
          Expanded(
            child: customerProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : customers.isEmpty
                    ? EmptyStateWidget(
                        title: context.tr('no_data'),
                        message: 'No customers found matching your filter.\nनवीन ग्राहक जोडण्यासाठी खालील बटनावर टॅप करा.',
                        buttonText: context.tr('add_customer'),
                        onButtonPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddEditCustomerScreen()),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80, top: 8),
                        itemCount: customers.length,
                        itemBuilder: (ctx, index) {
                          final customer = customers[index];
                          return _buildCustomerCard(customer, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, CustomerProvider provider) {
    final isSelected = provider.statusFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) provider.setStatusFilter(filterKey);
      },
      selectedColor: AppColors.softLightGreen,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.darkGreen : AppColors.textMuted,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer, bool isDark) {
    final hasDue = customer.currentBalance > 0;
    final isAdvance = customer.currentBalance < 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(customer: customer),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: customer.isActive
                        ? AppColors.softLightGreen
                        : (customer.isPaused ? AppColors.goldLight : AppColors.dividerColor),
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: customer.isActive ? AppColors.darkGreen : AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                customer.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _statusBadge(customer.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${customer.phone} ${customer.address.isNotEmpty ? "• " + customer.address : ""}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Daily Quota', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      Text(
                        '${customer.dailyTotalQuota.toStringAsFixed(1)} L/day (₹${customer.milkRate.toStringAsFixed(0)}/L)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isAdvance ? 'Advance Paid' : 'Outstanding Balance',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                      Text(
                        CurrencyFormatter.format(customer.currentBalance.abs()),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: hasDue ? AppColors.error : (isAdvance ? AppColors.success : AppColors.textDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.call_rounded, color: AppColors.darkGreen, size: 20),
                    onPressed: () => _callCustomer(customer.phone),
                    tooltip: 'Call Customer',
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_rounded, color: AppColors.lightGreen, size: 20),
                    onPressed: () => _whatsappCustomer(customer.phone),
                    tooltip: 'WhatsApp',
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu_book_rounded, color: AppColors.info, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerLedgerScreen(customer: customer),
                        ),
                      );
                    },
                    tooltip: 'View Khata Ledger',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'active':
        bg = AppColors.softLightGreen;
        fg = AppColors.darkGreen;
        label = 'Active';
        break;
      case 'paused':
        bg = AppColors.goldLight;
        fg = AppColors.warning;
        label = 'Paused';
        break;
      default:
        bg = AppColors.dividerColor;
        fg = AppColors.textMuted;
        label = 'Inactive';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

