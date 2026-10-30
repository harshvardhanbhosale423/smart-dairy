import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import 'owner_home_screen.dart';
import '../../customers/screens/customer_list_screen.dart';
import '../../milk_entry/screens/daily_milk_entry_screen.dart';
import '../../billing/screens/monthly_bills_screen.dart';
import '../../settings/screens/settings_screen.dart';

class OwnerMainNavScreen extends StatefulWidget {
  const OwnerMainNavScreen({super.key});

  @override
  State<OwnerMainNavScreen> createState() => _OwnerMainNavScreenState();
}

class _OwnerMainNavScreenState extends State<OwnerMainNavScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      OwnerHomeScreen(onNavigateTab: _onTabSelected),
      const CustomerListScreen(),
      const DailyMilkEntryScreen(),
      const MonthlyBillsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        selectedItemColor: AppColors.darkGreen,
        unselectedItemColor: AppColors.textMuted,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: context.tr('dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_alt_rounded),
            label: context.tr('customers'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.edit_calendar_rounded),
            label: context.tr('milk_entry'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_rounded),
            label: context.tr('monthly_bills'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_rounded),
            label: context.tr('settings'),
          ),
        ],
      ),
    );
  }
}

