import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';

class AppLauncher {
  /// Clean and format Indian phone number
  static String sanitizePhone(String phone, {bool prependCountryCode = false}) {
    var cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (prependCountryCode) {
      var digitsOnly = cleaned.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length == 10) {
        return '91$digitsOnly';
      }
      return digitsOnly;
    }
    return cleaned;
  }

  /// Make phone call directly to dialer
  static Future<bool> makePhoneCall(BuildContext? context, String phone) async {
    final cleanPhone = sanitizePhone(phone);
    if (cleanPhone.isEmpty) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('फोन नंबर उपलब्ध नाही / Phone number not available'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return false;
    }

    final uri = Uri.parse('tel:$cleanPhone');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (_) {}

    // Fallback try without mode
    try {
      return await launchUrl(uri);
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('कॉल करता आला नाही: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    }
  }

  /// Open WhatsApp with contact and optional pre-filled message
  static Future<bool> openWhatsApp({
    BuildContext? context,
    required String phone,
    String? message,
  }) async {
    final cleanPhone = sanitizePhone(phone, prependCountryCode: true);
    if (cleanPhone.isEmpty) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('व्हॉट्सअ‍ॅप नंबर उपलब्ध नाही / Phone number not available'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return false;
    }

    final text = message ?? '';
    final encoded = Uri.encodeComponent(text);

    // 1. Try WhatsApp native deep link
    final nativeUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encoded');
    try {
      final launched = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (_) {}

    // 2. Try wa.me web link
    final webUri = Uri.parse('https://wa.me/$cleanPhone?text=$encoded');
    try {
      final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (_) {}

    // 3. Fallback to Share sheet if WhatsApp app is not directly accessible
    if (text.isNotEmpty) {
      try {
        await Share.share(text, subject: 'Smart Dairy');
        return true;
      } catch (_) {}
    }

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp उघडता आले नाही. कृपया WhatsApp इन्स्टॉल असल्याचे तपासा.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    return false;
  }

  /// Open SMS app with number and body
  static Future<bool> openSms({
    BuildContext? context,
    required String phone,
    String? message,
  }) async {
    final cleanPhone = sanitizePhone(phone);
    final text = message ?? '';
    final encoded = Uri.encodeComponent(text);

    final uri = Uri.parse('sms:$cleanPhone?body=$encoded');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (_) {}

    try {
      final smstoUri = Uri.parse('smsto:$cleanPhone');
      return await launchUrl(smstoUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('मेसेज ॲप उघडता आले नाही: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    }
  }
}

