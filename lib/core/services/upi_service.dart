import 'package:url_launcher/url_launcher.dart';

class UpiService {
  /// Check if the UPI ID is real, valid, and not a dummy placeholder
  static bool isValidUpiId(String? upiId) {
    if (upiId == null) return false;
    final clean = upiId.trim().toLowerCase();
    if (clean.isEmpty) return false;
    if (!clean.contains('@')) return false;

    // Block known dummy or placeholder UPI IDs
    final dummyIds = [
      'owner@upi',
      'harshvardhan@upi',
      'test@upi',
      'demo@upi',
      'example@upi',
      'sample@upi',
      'admin@upi',
      'user@upi',
    ];
    if (dummyIds.contains(clean)) return false;

    // Basic format: username@bank
    final upiRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');
    return upiRegex.hasMatch(clean);
  }

  /// Generate the standard NPCI compliant UPI Intent URI
  static String buildUpiUri({
    required String upiId,
    required String payeeName,
    required double amount,
    required String transactionNote,
    String currency = 'INR',
  }) {
    final cleanUpi = upiId.trim();
    if (cleanUpi.isEmpty) return '';

    final cleanName = Uri.encodeComponent(payeeName.trim().isNotEmpty ? payeeName.trim() : 'Smart Dairy Owner');
    final cleanNote = Uri.encodeComponent(transactionNote.trim().isNotEmpty ? transactionNote.trim() : 'Milk Payment');
    final formattedAmount = amount > 0 ? amount.toStringAsFixed(2) : '0.00';

    return 'upi://pay?pa=$cleanUpi&pn=$cleanName&am=$formattedAmount&tn=$cleanNote&cu=$currency';
  }

  /// Launch generic UPI Intent (Android OS will show native UPI app chooser: GPay, PhonePe, Paytm, BHIM)
  static Future<bool> launchUpiIntent({
    required String upiUri,
  }) async {
    if (upiUri.isEmpty) return false;
    final uri = Uri.parse(upiUri);

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (_) {}

    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  /// Launch specific UPI app by scheme or fallback to generic UPI intent
  static Future<bool> launchSpecificApp({
    required String upiId,
    required String payeeName,
    required double amount,
    required String transactionNote,
    required String appScheme, // 'tez', 'phonepe', 'paytmmp', 'bhim'
  }) async {
    final cleanUpi = upiId.trim();
    if (!isValidUpiId(cleanUpi)) return false;

    final cleanName = Uri.encodeComponent(payeeName.trim().isNotEmpty ? payeeName.trim() : 'Dairy Owner');
    final cleanNote = Uri.encodeComponent(transactionNote.trim().isNotEmpty ? transactionNote.trim() : 'Milk Payment');
    final formattedAmount = amount.toStringAsFixed(2);

    // 1. Try specific app intent
    final appUri = Uri.parse('$appScheme://upi/pay?pa=$cleanUpi&pn=$cleanName&am=$formattedAmount&tn=$cleanNote&cu=INR');
    try {
      final launched = await launchUrl(appUri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (_) {}

    // 2. Fallback to standard generic UPI intent (Android will present installed UPI apps)
    final genericUri = Uri.parse('upi://pay?pa=$cleanUpi&pn=$cleanName&am=$formattedAmount&tn=$cleanNote&cu=INR');
    try {
      final launched = await launchUrl(genericUri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (_) {}

    try {
      return await launchUrl(genericUri);
    } catch (_) {
      return false;
    }
  }
}
