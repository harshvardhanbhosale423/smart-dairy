import 'dart:io';
import 'package:flutter/foundation.dart';
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
import 'upi_service.dart';

class PdfService {
  /// Generate printable, premium PDF Invoice for Monthly Bill
  static Future<File> generateMonthlyBillPdf({
    required CustomerModel customer,
    required MonthlyBillModel bill,
    required DairySettingsModel dairy,
    required List<MilkEntryModel> monthEntries,
    bool isMarathi = true,
  }) async {
    // 1. Load Devanagari Font to ensure Marathi letters never appear as black boxes
    pw.Font? devanagariFont;
    pw.Font? devanagariBoldFont;
    bool hasDevanagari = false;

    try {
      devanagariFont = await PdfGoogleFonts.notoSansDevanagariRegular();
      devanagariBoldFont = await PdfGoogleFonts.notoSansDevanagariBold();
      hasDevanagari = true;
    } catch (e) {
      debugPrint('PdfService font loading note: $e');
    }

    final theme = hasDevanagari
        ? pw.ThemeData.withFont(base: devanagariFont, bold: devanagariBoldFont)
        : pw.ThemeData.withFont(base: pw.Font.helvetica(), bold: pw.Font.helveticaBold());

    final pdf = pw.Document(theme: theme);

    // Premium Color Palette
    final primaryGreen = PdfColor.fromHex('1B4332'); // Deep Forest Green
    final accentGold = PdfColor.fromHex('D4AF37');   // Royal Gold
    final emeraldTint = PdfColor.fromHex('E8F5E9');  // Soft Emerald
    final borderGrey = PdfColor.fromHex('D1D5DB');   // Clean Silver Grey
    final textDark = PdfColor.fromHex('1F2937');     // Charcoal
    final textMuted = PdfColor.fromHex('4B5563');    // Subtle Slate
    final zebraLight = PdfColor.fromHex('F9FAFB');   // Very Light Grey

    // Currency representation: if font loaded use ₹ else Rs.
    final curr = hasDevanagari ? '₹' : 'Rs.';

    // UPI QR URI
    final validUpi = UpiService.isValidUpiId(dairy.ownerUpiId);
    final upiUri = validUpi
        ? UpiService.buildUpiUri(
            upiId: dairy.ownerUpiId,
            payeeName: dairy.dairyName,
            amount: bill.finalPayable,
            transactionNote: 'Bill-${customer.name}-${bill.yearMonth}',
          )
        : '';

    // Calculate total delivered in entries
    final totalLitres = monthEntries.fold<double>(0.0, (sum, e) => sum + e.totalQty);
    final totalCharges = monthEntries.fold<double>(0.0, (sum, e) => sum + e.totalAmount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        build: (pw.Context context) {
          return [
            // 1. Executive Top Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                color: primaryGreen,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          dairy.dairyName.trim().isNotEmpty ? dairy.dairyName.trim() : 'SMART DAIRY',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          hasDevanagari
                              ? 'ताजे, शुद्ध व सकस गायीचे दूध वाटप सेवा 🥛'
                              : 'Fresh, Pure & Nutritious Cow Milk Delivery',
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${hasDevanagari ? "मालक: " : "Owner: "}${dairy.ownerName} | Mo: ${dairy.ownerPhone}',
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: accentGold,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          hasDevanagari ? 'मासिक दूध बिल' : 'MONTHLY BILL',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          hasDevanagari ? bill.monthNameMr : bill.monthNameEn,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // 2. Customer & Invoice Info Card (Side-by-Side)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderGrey, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Customer Info
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        hasDevanagari ? 'ग्राहक माहिती / Customer Details:' : 'Customer Details:',
                        style: pw.TextStyle(fontSize: 9, color: textMuted, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        customer.name,
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: textDark),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '${hasDevanagari ? "फोन: " : "Phone: "}${customer.phone}${customer.address.isNotEmpty ? " | " + customer.address : ""}',
                        style: pw.TextStyle(fontSize: 10, color: textMuted),
                      ),
                    ],
                  ),

                  // Bill Metadata
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        '${hasDevanagari ? "बिल क्र: " : "Bill No: "}SD-${bill.yearMonth}-${customer.id.length > 5 ? customer.id.substring(customer.id.length - 5) : customer.id}',
                        style: pw.TextStyle(fontSize: 9, color: textMuted),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '${hasDevanagari ? "तारीख: " : "Date: "}${DateFormatter.formatShortDate(bill.createdAt)}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: bill.status == 'PAID' ? PdfColor.fromHex('DCFCE7') : PdfColor.fromHex('FEE2E2'),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          bill.status == 'PAID'
                              ? (hasDevanagari ? 'भरलेले (PAID)' : 'PAID')
                              : (hasDevanagari ? 'बाकी (UNPAID)' : 'UNPAID'),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: bill.status == 'PAID' ? PdfColors.green900 : PdfColors.red900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // 3. Section Title
            pw.Text(
              hasDevanagari ? 'दैनिक दूध वितरण तपशील' : 'Daily Milk Delivery Breakdown',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryGreen),
            ),
            pw.SizedBox(height: 6),

