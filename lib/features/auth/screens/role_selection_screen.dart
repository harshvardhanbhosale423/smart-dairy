import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import 'owner_register_screen.dart';
import '../../customer_dashboard/screens/customer_main_nav_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  final String phoneNumber;

  const RoleSelectionScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('select_role')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                context.tr('select_role'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose how you will be using Smart Dairy\nआपण स्मार्ट डेअरीचा वापर कसा करणार आहात ते निवडा',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // Option 1: Dairy Owner
              _buildRoleCard(
                context: context,
                isDark: isDark,
                title: context.tr('owner'),
                subtitle: context.tr('owner_desc'),
                icon: Icons.agriculture_rounded,
                badgeColor: AppColors.darkGreen,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OwnerRegisterScreen(phoneNumber: phoneNumber),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Option 2: Milk Customer
              _buildRoleCard(
                context: context,
                isDark: isDark,
                title: context.tr('customer'),
                subtitle: context.tr('customer_desc'),
                icon: Icons.local_drink_rounded,
                badgeColor: AppColors.lightGreen,
                onTap: () {
                  _showCustomerApprovalDialog(context);
                },
              ),

              const Spacer(),

              // Helper notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.goldLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.goldenYellow.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.goldenYellow, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'डेअरी मालक सर्व हिशोब व्यवस्थापित करू शकतात. ग्राहक फक्त त्यांचे स्वतःचे दूध रेकॉर्ड व बिल पाहू शकतात.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.pureWhite : AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: badgeColor.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: badgeColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: badgeColor),
          ],
        ),
      ),
    );
  }

  void _showCustomerApprovalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Customer Access / ग्राहक नोंदणी'),
        content: const Text(
          'स्मार्ट डेअरीमध्ये ग्राहकांचे खाते डेअरी मालकाद्वारे नोंदवले जाते.\n\nआपला मोबाईल नंबर आपल्या डेअरी मालकाकडे नोंदवला असल्याची खात्री करा. नोंदणी झाल्यावर आपण त्वरित आपले दूध व बिले पाहू शकता.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen),
            child: const Text('समजले (OK)'),
          ),
        ],
      ),
    );
  }
}

