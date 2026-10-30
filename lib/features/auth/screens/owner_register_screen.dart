import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';
import '../../owner_dashboard/screens/owner_main_nav_screen.dart';

class OwnerRegisterScreen extends StatefulWidget {
  final String phoneNumber;

  const OwnerRegisterScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OwnerRegisterScreen> createState() => _OwnerRegisterScreenState();
}

class _OwnerRegisterScreenState extends State<OwnerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerNameController = TextEditingController();
  final _dairyNameController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _cowCountController = TextEditingController(text: '5');
  final _rateController = TextEditingController(text: '60');
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _ownerNameController.dispose();
    _dairyNameController.dispose();
    _upiIdController.dispose();
    _cowCountController.dispose();
    _rateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.registerOwner(
      ownerName: _ownerNameController.text.trim(),
      dairyName: _dairyNameController.text.trim(),
      upiId: _upiIdController.text.trim(),
      address: _addressController.text.trim(),
      cowCount: int.tryParse(_cowCountController.text.trim()) ?? 5,
      defaultMilkRate: double.tryParse(_rateController.text.trim()) ?? 60.0,
    );

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OwnerMainNavScreen()),
        (route) => false,
      );
    } else if (auth.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
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
        title: Text(context.tr('register_owner')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.softLightGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppColors.darkGreen, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Setup Dairy Business Profile',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkGreen),
                            ),
                            Text(
                              'Phone: +91 ${widget.phoneNumber}',
                              style: const TextStyle(fontSize: 12, color: AppColors.darkGreen),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                CustomTextField(
                  controller: _dairyNameController,
                  label: '${context.tr('dairy_name')} *',
                  hint: 'उदा. माऊली डेअरी फार्म / Mauli Dairy',
                  prefixIcon: Icons.store_rounded,
                  validator: (v) => Validators.validateRequired(v, context.tr('dairy_name')),
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: _ownerNameController,
                  label: '${context.tr('name')} *',
                  hint: 'उदा. राहुल रमेश पाटील',
                  prefixIcon: Icons.person_rounded,
                  validator: (v) => Validators.validateRequired(v, context.tr('name')),
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: _upiIdController,
                  label: '${context.tr('upi_id')} *',
                  hint: 'उदा. 9822000000@ybl किंवा rahul@oksbi',
                  prefixIcon: Icons.qr_code_rounded,
                  validator: Validators.validateUpiId,
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _cowCountController,
                        label: context.tr('cows_owned'),
                        hint: '5',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.pets_rounded,
                        validator: (v) => Validators.validateNumber(v, context.tr('cows_owned')),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _rateController,
                        label: '${context.tr('milk_rate')} *',
                        hint: '60',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.currency_rupee_rounded,
                        validator: (v) => Validators.validateNumber(v, context.tr('milk_rate'), allowZero: false),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: _addressController,
                  label: context.tr('address'),
                  hint: 'गाव, तालुका, जिल्हा',
                  prefixIcon: Icons.location_on_rounded,
                  maxLines: 2,
                ),

                const SizedBox(height: 28),

                CustomButton(
                  text: context.tr('save'),
                  icon: Icons.check_circle_rounded,
                  isLoading: auth.status == AuthStatus.authenticating,
                  onPressed: _onRegister,
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