            // 4. Premium Milk Delivery Table
            pw.Table(
              border: pw.TableBorder.all(color: borderGrey, width: 0.5),
              children: [
                // Header Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: emeraldTint),
                  children: [
                    _headerCell(hasDevanagari ? 'दिनांक' : 'Date'),
                    _headerCell(hasDevanagari ? 'सकाळ (L)' : 'Morn (L)'),
                    _headerCell(hasDevanagari ? 'संध्याकाळ (L)' : 'Eve (L)'),
                    _headerCell(hasDevanagari ? 'एकूण दूध (L)' : 'Total (L)'),
                    _headerCell(hasDevanagari ? 'दर ($curr)' : 'Rate ($curr)'),
                    _headerCell(hasDevanagari ? 'रक्कम ($curr)' : 'Amount ($curr)'),
                  ],
                ),
                // Data Rows with subtle alternating zebra color
                ...monthEntries.asMap().entries.map((entryItem) {
                  final idx = entryItem.key;
                  final e = entryItem.value;
                  final isEven = idx % 2 == 0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : zebraLight),
                    children: [
                      _dataCell(DateFormatter.formatShortDate(e.date)),
                      _dataCell(e.morningQty > 0 ? e.morningQty.toStringAsFixed(1) : '-'),
                      _dataCell(e.eveningQty > 0 ? e.eveningQty.toStringAsFixed(1) : '-'),
                      _dataCell(e.totalQty.toStringAsFixed(1), isBold: true),
                      _dataCell(e.ratePerLitre.toStringAsFixed(0)),
                      _dataCell(e.totalAmount.toStringAsFixed(2), isBold: true),
                    ],
                  );
                }),
                // Table Total Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: emeraldTint),
                  children: [
                    _dataCell(hasDevanagari ? 'एकूण' : 'Total', isBold: true),
                    _dataCell(''),
                    _dataCell(''),
                    _dataCell('${totalLitres.toStringAsFixed(1)} L', isBold: true),
                    _dataCell(''),
                    _dataCell('$curr ${totalCharges.toStringAsFixed(2)}', isBold: true),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 14),

            // 5. Payment & Financial Summary (Side-by-Side)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left: Digital UPI QR Code Card
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderGrey, width: 1),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          hasDevanagari ? 'ऑनलाइन पेमेंट (UPI QR Code)' : 'Scan & Pay via UPI',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryGreen),
                        ),
                        pw.SizedBox(height: 6),
                        if (validUpi && upiUri.isNotEmpty) ...[
                          pw.BarcodeWidget(
                            data: upiUri,
                            barcode: pw.Barcode.qrCode(),
                            width: 90,
                            height: 90,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            dairy.ownerUpiId,
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark),
                          ),
                          pw.Text(
                            dairy.dairyName,
                            style: pw.TextStyle(fontSize: 8, color: textMuted),
                          ),
                        ] else ...[
                          pw.Container(
                            height: 80,
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              hasDevanagari ? 'रोख किंवा थेट पेमेंट करा' : 'Cash or Direct Bank Transfer',
                              style: pw.TextStyle(fontSize: 9, color: textMuted),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                pw.SizedBox(width: 14),

                // Right: Financial Summary Card
                pw.Expanded(
                  flex: 7,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: zebraLight,
                      border: pw.Border.all(color: borderGrey, width: 1),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    ),
                    child: pw.Column(
                      children: [
                        _statementRow(
                          hasDevanagari ? 'एकूण दूध प्रमाण:' : 'Total Milk Delivered:',
                          '${bill.totalMilkLitres.toStringAsFixed(1)} Litres',
                        ),
                        pw.Divider(color: borderGrey, thickness: 0.5),
                        _statementRow(
                          hasDevanagari ? 'चालू महिन्याचे भाडे:' : 'Current Milk Charges:',
                          '$curr ${bill.currentMonthMilkCharges.toStringAsFixed(2)}',
                        ),
                        _statementRow(
                          hasDevanagari ? 'मागील येणे बाकी (+):' : 'Previous Dues (+):',
                          '$curr ${bill.previousBalance.toStringAsFixed(2)}',
                        ),
                        _statementRow(
                          hasDevanagari ? 'जमा झालेली रक्कम (-):' : 'Payments Received (-):',
                          '- $curr ${bill.paidAmount.toStringAsFixed(2)}',
                          valueColor: PdfColors.green800,
                        ),
                        pw.SizedBox(height: 6),
                        // Highlighted Final Total Box
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: pw.BoxDecoration(
                            color: primaryGreen,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                hasDevanagari ? 'एकूण भरावयाची रक्कम:' : 'Total Payable Amount:',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.Text(
                                '$curr ${bill.finalPayable.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  fontSize: 13,
                                  fontWeight: pw.FontWeight.bold,
                                  color: accentGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // 6. Footer & Signature
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      hasDevanagari
                          ? 'धन्यवाद! शुद्ध दूध, निरोगी आयुष्य.'
                          : 'Thank you! Pure Milk for Healthy Life.',
                      style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: primaryGreen),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Smart Dairy App द्वारे तयार केलेले अधिकृत संगणकीकृत बिल',
                      style: pw.TextStyle(fontSize: 7, color: textMuted),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 130,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 1)),
                      ),
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Center(
                        child: pw.Text(
                          hasDevanagari ? 'डेअरी मालकाची सही' : 'Authorized Signature',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark),
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
    final cleanCustName = customer.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final file = File('${outputDir.path}/Bill_${cleanCustName}_${bill.yearMonth}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  static pw.Widget _dataCell(String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColors.black,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  static pw.Widget _statementRow(String label, String value, {PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: valueColor ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
