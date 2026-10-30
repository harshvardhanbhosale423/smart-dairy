import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';
import 'role_selection_screen.dart';
import '../../owner_dashboard/screens/owner_main_nav_screen.dart';
import '../../customer_dashboard/screens/customer_main_nav_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _onVerify() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _otpController.text.trim();
    final auth = context.read<AuthProvider>();

    final success = await auth.verifyOtp(code);
    if (!mounted) return;

    if (success) {
      final user = auth.currentUser;
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
      } else {
        // User is authenticated in Firebase Auth, but does not have a Firestore user profile yet
        // Check if pre-registered by owner as a customer
        final customerMatch = await auth.checkCustomerPreRegistered(widget.phoneNumber);
        if (customerMatch != null && mounted) {
          // Auto-link customer profile
          await auth.linkCustomer(
            customerId: customerMatch['id'],
            customerName: customerMatch['name'] ?? 'Customer',
          );
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const CustomerMainNavScreen()),
              (route) => false,
            );
          }
        } else if (mounted) {
          // New user: go to Role Selection
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RoleSelectionScreen(phoneNumber: widget.phoneNumber),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Invalid OTP code'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('verify_otp')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: AppColors.softLightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    size: 40,
                    color: AppColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr('verify_otp'),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${context.tr('enter_otp_sent_to')} +91 ${widget.phoneNumber}',
                  style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.dividerColor.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _otpController,
                        label: 'Enter 6-Digit OTP / ६ अंकी ओटीपी',
                        hint: '123456',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.lock_outline_rounded,
                        validator: (val) {
                          if (val == null || val.trim().length != 6) {
                            return 'Enter 6-digit OTP / ६ अंकी ओटीपी टाका';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: context.tr('verify_otp'),
                        icon: Icons.check_circle_rounded,
                        isLoading: auth.status == AuthStatus.authenticating,
                        onPressed: _onVerify,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Resend OTP countdown
                if (auth.canResendOtp)
                  TextButton.icon(
                    onPressed: () => auth.sendOtp(widget.phoneNumber),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(
                      context.tr('resend_otp'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Text(
                    '${context.tr('resend_otp_in')} ${auth.resendTimer}s',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

