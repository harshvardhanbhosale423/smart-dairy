import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/widgets/cow_logo.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';
import 'owner_register_screen.dart';
import 'customer_register_screen.dart';
import '../../owner_dashboard/screens/owner_main_nav_screen.dart';
import '../../customer_dashboard/screens/customer_main_nav_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final id = _identifierController.text.trim();
    final pass = _passwordController.text.trim();
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(id, pass);
    if (!mounted) return;

    if (success) {
      final user = authProvider.currentUser;
      if (user != null) {
        if (user.isOwner) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const OwnerMainNavScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const CustomerMainNavScreen()),
            (route) => false,
          );
        }
      }
    } else {
      final errorMsg = authProvider.errorMessage ?? 'लॉगिन अयशस्वी झाले';
      _showErrorDialog(errorMsg);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.info_outline_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('सूचना (Alert)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('समजले (OK)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeProvider = context.watch<LocaleProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Language Switcher
          TextButton.icon(
            onPressed: () => localeProvider.toggleLocale(),
            icon: const Icon(Icons.language, size: 18, color: AppColors.darkGreen),
            label: Text(
              localeProvider.isMarathi ? 'English' : 'मराठी',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                const CowLogoWidget(size: 88),
                const SizedBox(height: 16),
                Text(
                  context.tr('app_name'),
                  style: AppTypography.headingLarge.copyWith(
                    color: isDark ? AppColors.pureWhite : AppColors.darkGreen,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('app_tagline'),
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.lightCream : AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 28),

                // Card with Login Form
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('login_btn'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        localeProvider.isMarathi
                            ? 'डेअरी मालक किंवा ग्राहक म्हणून लॉगिन करा'
                            : 'Log in as Dairy Owner or Customer',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Username or Mobile Field
                      CustomTextField(
                        label: context.tr('username_or_phone'),
                        hint: context.tr('enter_username'),
                        controller: _identifierController,
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.darkGreen),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'कृपया युझरनेम किंवा मोबाईल नंबर टाका';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      CustomTextField(
                        label: context.tr('password'),
                        hint: context.tr('enter_password'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.darkGreen),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.secondaryText,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'कृपया पासवर्ड टाका';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      CustomButton(
                        text: context.tr('login_btn'),
                        icon: Icons.login_rounded,
                        isLoading: authProvider.status == AuthStatus.authenticating,
                        onPressed: _onLogin,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Register options
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        localeProvider.isMarathi ? 'नवीन खाते नोंदणी' : 'Create New Account',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : AppColors.secondaryText,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // Owner Register Option
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OwnerRegisterScreen()),
                    );
                  },
                  icon: const Icon(Icons.business_center_outlined, color: AppColors.darkGreen),
                  label: Text(
                    context.tr('new_owner_register'),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.darkGreen, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Customer Register Option
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerRegisterScreen()),
                    );
                  },
                  icon: const Icon(Icons.person_add_alt_1_outlined, color: AppColors.primaryGreen),
                  label: Text(
                    context.tr('customer_self_register'),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  localeProvider.isMarathi
                      ? 'टीप: ग्राहकांना डेअरी मालक स्वतः देखील युझरनेम व पासवर्ड देऊ शकतात.'
                      : 'Note: Dairy owners can also assign login credentials directly to customers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
