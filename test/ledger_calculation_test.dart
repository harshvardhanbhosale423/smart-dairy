import 'package:flutter_test/flutter_test.dart';
import 'package:smart_dairy/features/ledger/models/ledger_entry_model.dart';

void main() {
  group('Digital Khata Ledger Calculations', () {
    test('Calculates running balance across debit (milk) and credit (payment) transactions', () {
      double runningBalance = 0.0; // Initial opening balance

      // 1. Day 1: 2 Litres Milk @ Rs.60 = Rs.120 (Debit)
      final debit1 = LedgerEntryModel(
        id: 'l1',
        ownerId: 'o1',
        customerId: 'c1',
        customerName: 'Rahul Patil',
        type: 'DEBIT',
        category: 'DAILY_MILK',
        amount: 120.0,
        balanceBefore: runningBalance,
        balanceAfter: runningBalance + 120.0,
        transactionDate: DateTime(2026, 10, 1),
      );
      runningBalance = debit1.balanceAfter;
      expect(runningBalance, 120.0);

      // 2. Day 2: 2 Litres Milk @ Rs.60 = Rs.120 (Debit)
      final debit2 = LedgerEntryModel(
        id: 'l2',
        ownerId: 'o1',
        customerId: 'c1',
        customerName: 'Rahul Patil',
        type: 'DEBIT',
        category: 'DAILY_MILK',
        amount: 120.0,
        balanceBefore: runningBalance,
        balanceAfter: runningBalance + 120.0,
        transactionDate: DateTime(2026, 10, 2),
      );
      runningBalance = debit2.balanceAfter;
      expect(runningBalance, 240.0);

      // 3. Payment Received: Rs.200 (Credit)
      final credit1 = LedgerEntryModel(
        id: 'l3',
        ownerId: 'o1',
        customerId: 'c1',
        customerName: 'Rahul Patil',
        type: 'CREDIT',
        category: 'PAYMENT_RECEIVED',
        amount: 200.0,
        balanceBefore: runningBalance,
        balanceAfter: runningBalance - 200.0,
        transactionDate: DateTime(2026, 10, 3),
      );
      runningBalance = credit1.balanceAfter;
      expect(runningBalance, 40.0); // 240 - 200 = 40 remaining due
    });

    test('Advance payment results in negative ledger balance (credit)', () {
      double runningBalance = 0.0;

      // Customer pays Rs. 500 advance
      final advanceCredit = LedgerEntryModel(
        id: 'l_adv',
        ownerId: 'o1',
        customerId: 'c1',
        customerName: 'Rahul Patil',
        type: 'CREDIT',
        category: 'PAYMENT_RECEIVED',
        amount: 500.0,
        balanceBefore: runningBalance,
        balanceAfter: runningBalance - 500.0,
        transactionDate: DateTime(2026, 10, 1),
      );

      runningBalance = advanceCredit.balanceAfter;
      expect(runningBalance, -500.0); // Negative indicates advance paid by customer
    });
  });
}

