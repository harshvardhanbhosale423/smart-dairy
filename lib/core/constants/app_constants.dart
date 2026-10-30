class AppConstants {
  static const String appName = 'Smart Dairy';
  static const String appTaglineEn = 'Milk & Account Management System';
  static const String appTaglineMr = 'दूध आणि हिशोब व्यवस्थापन प्रणाली';

  // User Roles
  static const String roleOwner = 'owner';
  static const String roleCustomer = 'customer';

  // Customer Status
  static const String statusActive = 'active';
  static const String statusPaused = 'paused';
  static const String statusInactive = 'inactive';

  // Payment Status
  static const String paymentPaid = 'PAID';
  static const String paymentUnpaid = 'UNPAID';
  static const String paymentPartial = 'PARTIALLY PAID';
  static const String paymentPending = 'PENDING';
  static const String paymentFailed = 'FAILED';

  // Payment Methods
  static const String methodUpi = 'UPI';
  static const String methodCash = 'CASH';
  static const String methodBankTransfer = 'BANK_TRANSFER';

  // Ledger Entry Types
  static const String ledgerDebit = 'DEBIT'; // Customer owes money (Milk delivered, bill generated)
  static const String ledgerCredit = 'CREDIT'; // Customer pays money (Payment received, advance)

  // Expense Categories
  static const List<String> expenseCategories = [
    'cow_feed', // पशुआहार
    'green_fodder', // हिरवा चारा
    'dry_fodder', // सुका चारा
    'veterinary', // पशुवैद्यकीय तपासणी
    'medicines', // औषधोपचार
    'transportation', // वाहतूक खर्च
    'electricity', // वीज बिल
    'equipment', // उपकरणे व भांडी
    'other', // इतर खर्च
  ];

  // Default values
  static const double defaultMilkRate = 60.0;
  static const int otpTimeoutSeconds = 60;
  static const int defaultCowCount = 5;
}

