# Smart Dairy – Milk & Account Management System 🐄🥛
**स्मार्ट डेअरी – दूध आणि हिशोब व्यवस्थापन प्रणाली**

A complete, modern, professional, secure, and user-friendly Android mobile application built with Flutter & Firebase, designed specifically for small dairy business owners (~5 cows, personal household milk distribution) and their household customers.

---

## 🌟 Key Features

### 1. Two Dedicated Roles with OTP Login
* **Dairy Owner:** Complete operational control over customers, manual daily milk distribution, billing, expenses, payments, and financial profit & loss reports.
* **Customer:** Transparent view of their daily morning & evening milk records, monthly bills, ledger balance, payment receipts, and 1-click UPI payments.
* **Strict Data Isolation:** Customers can **never** access another customer's data or modify milk/billing records.

### 2. Manual Daily Milk Entry System (दैनिक दूध नोंद)
* Manual entry only (no accidental auto-fills).
* Date selector with day-by-day navigation & calendar picker.
* Morning and Evening milk quantities in Litres.
* Customer milk rate (₹/Litre) & instant daily amount calculation.
* Zero Milk / Delivery Holiday / Missed delivery flags.
* Duplicate entry protection & complete audit log.
* **Quick Daily Batch Entry mode:** Update all active customers in seconds.

### 3. Digital Customer Ledger (डिजिटल खतावणी / Khata System)
* Running ledger for every customer.
* Tracks:
  * Previous / Opening Balance
  * Daily Milk Deliveries (Debit)
  * Payments Received (Credit via UPI / Cash)
  * Advance Payments
  * Outstanding Due Balance
* Account adjustment tool with reason notes.
* Immutable audit trail for every transaction.

### 4. Automatic Monthly Billing (मासिक दूध बिल)
* Precise specification formula:
  $$\text{Final Bill} = \text{Previous Balance} + \sum(\text{Daily Milk} \times \text{Rate}) - \text{Payments Received}$$
* Statuses: `PAID`, `UNPAID`, `PARTIALLY PAID`.
* 1-Click "Auto-Generate All Bills" for the month.
* No duplicate monthly bills.
* Professional printable PDF bill generation with embedded dynamic UPI QR Code.

### 5. Secure UPI Payments & Direct Bank Inflow
* Customer payments go **directly** to the dairy owner's bank account.
* **Dynamic UPI QR Code** generation (`upi://pay?pa=...&pn=...&am=...&tn=...&cu=INR`).
* 1-Tap UPI app launch for **Google Pay, PhonePe, Paytm, and BHIM UPI**.
* **Zero Trust Verification:** Unverified screenshots or manual claims are never trusted blindly. Owners approve pending payments or trusted Cloud Functions verify webhooks before crediting the ledger.
* Never collects or stores customer UPI PINs.

### 6. WhatsApp Bill Sharing (व्हॉट्सअ‍ॅपवर बिल पाठवा)
* Pre-formatted messages with customer name, litres, rate, charges, previous dues, payments, and owner UPI ID.
* Native Marathi and English message templates.
* PDF bill attachment sharing via standard system sheet.

### 7. Dairy Expense Management (गोठा खर्च नोंद)
* Categories: Cow Feed (पशुआहार), Green Fodder (हिरवा चारा), Dry Fodder (सुका चारा), Veterinary (डॉक्टर फी), Medicines (औषधे), Transportation (डिझेल/वाहतूक), Electricity (वीज बिल), Equipment, and Other.
* Monthly expense breakdown and total tracking.

### 8. Business Profit & Loss Analytics (नफा-तोटा अहवाल)
* Distinguishes **Billed Milk Sales** from **Actual Cash Collected** (Accrual vs Cash accounting).
* Net Cash Profit = Cash Collected - Total Dairy Expenses.
* Interactive financial bar charts (`fl_chart`).
* Exportable business summary.

### 9. Premium Visual Identity & Localization
* **Visual Theme:** Dark Dairy Green (`#14532D`), Fresh Light Green (`#22C55E`), Soft Cream (`#FAF7F2`), and Golden Yellow (`#F59E0B`).
* **Dual Language:** Full Marathi (मराठी) and English support with 1-tap language switch.
* **Themes:** Light Mode and Dark Mode.

---

## 🏗 Tech Stack

| Layer | Technology |
|---|---|
| **Frontend Framework** | Flutter (Dart 3), Material Design 3 |
| **State Management** | Provider |
| **Backend & Auth** | Firebase Authentication (Phone OTP) |
| **Database** | Cloud Firestore with atomic transactions & batch writes |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **Cloud Storage** | Firebase Storage |
| **Security & Rules** | Firestore Security Rules & Firebase App Check |
| **Charts** | `fl_chart` |
| **QR Code Engine** | `qr_flutter` |
| **PDF Generation** | `pdf` & `printing` |
| **Payment Protocol** | NPCI UPI Deep Links (`upi://pay`) & Webhooks |

---

## 📁 Project Architecture

```
my_dairy_app/
├── android/                   # Native Android manifest, Gradle & permissions
├── assets/                    # Icons, cow & dairy illustrations
├── firebase/
│   ├── firestore.rules        # Role-based Firestore security rules
│   ├── storage.rules          # Storage rules
│   ├── firestore.indexes.json # Composite query indexes
│   └── functions/             # Cloud Functions for webhooks & daily backups
├── lib/
│   ├── main.dart              # MultiProvider setup & root navigation
│   ├── firebase_options.dart  # Firebase platform configuration
│   ├── core/
│   │   ├── constants/         # Colors, typography, constants
│   │   ├── localization/      # English & Marathi dictionaries & providers
│   │   ├── services/          # UPI, WhatsApp, PDF & Notification services
│   │   ├── theme/             # Light & Dark dairy green theme
│   │   ├── utils/             # Currency, date & validator utils
│   │   └── widgets/           # Buttons, text fields, cards & dialogs
│   └── features/
│       ├── auth/              # Phone login, OTP, registration & role gates
│       ├── owner_dashboard/   # 8 financial cards, quick actions & charts
│       ├── customers/         # Customer CRUD, quotas & ledger shortcuts
│       ├── milk_entry/        # Manual daily entry & batch entry
│       ├── ledger/            # Digital Khata & immutable audit log
│       ├── billing/           # Automatic billing engine & bill details
│       ├── payments/          # UPI Intent, QR, receipts & verification
│       ├── expenses/          # Feed, fodder, medicines & vet expenses
│       ├── reports/           # Business analytics & profit/loss
│       ├── customer_dashboard/# Customer portal (My Milk, Bills, Pay Now)
│       └── settings/          # Dairy profile, UPI config, language & theme
└── test/                      # Unit tests for billing, ledger, milk & UPI
```

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (`>= 3.0.0`)
* Android Studio / VS Code
* Firebase Project with Phone Auth and Firestore enabled

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/smart-dairy.git
   cd smart-dairy
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run unit tests to verify business logic:
   ```bash
   flutter test
   ```
4. Run on an Android device or emulator:
   ```bash
   flutter run
   ```

---

## 🔒 Security & Privacy Notice
* Sensitive data such as customer UPI PINs or banking credentials are **never** collected or stored.
* Database access is governed strictly by `firestore.rules` enforcing that customers cannot alter milk records or payment states.

