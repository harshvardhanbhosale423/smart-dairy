import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import 'dairy_profile_screen.dart';
import 'upi_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerColor.withOpacity(0.6)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.softLightGreen,
                  child: const Icon(Icons.agriculture_rounded, color: AppColors.darkGreen, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Dairy Owner',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user?.phone ?? '',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.softLightGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user?.role.toUpperCase() ?? 'OWNER',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Business Settings Group
          _sectionTitle('Dairy Business Settings / डेअरी माहिती'),
          _settingsTile(
            icon: Icons.store_rounded,
            title: 'Dairy Profile & Cows / गोठा माहिती',
            subtitle: 'Name, Cow Count, Default Rate',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DairyProfileScreen()));
            },
          ),
          _settingsTile(
            icon: Icons.qr_code_rounded,
            title: 'UPI Payment Settings / यूपीआय माहिती',
            subtitle: 'Configure UPI ID & QR Code',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UpiSettingsScreen()));
            },
          ),

          const SizedBox(height: 20),

          // App Preferences Group
          _sectionTitle('Preferences / ॲप सेटिंग्ज'),
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

          const SizedBox(height: 20),

          // Security & Account
          _sectionTitle('Security & Logout'),
          _settingsTile(
            icon: Icons.logout_rounded,
            title: context.tr('logout'),
            subtitle: 'Sign out from this device',
            isDestructive: true,
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

          const SizedBox(height: 30),

          Center(
            child: Text(
              'Smart Dairy v1.0.0 (Secure Build)\nDesigned for Small Cow Dairy Management',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.darkGreen),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDestructive ? AppColors.error : null,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: onTap,
      ),
    );
  }
}

