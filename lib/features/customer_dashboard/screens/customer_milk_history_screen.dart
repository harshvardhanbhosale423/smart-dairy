import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../milk_entry/models/milk_entry_model.dart';
import '../../milk_entry/repositories/milk_entry_repository.dart';

class CustomerMilkHistoryScreen extends StatelessWidget {
  const CustomerMilkHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().currentUser;
    final customerId = user?.customerId;

    if (customerId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('my_milk'))),
        body: const Center(child: Text('Customer profile not linked')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('my_milk')),
      ),
      body: StreamBuilder<List<MilkEntryModel>>(
        stream: MilkEntryRepository().getEntriesForCustomer(customerId, limit: 60),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return EmptyStateWidget(
              title: 'No Milk Deliveries Yet',
              message: 'डेअरी मालकाने दूध नोंद केल्यावर ती येथे दिसेल.\nDaily entries will show up here as soon as recorded.',
              icon: Icons.water_drop_rounded,
            );
          }

          final totalLitres = entries.fold(0.0, (s, e) => s + e.totalQty);
          final totalAmount = entries.fold(0.0, (s, e) => s + e.totalAmount);

          return Column(
            children: [
              // Summary Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isDark ? AppColors.darkCard : AppColors.softLightGreen.withOpacity(0.4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${totalLitres.toStringAsFixed(1)} Litres (${entries.length} Deliveries)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      CurrencyFormatter.format(totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkGreen),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (ctx, index) {
                    final e = entries[index];
                    return Card(
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
                          e.isZeroMilk
                              ? 'Delivery Holiday / दूध दिले नाही'
                              : 'Morning: ${e.morningQty}L | Evening: ${e.eveningQty}L @ ₹${e.ratePerLitre.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          CurrencyFormatter.format(e.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkGreen),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

