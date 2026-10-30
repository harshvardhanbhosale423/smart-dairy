import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
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

    _loadDairyDetails();
  }

  Future<void> _loadDairyDetails() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('dairy_profiles').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      setState(() {
        _dairyNameController.text = data['dairyName'] ?? '';
        _ownerNameController.text = data['ownerName'] ?? '';
        _cowCountController.text = (data['cowCount'] ?? 5).toString();
        _rateController.text = (data['defaultMilkRate'] ?? 60.0).toString();
        _addressController.text = data['address'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _dairyNameController.dispose();
    _ownerNameController.dispose();
    _cowCountController.dispose();
    _rateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    await FirebaseFirestore.instance.collection('dairy_profiles').doc(user.uid).set({
      'ownerId': user.uid,
      'dairyName': _dairyNameController.text.trim(),
      'ownerName': _ownerNameController.text.trim(),
      'cowCount': int.tryParse(_cowCountController.text.trim()) ?? 5,
      'defaultMilkRate': double.tryParse(_rateController.text.trim()) ?? 60.0,
      'address': _addressController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

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

