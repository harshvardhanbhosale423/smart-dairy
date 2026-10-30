import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../../features/billing/models/monthly_bill_model.dart';
import '../../features/customers/models/customer_model.dart';
import '../../features/milk_entry/models/milk_entry_model.dart';
import '../../features/settings/models/dairy_settings_model.dart';

class PdfService {
  /// Generate printable PDF Invoice for Monthly Bill
  static Future<File> generateMonthlyBillPdf({
    required CustomerModel customer,
    required MonthlyBillModel bill,
    required DairySettingsModel dairy,
    required List<MilkEntryModel> monthEntries,
    bool isMarathi = false,
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('14532D'); // Dark Dairy Green
    final accentGold = PdfColor.fromHex('F59E0B');
    final surfaceCream = PdfColor.fromHex('FAF7F2');
    final lightGrey = PdfColor.fromHex('E5E7EB');

    // Build UPI URI for QR Code
    final upiUri = 'upi://pay?pa=${dairy.ownerUpiId}&pn=${dairy.dairyName}&am=${bill.finalPayable.toStringAsFixed(2)}&tn=Bill-${bill.yearMonth}&cu=INR';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Dairy Farm Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        dairy.dairyName.toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        isMarathi ? 'ताजे व सकस गायीचे दूध' : 'Fresh Cow Milk Distribution',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
                      ),
                      pw.Text(
                        '${dairy.ownerName} | Mo: ${dairy.ownerPhone}',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: accentGold,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          isMarathi ? 'मासिक दूध बिल' : 'MONTHLY BILL',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.Text(
                          isMarathi ? bill.monthNameMr : bill.monthNameEn,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // Customer Info Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: lightGrey),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        isMarathi ? 'ग्राहक नाव:' : 'Customer Name:',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        customer.name,
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${customer.phone} ${customer.address.isNotEmpty ? "| " + customer.address : ""}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        isMarathi ? 'बिल दिनांक:' : 'Bill Date:',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        DateFormatter.formatShortDate(bill.createdAt),
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Status: ${bill.status}',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: bill.status == 'PAID' ? PdfColors.green800 : PdfColors.red800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // Daily Milk Table
            pw.Text(
              isMarathi ? 'दैनिक दूध वाटप नोंद तपशील' : 'Daily Milk Delivery Breakdown',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: lightGrey, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: surfaceCream),
                  children: [
                    _tableHeaderCell(isMarathi ? 'दिनांक' : 'Date'),
                    _tableHeaderCell(isMarathi ? 'सकाळ (L)' : 'Morn (L)'),
                    _tableHeaderCell(isMarathi ? 'संध्याकाळ (L)' : 'Eve (L)'),
                    _tableHeaderCell(isMarathi ? 'एकूण (L)' : 'Total (L)'),
                    _tableHeaderCell(isMarathi ? 'दर (₹)' : 'Rate (₹)'),
                    _tableHeaderCell(isMarathi ? 'रक्कम (₹)' : 'Amount (₹)'),
                  ],
                ),
                ...monthEntries.map((e) => pw.TableRow(
                  children: [
                    _tableCell(DateFormatter.formatShortDate(e.date)),
                    _tableCell(e.morningQty.toStringAsFixed(1)),
                    _tableCell(e.eveningQty.toStringAsFixed(1)),
                    _tableCell(e.totalQty.toStringAsFixed(1), isBold: true),
                    _tableCell(e.ratePerLitre.toStringAsFixed(0)),
                    _tableCell(CurrencyFormatter.formatWithoutSymbol(e.totalAmount)),
                  ],
                )),
              ],
            ),

            pw.SizedBox(height: 16),

            // Financial Summary & UPI QR Code Section
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // UPI QR Code
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: lightGrey),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          isMarathi ? 'QR कोड स्कॅन करून पैसे भरा' : 'Scan QR to Pay via UPI',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 8),
                        pw.BarcodeWidget(
                          data: upiUri,
                          barcode: pw.Barcode.qrCode(),
                          width: 100,
                          height: 100,
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          dairy.ownerUpiId,
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          dairy.dairyName,
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                ),

                pw.SizedBox(width: 16),

                // Financial Breakdown Box
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: surfaceCream,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: lightGrey),
                    ),
                    child: pw.Column(
                      children: [
                        _summaryRow(
                          isMarathi ? 'एकूण दूध प्रमाण:' : 'Total Milk Delivered:',
                          '${bill.totalMilkLitres.toStringAsFixed(1)} Litres',
                        ),
                        pw.Divider(color: lightGrey),
                        _summaryRow(
                          isMarathi ? 'चालू महिन्याचे भाडे:' : 'Current Month Milk Charges:',
                          CurrencyFormatter.format(bill.currentMonthMilkCharges),
                        ),
                        _summaryRow(
                          isMarathi ? 'मागील येणे बाकी:' : 'Previous Outstanding:',
                          CurrencyFormatter.format(bill.previousBalance),
                        ),
                        _summaryRow(
                          isMarathi ? 'जमा झालेली रक्कम (-):' : 'Payments Deducted (-):',
                          CurrencyFormatter.format(bill.paidAmount),
                          color: PdfColors.green800,
                        ),
                        pw.Divider(thickness: 1.5, color: primaryColor),
                        _summaryRow(
                          isMarathi ? 'एकूण भरावयाची रक्कम:' : 'Total Payable Amount:',
                          CurrencyFormatter.format(bill.finalPayable),
                          isTotal: true,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 24),

            // Footer & Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      isMarathi ? 'धन्यवाद! पुन्हा सेवेची संधी द्या.' : 'Thank you for choosing Smart Dairy!',
                      style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                    ),
                    pw.Text(
                      'Generated securely via Smart Dairy App',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 120,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey600, width: 1)),
                      ),
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Center(
                        child: pw.Text(
                          isMarathi ? 'डेअरी मालकाची स्वाक्षरी' : 'Authorized Signature',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    final outputDir = await getTemporaryDirectory();
    final file = File('${outputDir.path}/Bill_${customer.name}_${bill.yearMonth}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool isTotal = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 12 : 10,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 10,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.bold,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

