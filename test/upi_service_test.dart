import 'package:flutter_test/flutter_test.dart';
import 'package:smart_dairy/core/services/upi_service.dart';

void main() {
  group('UpiService URI Generation', () {
    test('Builds valid NPCI compliant UPI Intent URI', () {
      final uri = UpiService.buildUpiUri(
        upiId: 'dairyowner@oksbi',
        payeeName: 'Smart Dairy Farm',
        amount: 1800.0,
        transactionNote: 'Bill-2026-10',
      );

      expect(uri, startsWith('upi://pay?'));
      expect(uri, contains('pa=dairyowner@oksbi'));
      expect(uri, contains('pn=Smart%20Dairy%20Farm'));
      expect(uri, contains('am=1800.00'));
      expect(uri, contains('tn=Bill-2026-10'));
      expect(uri, contains('cu=INR'));
    });

    test('Encodes special characters and spaces properly in payee name and note', () {
      final uri = UpiService.buildUpiUri(
        upiId: '9822112233@paytm',
        payeeName: 'Mauli Dairy (पाटील)',
        amount: 250.50,
        transactionNote: 'Milk bill / ऑक्टोबर',
      );

      expect(uri, contains('pa=9822112233@paytm'));
      expect(uri, contains('am=250.50'));
      expect(uri, isNot(contains(' '))); // no raw unencoded spaces
    });
  });
}

