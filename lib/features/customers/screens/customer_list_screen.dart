import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../models/customer_model.dart';
import '../providers/customer_provider.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import 'add_edit_customer_screen.dart';
import 'customer_detail_screen.dart';

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

  void _showApproveDialog(UserModel user) {
    final rateController = TextEditingController(text: '60');
    final morningController = TextEditingController(text: (user.morningQuota ?? 1.0).toString());
    final eveningController = TextEditingController(text: (user.eveningQuota ?? 1.0).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_outline_rounded, color: AppColors.darkGreen),
            SizedBox(width: 8),
            Text('ग्राहक मंजूर करा (Approve)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ग्राहक: ${user.name ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('मोबाईल: ${user.phone}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
              const SizedBox(height: 14),
              TextField(
                controller: rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'दूध दर प्रति लिटर (₹/Litre)',
                  hintText: '60',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: morningController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'सकाळ (L)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: eveningController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'संध्याकाळ (L)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('रद्द करा'),
          ),
          ElevatedButton(
            onPressed: () async {
              final rate = double.tryParse(rateController.text.trim()) ?? 60.0;
              final morning = double.tryParse(morningController.text.trim()) ?? 1.0;
              final evening = double.tryParse(eveningController.text.trim()) ?? 1.0;

              final auth = context.read<AuthProvider>();
              final success = await auth.approveCustomer(
                pendingUser: user,
                milkRate: rate,
                morningQuota: morning,
                eveningQuota: evening,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'ग्राहक यशस्वीपणे मंजूर झाला!' : 'मंजुरी अयशस्वी'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkGreen,
              foregroundColor: AppColors.pureWhite,
            ),
            child: const Text('मंजूर करा'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customerProvider = context.watch<CustomerProvider>();
    final authProvider = context.watch<AuthProvider>();
    final customers = customerProvider.filteredCustomers;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('customers')),
          bottom: TabBar(
            indicatorColor: AppColors.pureWhite,
            labelColor: AppColors.pureWhite,
            unselectedLabelColor: AppColors.pureWhite.withOpacity(0.7),
            tabs: [
              Tab(text: context.tr('customers')),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('मंजुऱ्या (Approvals)'),
                    if (authProvider.pendingApprovalsCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${authProvider.pendingApprovalsCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
        body: TabBarView(
          children: [
            // Tab 1: All Customers
            _buildAllCustomersTab(customerProvider, customers, isDark),

            // Tab 2: Pending Approvals
            _buildPendingApprovalsTab(authProvider, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAllCustomersTab(
    CustomerProvider customerProvider,
    List<CustomerModel> customers,
    bool isDark,
  ) {
    return Column(
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

        // Customer Count & Summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${context.tr('all')}: ${customers.length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
              ),
              Text(
                'सक्रिय: ${customers.where((c) => c.isActive).length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkGreen),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: customerProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : customers.isEmpty
                  ? Center(
                      child: EmptyStateWidget(
                        title: context.tr('no_data'),
                        subtitle: 'नवीन ग्राहक जोडण्यासाठी खालील बटनावर दाबा',
                        icon: Icons.people_outline_rounded,
                      ),
                    )
                  : ListView.builder(
                      itemCount: customers.length,
                      padding: const EdgeInsets.only(bottom: 80),
                      itemBuilder: (ctx, i) => _buildCustomerCard(customers[i], isDark),
                    ),
        ),
      ],
    );
  }

  Widget _buildPendingApprovalsTab(AuthProvider authProvider, bool isDark) {
    final pending = authProvider.pendingApprovals;

    if (pending.isEmpty) {
      return const Center(
        child: EmptyStateWidget(
          title: 'कोणतीही प्रलंबित मंजुरी नाही',
          subtitle: 'जेव्हा ग्राहक ॲपवरून स्वतःचे खाते नोंदवतील, तेव्हा ते अर्ज येथे दिसतील.',
          icon: Icons.check_circle_outline_rounded,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: pending.length,
      itemBuilder: (ctx, i) {
        final user = pending[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.softCream,
                      child: Text(
                        user.name?.isNotEmpty == true ? user.name![0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name ?? 'ग्राहक',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'मोबाईल: ${user.phone} • युझरनेम: ${user.username}',
                            style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Text(
                  'मागणी: सकाळ ${user.morningQuota ?? 1.0}L | संध्याकाळ ${user.eveningQuota ?? 1.0}L',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (user.address != null && user.address!.isNotEmpty)
                  Text(
                    'पत्ता: ${user.address}',
                    style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final confirm = await ConfirmationDialog.show(
                            context,
                            title: 'अर्ज नाकारायचा आहे का?',
                            message: '${user.name} यांचा ग्राहक अर्ज नाकारायचा आहे का?',
                            confirmText: 'नाकारा (Reject)',
                            isDestructive: true,
                          );
                          if (confirm == true) {
                            await authProvider.rejectCustomer(user.uid);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        child: const Text('नाकारा (Reject)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showApproveDialog(user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkGreen,
                          foregroundColor: AppColors.pureWhite,
                        ),
                        child: const Text('मंजूर करा (Approve)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label, CustomerProvider provider) {
    final isSelected = provider.statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.setStatusFilter(value),
      selectedColor: AppColors.darkGreen,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.pureWhite : AppColors.darkGreen,
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
                        const SizedBox(height: 2),
                        Text(
                          '${customer.phone}${customer.username != null ? ' • @${customer.username}' : ''}',
                          style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'दैनिक दूध प्रमाण',
                        style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                      ),
                      Text(
                        'सकाळ: ${customer.morningQuota}L | संध्याकाळ: ${customer.eveningQuota}L',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isAdvance ? 'जमा रक्कम (Advance)' : 'बाकी रक्कम (Balance)',
                        style: TextStyle(
                          fontSize: 11,
                          color: hasDue ? AppColors.error : (isAdvance ? AppColors.success : AppColors.secondaryText),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(customer.currentBalance.abs()),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: hasDue ? AppColors.error : (isAdvance ? AppColors.success : AppColors.darkGreen),
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
                    icon: const Icon(Icons.call_rounded, size: 18, color: AppColors.darkGreen),
                    onPressed: () => _callCustomer(customer.phone),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_rounded, size: 18, color: AppColors.lightGreen),
                    onPressed: () => _whatsappCustomer(customer.phone),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
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
    String text;

    switch (status) {
      case 'active':
        bg = AppColors.softLightGreen;
        fg = AppColors.darkGreen;
        text = context.tr('status_active');
        break;
      case 'paused':
        bg = AppColors.goldLight;
        fg = AppColors.textDark;
        text = context.tr('status_paused');
        break;
      default:
        bg = AppColors.dividerColor;
        fg = AppColors.secondaryText;
        text = context.tr('status_inactive');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
