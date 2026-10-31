import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerColor.withOpacity(0.6)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.softLightGreen,
                  child: const Icon(Icons.person_rounded, color: AppColors.darkGreen, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Customer',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.phone ?? '',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.softLightGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'VERIFIED CUSTOMER',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Preferences
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.language_rounded, color: AppColors.darkGreen),
              title: const Text('Language / भाषा', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(localeProvider.isMarathi ? 'मराठी (सक्रिय)' : 'English (Active)'),
              trailing: Switch(
                value: localeProvider.isMarathi,
                activeColor: AppColors.darkGreen,
                onChanged: (_) => localeProvider.toggleLocale(),
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.dark_mode_rounded, color: AppColors.darkGreen),
              title: const Text('Dark Mode / डार्क मोड', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(themeProvider.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled'),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                activeColor: AppColors.darkGreen,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Logout
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: Text(context.tr('logout'), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              onTap: () async {
                final confirm = await ConfirmationDialog.show(
                  context,
                  title: context.tr('logout'),
                  message: 'Are you sure you want to log out from Smart Dairy?\nआपण बाहेर पडू इच्छिता का?',
                  confirmText: context.tr('logout'),
                  isDestructive: true,
                );
                if (confirm == true) {
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              'Smart Dairy • Consumer Portal\nData Isolated & Secured',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

