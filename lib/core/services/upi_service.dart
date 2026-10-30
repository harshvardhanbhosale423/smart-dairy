import 'package:url_launcher/url_launcher.dart';

class UpiService {
  /// Generate the standard NPCI compliant UPI Intent URI
  static String buildUpiUri({
    required String upiId,
    required String payeeName,
    required double amount,
    required String transactionNote,
    String currency = 'INR',
  }) {
    final cleanUpi = upiId.trim();
    final cleanName = Uri.encodeComponent(payeeName.trim());
    final cleanNote = Uri.encodeComponent(transactionNote.trim());
    final formattedAmount = amount.toStringAsFixed(2);

    return 'upi://pay?pa=$cleanUpi&pn=$cleanName&am=$formattedAmount&tn=$cleanNote&cu=$currency';
  }

  /// Launch generic UPI Intent (Android OS will show app chooser)
  static Future<bool> launchUpiIntent({
    required String upiUri,
  }) async {
    final uri = Uri.parse(upiUri);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Launch specific UPI app
  static Future<bool> launchSpecificApp({
    required String upiId,
    required String payeeName,
    required double amount,
    required String transactionNote,
    required String appScheme, // 'tez', 'phonepe', 'paytmmp', 'bhim'
  }) async {
    final cleanUpi = upiId.trim();
    final cleanName = Uri.encodeComponent(payeeName.trim());
    final cleanNote = Uri.encodeComponent(transactionNote.trim());
    final formattedAmount = amount.toStringAsFixed(2);

    final appUriString = '$appScheme://upi/pay?pa=$cleanUpi&pn=$cleanName&am=$formattedAmount&tn=$cleanNote&cu=INR';
    final uri = Uri.parse(appUriString);

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to standard generic UPI intent
      final genericUri = Uri.parse('upi://pay?pa=$cleanUpi&pn=$cleanName&am=$formattedAmount&tn=$cleanNote&cu=INR');
      if (await canLaunchUrl(genericUri)) {
        return await launchUrl(genericUri, mode: LaunchMode.externalApplication);
      }
    }
    return false;
  }
}

