import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/cow_logo.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';
import 'otp_verification_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onGetOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.sendOtp(phone);
    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => OtpVerificationScreen(phoneNumber: phone),
        ),
      );
    } else if (authProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
          // Language Switch Button
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const CowLogoWidget(size: 96),
                const SizedBox(height: 20),
                Text(
                  context.tr('app_name'),
                  style: AppTypography.headingLarge.copyWith(
                    color: isDark ? AppColors.pureWhite : AppColors.darkGreen,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('app_tagline'),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textLight : AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Card Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.dividerColor.withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkGreen.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('login_title'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('login_subtitle'),
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 24),

                      CustomTextField(
                        controller: _phoneController,
                        label: context.tr('phone_number'),
                        hint: '9822XXXXXX',
                        prefixIcon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        validator: Validators.validatePhone,
                      ),

                      const SizedBox(height: 24),

                      CustomButton(
                        text: context.tr('get_otp'),
                        icon: Icons.arrow_forward_rounded,
                        isLoading: authProvider.status == AuthStatus.authenticating,
                        onPressed: _onGetOtp,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Bottom security assurance badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.security_rounded, size: 16, color: AppColors.darkGreen),
                    const SizedBox(width: 6),
                    Text(
                      '100% Secure • Encrypted Mobile OTP Verification',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textLight : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

