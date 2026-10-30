import '../models/monthly_bill_model.dart';
import '../../customers/models/customer_model.dart';
import '../../milk_entry/models/milk_entry_model.dart';
import '../../payments/models/payment_model.dart';

class BillingEngine {
  /// Calculate monthly bill according to exact specification:
  /// Total Milk Amount = Sum(Daily Milk Quantity × Rate)
  /// Final Bill = Previous Balance + Current Month Charges - Payments Received
  static MonthlyBillModel calculateCustomerMonthlyBill({
    required String billId,
    required CustomerModel customer,
    required int year,
    required int month,
    required List<MilkEntryModel> monthMilkEntries,
    required List<PaymentModel> monthPayments,
    required double previousOutstandingBalance,
  }) {
    // 1. Calculate total milk delivered and total charges
    double totalLitres = 0.0;
    double currentCharges = 0.0;

    for (final entry in monthMilkEntries) {
      totalLitres += entry.totalQty;
      currentCharges += entry.totalAmount;
    }

    // 2. Sum payments made during this billing period
    double totalPaidInMonth = 0.0;
    for (final p in monthPayments) {
      if (p.isPaid) {
        totalPaidInMonth += p.amount;
      }
    }

    // 3. Billing formula
    // Final Outstanding = Previous Balance + Current Month Milk Charges - Payments Received
    final netPayable = previousOutstandingBalance + currentCharges - totalPaidInMonth;

    // 4. Determine status
    String status;
    if (netPayable <= 0) {
      status = 'PAID';
    } else if (totalPaidInMonth > 0) {
      status = 'PARTIALLY PAID';
    } else {
      status = 'UNPAID';
    }

    final ym = '$year-${month.toString().padLeft(2, '0')}';
    final now = DateTime.now();

    return MonthlyBillModel(
      id: billId,
      ownerId: customer.ownerId,
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      customerUserId: customer.userId,
      yearMonth: ym,
      month: month,
      year: year,
      totalMilkLitres: totalLitres,
      appliedRate: customer.milkRate,
      currentMonthMilkCharges: currentCharges,
      previousBalance: previousOutstandingBalance,
      paidAmount: totalPaidInMonth,
      finalPayable: netPayable > 0 ? netPayable : 0.0,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }
}

