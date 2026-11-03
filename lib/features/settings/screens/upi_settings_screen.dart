import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/upi_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/services/local_database_service.dart';
import '../../auth/providers/auth_provider.dart';

class UpiSettingsScreen extends StatefulWidget {
  const UpiSettingsScreen({super.key});

  @override
  State<UpiSettingsScreen> createState() => _UpiSettingsScreenState();
}

class _UpiSettingsScreenState extends State<UpiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _upiIdController = TextEditingController();
  final _holderNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUpi();
  }

  Future<void> _loadUpi() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final localData = LocalDatabaseService().get('dairy_profiles', user.uid);
    if (localData != null) {
      setState(() {
        _upiIdController.text = localData['ownerUpiId'] ?? '';
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
          _upiIdController.text = data['ownerUpiId'] ?? '';
          _holderNameController.text = data['accountHolderName'] ?? data['ownerName'] ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _holderNameController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final upiUpdate = {
      'ownerUpiId': _upiIdController.text.trim(),
      'accountHolderName': _holderNameController.text.trim(),
      'updatedAt': Timestamp.now(),
    };

    // 1. Save locally
    await LocalDatabaseService().update('dairy_profiles', user.uid, upiUpdate);

    // 2. Safe cloud sync
    try {
      await FirebaseFirestore.instance.collection('dairy_profiles').doc(user.uid).set(
        {
          'ownerUpiId': _upiIdController.text.trim(),
          'accountHolderName': _holderNameController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI settings updated successfully!'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final upiId = _upiIdController.text.trim();
    final holderName = _holderNameController.text.trim().isNotEmpty
        ? _holderNameController.text.trim()
        : (user?.name ?? 'Smart Dairy');

    final testUri = upiId.isNotEmpty
        ? UpiService.buildUpiUri(
            upiId: upiId,
            payeeName: holderName,
            amount: 1.0,
            transactionNote: 'Smart Dairy Test QR',
          )
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Payment Configuration'),
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.softLightGreen.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.security_rounded, color: AppColors.darkGreen, size: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ग्राहक पेमेंट थेट तुमच्या बँक खात्यात जमा होईल. ग्राहकांचा UPI PIN कधीही विचारला जात नाही.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                CustomTextField(
                  controller: _upiIdController,
                  label: '${context.tr('upi_id')} *',
                  hint: 'उदा. 9822000000@okaxis किंवा name@paytm',
                  prefixIcon: Icons.qr_code_rounded,
                  validator: Validators.validateUpiId,
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: _holderNameController,
                  label: 'Account Holder Name / बँक खातेदाराचे नाव *',
                  hint: 'उदा. Rahul Ramesh Patil',
                  prefixIcon: Icons.person_rounded,
                  validator: (v) => Validators.validateRequired(v, 'Holder Name'),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 24),

                CustomButton(
                  text: context.tr('save'),
                  icon: Icons.check_circle_rounded,
                  isLoading: _isLoading,
                  onPressed: _onSave,
                ),

                const SizedBox(height: 32),

                // Live Dynamic QR Preview
                if (testUri.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Live Dynamic QR Preview / क्यूआर कोड पूर्वदृश्य:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: testUri,
                            size: 160,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            upiId,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          ),
                          Text(
                            holderName,
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => UpiService.launchUpiIntent(upiUri: testUri),
                            icon: const Icon(Icons.touch_app_rounded, size: 16),
                            label: const Text('UPI ॲपमध्ये स्वतःचे नाव तपासा (Test)'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

