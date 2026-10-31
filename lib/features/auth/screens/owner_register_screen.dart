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
  const OwnerRegisterScreen({super.key});

  @override
  State<OwnerRegisterScreen> createState() => _OwnerRegisterScreenState();
}

class _OwnerRegisterScreenState extends State<OwnerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerNameController = TextEditingController();
  final _dairyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _cowCountController = TextEditingController(text: '5');
  final _rateController = TextEditingController(text: '60');
  final _addressController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _ownerNameController.dispose();
    _dairyNameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
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
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      phone: _phoneController.text.trim(),
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
                    children: const [
                      Icon(Icons.business_center_rounded, color: AppColors.darkGreen, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'डेअरी मालक खाते तयार करा\n(Create Dairy Owner Account)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Owner Name
                CustomTextField(
                  label: 'मालकाचे नाव (Owner Name)',
                  hint: 'उदा. हर्षवर्धन भोसले',
                  controller: _ownerNameController,
                  prefixIcon: const Icon(Icons.person_rounded, color: AppColors.darkGreen),
                  validator: Validators.required,
                ),
                const SizedBox(height: 14),

                // Dairy Name
                CustomTextField(
                  label: context.tr('dairy_name'),
                  hint: 'उदा. भोसले दूध डेअरी',
                  controller: _dairyNameController,
                  prefixIcon: const Icon(Icons.store_rounded, color: AppColors.darkGreen),
                  validator: Validators.required,
                ),
                const SizedBox(height: 14),

                // Phone
                CustomTextField(
                  label: context.tr('phone_number'),
                  hint: '१० अंकी मोबाईल नंबर',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.darkGreen),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 14),

                // Username
                CustomTextField(
                  label: 'लॉगिन युझरनेम (Username)',
                  hint: 'उदा. harsh_dairy किंवा मोबाईल नंबर',
                  controller: _usernameController,
                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.darkGreen),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'युझरनेम आवश्यक आहे';
                    if (val.trim().length < 3) return 'किमान ३ अक्षरे असावी';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password
                CustomTextField(
                  label: 'लॉगिन पासवर्ड (Password)',
                  hint: 'किमान ४ ते ६ अक्षरांचा पासवर्ड',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.darkGreen),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.secondaryText,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'पासवर्ड आवश्यक आहे';
                    if (val.trim().length < 4) return 'पासवर्ड किमान ४ अक्षरांचा असावा';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // UPI ID
                CustomTextField(
                  label: context.tr('upi_id'),
                  hint: 'उदा. 9822000000@oksbi / name@paytm',
                  controller: _upiIdController,
                  prefixIcon: const Icon(Icons.qr_code_rounded, color: AppColors.darkGreen),
                  validator: Validators.upiId,
                ),
                const SizedBox(height: 14),

                // Address
                CustomTextField(
                  label: context.tr('address'),
                  hint: 'डेअरीचा पत्ता / गाव',
                  controller: _addressController,
                  maxLines: 2,
                  prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.darkGreen),
                  validator: Validators.required,
                ),
                const SizedBox(height: 14),

                // Cow count & Default rate
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: context.tr('cows_owned'),
                        hint: '5',
                        controller: _cowCountController,
                        keyboardType: TextInputType.number,
                        validator: Validators.required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'दूध दर (₹/Litre)',
                        hint: '60',
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: Validators.required,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: 'डेअरी खाते सुरू करा (Register)',
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
