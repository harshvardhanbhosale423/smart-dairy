import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/services/notification_service.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/phone_login_screen.dart';
import 'features/customers/providers/customer_provider.dart';
import 'features/milk_entry/providers/milk_entry_provider.dart';
import 'features/ledger/providers/ledger_provider.dart';
import 'features/billing/providers/billing_provider.dart';
import 'features/payments/providers/payment_provider.dart';
import 'features/expenses/providers/expense_provider.dart';
import 'features/reports/providers/report_provider.dart';
import 'features/owner_dashboard/providers/dashboard_provider.dart';
import 'features/owner_dashboard/screens/owner_main_nav_screen.dart';
import 'features/customer_dashboard/screens/customer_main_nav_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Firebase init note: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => MilkEntryProvider()),
        ChangeNotifierProvider(create: (_) => LedgerProvider()),
        ChangeNotifierProvider(create: (_) => BillingProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const SmartDairyApp(),
    ),
  );
}

class SmartDairyApp extends StatelessWidget {
  const SmartDairyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Smart Dairy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('mr', 'IN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.authenticating && auth.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = auth.currentUser;
    if (user != null) {
      if (user.isOwner) {
        return const OwnerMainNavScreen();
      } else {
        return const CustomerMainNavScreen();
      }
    }

    return const PhoneLoginScreen();
  }
}

