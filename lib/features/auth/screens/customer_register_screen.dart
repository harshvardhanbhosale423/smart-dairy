import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _morningController = TextEditingController(text: '1.0');
  final _eveningController = TextEditingController(text: '1.0');

  bool _obscurePassword = true;
  String? _selectedDairyId;
  String? _selectedDairyName;
  List<Map<String, dynamic>> _dairies = [];
  bool _loadingDairies = true;

  @override
  void initState() {
    super.initState();
    _loadDairies();
  }

  void _loadDairies() async {
    final list = await context.read<AuthProvider>().getAvailableDairies();
    if (mounted) {
      setState(() {
        _dairies = list;
        _loadingDairies = false;
        if (list.isNotEmpty) {
          _selectedDairyId = list.first['ownerId'] ?? list.first['id'];
          _selectedDairyName = list.first['dairyName'] ?? 'Smart Dairy';
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _morningController.dispose();
    _eveningController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDairyId == null && _dairies.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया डेअरी निवडा'), backgroundColor: AppColors.error),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final morning = double.tryParse(_morningController.text.trim()) ?? 1.0;
    final evening = double.tryParse(_eveningController.text.trim()) ?? 1.0;

    final success = await auth.registerCustomerSelf(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      address: _addressController.text.trim(),
      dairyId: _selectedDairyId ?? 'default_owner',
      morningQuota: morning,
      eveningQuota: evening,
    );

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppColors.darkGreen, size: 28),
              SizedBox(width: 8),
              Text('नोंदणी यशस्वी!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'तुमची ग्राहक नोंदणी यशस्वीपणे झाली आहे!\n\nडेअरी मालक (Dairy Owner) तुमचे खाते तपासून मंजूर (Approve) करतील, त्यानंतर तुम्ही आपल्या युझरनेम व पासवर्डने थेट लॉगिन करू शकाल.',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Back to login screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                foregroundColor: AppColors.pureWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('ठीक आहे (लॉगिनवर जा)'),
            ),
          ],
        ),
      );
    } else if (auth.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('register_customer')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.softCream,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.how_to_reg_rounded, color: AppColors.primaryGreen, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'नवीन ग्राहक खाते नोंदणी\n(नोंदणीनंतर मालकांची मंजुरी आवश्यक राहील)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Customer Name
                CustomTextField(
                  label: 'आपले पूर्ण नाव (Customer Name)',
                  hint: 'उदा. राहुल पाटील',
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.darkGreen),
                  validator: Validators.required,
                ),
                const SizedBox(height: 14),

                // Mobile Number
                CustomTextField(
                  label: context.tr('phone_number'),
                  hint: '१० अंकी मोबाईल नंबर',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.darkGreen),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 14),

                // Desired Username
                CustomTextField(
                  label: 'लॉगिन युझरनेम (Username)',
                  hint: 'उदा. rahul12 किंवा मोबाईल नंबर',
                  controller: _usernameController,
                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.darkGreen),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'युझरनेम आवश्यक आहे';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password
                CustomTextField(
                  label: context.tr('password'),
                  hint: 'आपला पासवर्ड ठेवा',
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
                    if (val == null || val.trim().isEmpty) return 'पासवर्ड आवश्यक आहे';
                    if (val.trim().length < 4) return 'किमान ४ अक्षरे असावी';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Select Dairy Farm
                if (_loadingDairies)
                  const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                else if (_dairies.isNotEmpty) ...[
                  Text(
                    context.tr('select_dairy'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.softCream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedDairyId,
                        items: _dairies.map((d) {
                          final dName = d['dairyName'] ?? 'Smart Dairy';
                          final dOwner = d['ownerName'] ?? '';
                          final dId = d['ownerId'] ?? d['id'];
                          return DropdownMenuItem<String>(
                            value: dId,
                            child: Text('$dName ($dOwner)'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedDairyId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Milk Quotas
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'सकाळचे दूध (लिटर)',
                        hint: '1.0',
                        controller: _morningController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'संध्याकाळचे दूध (लिटर)',
                        hint: '1.0',
                        controller: _eveningController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Address
                CustomTextField(
                  label: 'दूध वाटपाचा पत्ता (Address)',
                  hint: 'घर क्र., गल्ली, परिसर',
                  controller: _addressController,
                  maxLines: 2,
                  prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.darkGreen),
                  validator: Validators.required,
                ),
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: 'नोंदणी अर्ज पाठवा (Submit)',
                  icon: Icons.send_rounded,
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
