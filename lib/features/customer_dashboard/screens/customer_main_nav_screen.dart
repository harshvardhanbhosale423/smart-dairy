import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import 'customer_home_screen.dart';
import 'customer_milk_history_screen.dart';
import 'customer_bills_screen.dart';
import 'customer_payments_screen.dart';
import 'customer_profile_screen.dart';

class CustomerMainNavScreen extends StatefulWidget {
  const CustomerMainNavScreen({super.key});

  @override
  State<CustomerMainNavScreen> createState() => _CustomerMainNavScreenState();
}

class _CustomerMainNavScreenState extends State<CustomerMainNavScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      CustomerHomeScreen(onNavigateTab: _onTabSelected),
      const CustomerMilkHistoryScreen(),
      const CustomerBillsScreen(),
      const CustomerPaymentsScreen(),
      const CustomerProfileScreen(),
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
            icon: const Icon(Icons.water_drop_rounded),
            label: context.tr('my_milk'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_rounded),
            label: context.tr('my_bills'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.payments_rounded),
            label: context.tr('payments'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: context.tr('profile'),
          ),
        ],
      ),
    );
  }
}

