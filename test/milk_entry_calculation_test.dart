import 'package:flutter_test/flutter_test.dart';
import 'package:smart_dairy/features/milk_entry/models/milk_entry_model.dart';

void main() {
  group('Daily Milk Entry Calculations', () {
    test('Calculates morning + evening milk total and amount correctly', () {
      // Customer: Rahul Patil
      // Morning Milk: 1 Litre
      // Evening Milk: 1 Litre
      // Total Milk: 2 Litres
      // Rate: Rs.60/Litre -> Amount: Rs.120
      final entry = MilkEntryModel.create(
        id: 'entry_test_1',
        ownerId: 'owner_1',
        customerId: 'cust_1',
        customerName: 'Rahul Patil',
        customerPhone: '9822112233',
        date: DateTime(2026, 10, 15),
        morningQty: 1.0,
        eveningQty: 1.0,
        ratePerLitre: 60.0,
      );

      expect(entry.morningQty, 1.0);
      expect(entry.eveningQty, 1.0);
      expect(entry.totalQty, 2.0);
      expect(entry.ratePerLitre, 60.0);
      expect(entry.totalAmount, 120.0);
      expect(entry.isZeroMilk, false);
    });

    test('Zero milk entry / delivery holiday sets total to 0L and amount to Rs.0', () {
      final entry = MilkEntryModel.create(
        id: 'entry_test_zero',
        ownerId: 'owner_1',
        customerId: 'cust_1',
        customerName: 'Rahul Patil',
        customerPhone: '9822112233',
        date: DateTime(2026, 10, 16),
        morningQty: 2.0,
        eveningQty: 2.0,
        ratePerLitre: 60.0,
        isZeroMilk: true,
        notes: 'Holiday / Absent',
      );

      expect(entry.totalQty, 0.0);
      expect(entry.totalAmount, 0.0);
      expect(entry.isZeroMilk, true);
    });

    test('Extra milk delivery calculations with half litres (e.g. 2.5L morning + 1.5L evening = 4.0L @ Rs.65 = Rs.260)', () {
      final entry = MilkEntryModel.create(
        id: 'entry_test_extra',
        ownerId: 'owner_1',
        customerId: 'cust_2',
        customerName: 'Suresh Shinde',
        customerPhone: '9822445566',
        date: DateTime(2026, 10, 17),
        morningQty: 2.5,
        eveningQty: 1.5,
        ratePerLitre: 65.0,
        notes: 'Festival extra milk',
      );

      expect(entry.totalQty, 4.0);
      expect(entry.totalAmount, 260.0);
    });
  });
}

