import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/services/local_database_service.dart';
import '../../auth/providers/auth_provider.dart';

class DairyProfileScreen extends StatefulWidget {
  const DairyProfileScreen({super.key});

  @override
  State<DairyProfileScreen> createState() => _DairyProfileScreenState();
}

class _DairyProfileScreenState extends State<DairyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _dairyNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _cowCountController;
  late TextEditingController _rateController;
  late TextEditingController _addressController;
  late TextEditingController _upiController;
  late TextEditingController _holderNameController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _dairyNameController = TextEditingController(text: user?.name ?? 'Smart Dairy Farm');
    _ownerNameController = TextEditingController(text: user?.name ?? '');
    _cowCountController = TextEditingController(text: '5');
    _rateController = TextEditingController(text: '60');
    _addressController = TextEditingController();
    _upiController = TextEditingController();
    _holderNameController = TextEditingController();

    _loadDairyDetails();
  }

  Future<void> _loadDairyDetails() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final localData = LocalDatabaseService().get('dairy_profiles', user.uid);
    if (localData != null) {
      setState(() {
        _dairyNameController.text = localData['dairyName'] ?? '';
        _ownerNameController.text = localData['ownerName'] ?? '';
        _cowCountController.text = (localData['cowCount'] ?? 5).toString();
        _rateController.text = (localData['defaultMilkRate'] ?? 60.0).toString();
        _addressController.text = localData['address'] ?? '';
        _upiController.text = localData['ownerUpiId'] ?? '';
        _holderNameController.text = localData['accountHolderName'] ?? localData['ownerName'] ?? '';
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('dairy_profiles').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        await LocalDatabaseService().set('dairy_profiles', user.uid, data);
        setState(() {
          _dairyNameController.text = data['dairyName'] ?? '';
          _ownerNameController.text = data['ownerName'] ?? '';
          _cowCountController.text = (data['cowCount'] ?? 5).toString();
          _rateController.text = (data['defaultMilkRate'] ?? 60.0).toString();
          _addressController.text = data['address'] ?? '';
          _upiController.text = data['ownerUpiId'] ?? '';
          _holderNameController.text = data['accountHolderName'] ?? data['ownerName'] ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _dairyNameController.dispose();
    _ownerNameController.dispose();
    _cowCountController.dispose();
    _rateController.dispose();
    _addressController.dispose();
    _upiController.dispose();
    _holderNameController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final profileData = {
      'ownerId': user.uid,
      'dairyName': _dairyNameController.text.trim(),
      'ownerName': _ownerNameController.text.trim(),
      'cowCount': int.tryParse(_cowCountController.text.trim()) ?? 5,
      'defaultMilkRate': double.tryParse(_rateController.text.trim()) ?? 60.0,
      'address': _addressController.text.trim(),
      'ownerUpiId': _upiController.text.trim(),
      'accountHolderName': _holderNameController.text.trim(),
      'updatedAt': Timestamp.now(),
    };

    // 1. Save locally
    await LocalDatabaseService().set('dairy_profiles', user.uid, profileData);

    // 2. Safe background cloud sync
    try {
      await FirebaseFirestore.instance.collection('dairy_profiles').doc(user.uid).set(
        profileData,
        SetOptions(merge: true),
      );
    } catch (_) {}

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dairy profile updated successfully!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dairy Profile & Cows'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _dairyNameController,
                  label: '${context.tr('dairy_name')} *',
                  hint: 'Smart Dairy Farm',
                  prefixIcon: Icons.store_rounded,
                  validator: (v) => Validators.validateRequired(v, context.tr('dairy_name')),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _ownerNameController,
                  label: '${context.tr('name')} *',
                  hint: 'Owner Name',
                  prefixIcon: Icons.person_rounded,
                  validator: (v) => Validators.validateRequired(v, context.tr('name')),
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
                        validator: (v) => Validators.validateNumber(v, 'Cows'),
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
                        validator: (v) => Validators.validateNumber(v, 'Milk Rate', allowZero: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // UPI Configuration Section
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.softLightGreen.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.payment_rounded, color: AppColors.darkGreen, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'UPI पेमेंट सेटिंग्ज (पैसे जमा होण्यासाठी)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkGreen),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _upiController,
                        label: 'मालकाचा UPI ID (उदा. 9822XXXXXX@ybl / patil@okaxis)',
                        hint: 'yourname@bank',
                        prefixIcon: Icons.account_balance_wallet_rounded,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: _holderNameController,
                        label: 'बँक खात्यावरील नाव (Account Holder Name)',
                        hint: 'उदा. हर्षवर्धन भोसले',
                        prefixIcon: Icons.badge_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _addressController,
                  label: context.tr('address'),
                  hint: 'Village / Farm Address',
                  prefixIcon: Icons.location_on_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 28),

                CustomButton(
                  text: context.tr('save'),
                  icon: Icons.check_circle_rounded,
                  isLoading: _isLoading,
                  onPressed: _onSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
