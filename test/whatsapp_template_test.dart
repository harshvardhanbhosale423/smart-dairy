import 'package:flutter_test/flutter_test.dart';
import 'package:smart_dairy/core/services/whatsapp_service.dart';
import 'package:smart_dairy/features/billing/models/monthly_bill_model.dart';
import 'package:smart_dairy/features/customers/models/customer_model.dart';

void main() {
  group('WhatsApp Message Template Tests', () {
    test('Formats Marathi and English bill messages successfully', () {
      final testCustomer = CustomerModel(
        id: 'c1',
        ownerId: 'o1',
        name: 'Rahul Patil',
        phone: '9822112233',
        morningQuota: 1.0,
        eveningQuota: 0.0,
        milkRate: 60.0,
        joiningDate: DateTime(2026, 1, 1),
        currentBalance: 1800.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final testBill = MonthlyBillModel(
        id: 'b1',
        ownerId: 'o1',
        customerId: 'c1',
        customerName: 'Rahul Patil',
        customerPhone: '9822112233',
        yearMonth: '2026-10',
        month: 10,
        year: 2026,
        totalMilkLitres: 30.0,
        appliedRate: 60.0,
        currentMonthMilkCharges: 1800.0,
        previousBalance: 0.0,
        paidAmount: 0.0,
        finalPayable: 1800.0,
        status: 'UNPAID',
        createdAt: DateTime(2026, 10, 31),
        updatedAt: DateTime(2026, 10, 31),
      );

      final mrMessage = WhatsAppService.formatMarathiBillMessage(
        customer: testCustomer,
        bill: testBill,
        dairyName: 'Smart Dairy',
        ownerUpiId: 'owner@oksbi',
      );
      expect(mrMessage, contains('Rahul Patil'));
      expect(mrMessage, contains('Smart Dairy'));

      final enMessage = WhatsAppService.formatEnglishBillMessage(
        customer: testCustomer,
        bill: testBill,
        dairyName: 'Smart Dairy',
        ownerUpiId: 'owner@oksbi',
      );
      expect(enMessage, contains('Rahul Patil'));
      expect(enMessage, contains('Smart Dairy'));
    });
  });
}
