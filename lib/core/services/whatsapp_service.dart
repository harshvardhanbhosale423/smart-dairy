import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/currency_formatter.dart';
import '../../features/billing/models/monthly_bill_model.dart';
import '../../features/customers/models/customer_model.dart';
import 'app_launcher.dart';

class WhatsAppService {
  /// Generate formatted monthly bill message in Marathi
  static String formatMarathiBillMessage({
    required CustomerModel customer,
    required MonthlyBillModel bill,
    required String dairyName,
    required String ownerUpiId,
  }) {
    final formattedMonth = bill.monthNameMr;
    final totalMilk = bill.totalMilkLitres.toStringAsFixed(1);
    final rate = CurrencyFormatter.format(bill.appliedRate);
    final milkCharges = CurrencyFormatter.format(bill.currentMonthMilkCharges);
    final prevBalance = CurrencyFormatter.format(bill.previousBalance);
    final payments = CurrencyFormatter.format(bill.paidAmount);
    final totalPayable = CurrencyFormatter.format(bill.finalPayable);

    return '''
🐄 *${dairyName.trim()} - मासिक दूध बिल* 🥛
----------------------------------------
नमस्कार *${customer.name.trim()}जी!*

आपले *${formattedMonth}* महिन्याचे दूध बिल खालीलप्रमाणे आहे:

📅 *महिना:* $formattedMonth
🥛 *एकूण दूध:* $totalMilk लिटर
💰 *प्रति लिटर दर:* $rate
💵 *चालू महिन्याचे दुधाचे भाडे:* $milkCharges
🔺 *मागील येणे बाकी:* $prevBalance
💳 *जमा झालेली रक्कम:* $payments
----------------------------------------
👉 *एकूण भरावयाची बाकी रक्कम:* *${totalPayable}*
----------------------------------------

📲 *UPI द्वारे पेमेंट करण्यासाठी ID:*
`${ownerUpiId.trim()}`

कृपया वेळेवर बिल भरून सहकार्य करावे.
*${dairyName.trim()}* निवडल्याबद्दल धन्यवाद! 🙏
''';
  }

  /// Generate formatted monthly bill message in English
  static String formatEnglishBillMessage({
    required CustomerModel customer,
    required MonthlyBillModel bill,
    required String dairyName,
    required String ownerUpiId,
  }) {
    final formattedMonth = bill.monthNameEn;
    final totalMilk = bill.totalMilkLitres.toStringAsFixed(1);
    final rate = CurrencyFormatter.format(bill.appliedRate);
    final milkCharges = CurrencyFormatter.format(bill.currentMonthMilkCharges);
    final prevBalance = CurrencyFormatter.format(bill.previousBalance);
    final payments = CurrencyFormatter.format(bill.paidAmount);
    final totalPayable = CurrencyFormatter.format(bill.finalPayable);

    return '''
🐄 *${dairyName.trim()} - Monthly Milk Statement* 🥛
----------------------------------------
Namaskar *${customer.name.trim()}ji!*

Here is your milk statement for *${formattedMonth}*:

📅 *Billing Month:* $formattedMonth
🥛 *Total Milk Delivered:* $totalMilk Litres
💰 *Rate per Litre:* $rate
💵 *Current Month Charges:* $milkCharges
🔺 *Previous Balance:* $prevBalance
💳 *Payments Received:* $payments
----------------------------------------
👉 *Total Outstanding Payable:* *${totalPayable}*
----------------------------------------

📲 *Pay via UPI ID:*
`${ownerUpiId.trim()}`

Please settle the dues at your earliest convenience.
Thank you for choosing *${dairyName.trim()}*! 🙏
''';
  }

  /// Share message directly via WhatsApp deep link with fallback
  static Future<bool> sendWhatsAppMessage({
    required String phone,
    required String message,
  }) async {
    return await AppLauncher.openWhatsApp(
      phone: phone,
      message: message,
    );
  }

  /// Share PDF Bill along with WhatsApp caption
  static Future<void> sharePdfBill({
    required String filePath,
    required String textMessage,
    required String customerName,
  }) async {
    final file = XFile(filePath);
    await Share.shareXFiles(
      [file],
      text: textMessage,
      subject: 'Milk Bill - $customerName',
    );
  }
}

