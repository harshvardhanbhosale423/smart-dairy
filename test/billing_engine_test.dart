import 'package:flutter_test/flutter_test.dart';
import 'package:smart_dairy/features/billing/models/monthly_bill_model.dart';
import 'package:smart_dairy/features/billing/services/billing_engine.dart';
import 'package:smart_dairy/features/customers/models/customer_model.dart';
import 'package:smart_dairy/features/milk_entry/models/milk_entry_model.dart';
import 'package:smart_dairy/features/payments/models/payment_model.dart';

void main() {
  group('BillingEngine Calculations', () {
    late CustomerModel testCustomer;

    setUp(() {
      testCustomer = CustomerModel(
        id: 'cust_rahul_1',
        ownerId: 'owner_123',
        name: 'Rahul Patil',
        phone: '9822112233',
        morningQuota: 1.0,
        eveningQuota: 1.0,
        milkRate: 60.0,
        joiningDate: DateTime(2026, 1, 1),
        currentBalance: 200.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('Prompt Example: Rahul Patil (30 days x 1L+1L = 60L @ Rs.60 = Rs.3600 or custom entries)', () {
      // Suppose Rahul took 30 Litres in total: 1L morning, 0L evening for 30 days
      final entries = List.generate(30, (i) {
        return MilkEntryModel.create(
          id: 'entry_$i',
          ownerId: 'owner_123',
          customerId: testCustomer.id,
          customerName: testCustomer.name,
          customerPhone: testCustomer.phone,
          date: DateTime(2026, 10, i + 1),
          morningQty: 1.0,
          eveningQty: 0.0,
          ratePerLitre: 60.0,
        );
      });

      // Total milk = 30L @ 60 = 1800
      // Previous Balance = 200
      // Payment received = 1500
      // Total Payable = 200 + 1800 - 1500 = 500
      final payments = [
        PaymentModel(
          id: 'pay_1',
          ownerId: 'owner_123',
          customerId: testCustomer.id,
          customerName: testCustomer.name,
          customerPhone: testCustomer.phone,
          amount: 1500.0,
          paymentMethod: 'UPI',
          transactionRef: 'UPI-TEST-123',
          status: 'PAID',
          verifiedBy: 'OWNER_MANUAL',
          paymentDate: DateTime(2026, 10, 15),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final bill = BillingEngine.calculateCustomerMonthlyBill(
        billId: 'bill_oct_2026',
        customer: testCustomer,
        year: 2026,
        month: 10,
        monthMilkEntries: entries,
        monthPayments: payments,
        previousOutstandingBalance: 200.0,
      );

      expect(bill.totalMilkLitres, 30.0);
      expect(bill.currentMonthMilkCharges, 1800.0);
      expect(bill.previousBalance, 200.0);
      expect(bill.paidAmount, 1500.0);
      expect(bill.finalPayable, 500.0);
      expect(bill.status, 'PARTIALLY PAID');
    });

    test('Full Payment marks bill as PAID', () {
      final entries = [
        MilkEntryModel.create(
          id: 'e1',
          ownerId: 'owner_123',
          customerId: testCustomer.id,
          customerName: testCustomer.name,
          customerPhone: testCustomer.phone,
          date: DateTime(2026, 10, 1),
          morningQty: 10.0,
          eveningQty: 0.0,
          ratePerLitre: 60.0,
        ),
      ];

      final payments = [
        PaymentModel(
          id: 'pay_full',
          ownerId: 'owner_123',
          customerId: testCustomer.id,
          customerName: testCustomer.name,
          customerPhone: testCustomer.phone,
          amount: 600.0,
          paymentMethod: 'CASH',
          transactionRef: 'CASH-123',
          status: 'PAID',
          verifiedBy: 'OWNER_MANUAL',
          paymentDate: DateTime(2026, 10, 2),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final bill = BillingEngine.calculateCustomerMonthlyBill(
        billId: 'bill_paid',
        customer: testCustomer,
        year: 2026,
        month: 10,
        monthMilkEntries: entries,
        monthPayments: payments,
        previousOutstandingBalance: 0.0,
      );

      expect(bill.finalPayable, 0.0);
      expect(bill.status, 'PAID');
    });

    test('Zero payment marks bill as UNPAID', () {
      final entries = [
        MilkEntryModel.create(
          id: 'e1',
          ownerId: 'owner_123',
          customerId: testCustomer.id,
          customerName: testCustomer.name,
          customerPhone: testCustomer.phone,
          date: DateTime(2026, 10, 1),
          morningQty: 5.0,
          eveningQty: 5.0,
          ratePerLitre: 60.0,
        ),
      ];

      final bill = BillingEngine.calculateCustomerMonthlyBill(
        billId: 'bill_unpaid',
        customer: testCustomer,
        year: 2026,
        month: 10,
        monthMilkEntries: entries,
        monthPayments: [],
        previousOutstandingBalance: 100.0,
      );

      // Charges: 10L * 60 = 600 + Prev 100 = 700
      expect(bill.currentMonthMilkCharges, 600.0);
      expect(bill.finalPayable, 700.0);
      expect(bill.status, 'UNPAID');
    });
  });
}

