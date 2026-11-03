import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/customers/models/customer_model.dart';
import '../../features/milk_entry/models/milk_entry_model.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import 'app_launcher.dart';

class SmsService {
  static const MethodChannel _channel = MethodChannel('com.smartdairy.app/sms');

  /// Check if SEND_SMS permission is granted
  static Future<bool> checkPermission() async {
    try {
      final granted = await _channel.invokeMethod<bool>('checkSmsPermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Request SEND_SMS permission
  static Future<bool> requestPermission() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestSmsPermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Send SMS directly from owner's SIM card using daily recharge
  static Future<bool> sendDirectSms({
    required String phone,
    required String message,
  }) async {
    try {
      final cleanPhone = AppLauncher.sanitizePhone(phone);
      if (cleanPhone.isEmpty) return false;

      final success = await _channel.invokeMethod<bool>('sendDirectSms', {
        'phone': cleanPhone,
        'message': message,
      });
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open default SMS Messenger app with pre-filled number & text
  static Future<bool> openSmsMessenger({
    required String phone,
    required String message,
  }) async {
    try {
      final cleanPhone = AppLauncher.sanitizePhone(phone);
      if (cleanPhone.isEmpty) return false;

      final success = await _channel.invokeMethod<bool>('openSmsApp', {
        'phone': cleanPhone,
        'message': message,
      });
      return success ?? false;
    } catch (_) {
      // Fallback via URL launcher
      return await AppLauncher.openSms(phone: phone, message: message);
    }
  }

  /// Format milk entry text message
  static String formatMilkEntryMessage({
    required CustomerModel customer,
    required MilkEntryModel entry,
    required String dairyName,
    double? balance,
  }) {
    final dateStr = DateFormatter.formatDate(entry.date);
    final cleanDairy = dairyName.isNotEmpty ? dairyName.trim() : 'Smart Dairy';

    if (entry.isZeroMilk) {
      return 'स्मार्ट डेअरी - दूध नोंद 🥛\n'
          'दिनांक: $dateStr\n'
          'ग्राहक: ${customer.name}\n'
          'आज दूध आले नाही (0L).\n'
          'चालू बाकी: ${CurrencyFormatter.format(balance ?? customer.currentBalance)}\n\n'
          'धन्यवाद!\n- $cleanDairy';
    }

    final morningStr = entry.morningQty > 0 ? '${entry.morningQty}L' : '0L';
    final eveningStr = entry.eveningQty > 0 ? '${entry.eveningQty}L' : '0L';
    final totalStr = '${entry.totalQty}L';
    final amountStr = CurrencyFormatter.format(entry.totalAmount);
    final currentBalStr = CurrencyFormatter.format(balance ?? (customer.currentBalance + entry.totalAmount));

    return 'स्मार्ट डेअरी - दूध नोंद 🥛\n'
        'दिनांक: $dateStr\n'
        'ग्राहक: ${customer.name}\n'
        'सकाळ: $morningStr | संध्याकाळ: $eveningStr\n'
        'एकूण दूध: $totalStr\n'
        'दर: ₹${entry.rate.toStringAsFixed(0)}/L | एकूण रक्कम: $amountStr\n'
        'चालू शिल्लक: $currentBalStr\n\n'
        'धन्यवाद!\n- $cleanDairy';
  }

  /// Automatically dispatch Milk Entry SMS to customer
  static Future<bool> sendMilkEntrySms({
    required CustomerModel customer,
    required MilkEntryModel entry,
    required String dairyName,
    double? balance,
    BuildContext? context,
  }) async {
    if (customer.phone.trim().isEmpty) return false;

    final message = formatMilkEntryMessage(
      customer: customer,
      entry: entry,
      dairyName: dairyName,
      balance: balance,
    );

    // 1. Try sending directly via SIM / SmsManager
    final directSent = await sendDirectSms(
      phone: customer.phone,
      message: message,
    );

    if (directSent) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ग्राहकाला SMS पाठवला (${customer.name}) 📩'),
            backgroundColor: const Color(0xFF1B5E20),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return true;
    }

    // 2. If direct SMS fails (e.g. permission denied or dual SIM chooser needed), open default SMS app
    final opened = await openSmsMessenger(
      phone: customer.phone,
      message: message,
    );

    return opened;
  }
}
