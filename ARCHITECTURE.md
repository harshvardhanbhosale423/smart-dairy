# System Architecture & Technical Design Specification
**Smart Dairy – Milk & Account Management System**

This document describes the architectural principles, data flow, security model, and transaction handling implemented in the Smart Dairy application.

---

## 1. Architectural Style: Feature-First Modular Clean Architecture

The application is structured following a **Feature-First Clean Architecture** with **Provider** for state management and the **Repository Pattern** for decoupling business rules from data sources.

### Separation of Concerns:
```
UI Layer (Screens & Widgets)
          ↕ 
State Management (ChangeNotifier Providers)
          ↕
Domain / Repository Layer (Repositories & Calculation Engines)
          ↕
Data Sources (Cloud Firestore, Firebase Auth, Local Preferences, NPCI UPI)
```

1. **Core Layer (`lib/core/`):** Contains application-wide singletons, design tokens, theming, localization dictionaries, utility functions, and foundational services (UPI, PDF, WhatsApp, FCM).
2. **Feature Modules (`lib/features/`):** Each module contains its own:
   - `models/`: Immutable domain models with `fromMap()` and `toMap()` serializers.
   - `repositories/` / `services/`: Encapsulates Firestore transactions, queries, and business logic.
   - `providers/`: `ChangeNotifier` state controllers exposing reactive state to the UI.
   - `screens/` & `widgets/`: Pure presentation widgets adhering to Material Design 3.

---

## 2. Security Architecture & Role-Based Access Control (RBAC)

### Threat Model & Protections:
1. **Customer Data Isolation:**
   - Every Firestore document in `milk_entries`, `monthly_bills`, `payments`, and `customer_ledgers` contains `ownerId`, `customerId`, and `customerUserId`.
   - Firestore security rules strictly prohibit customers from querying or reading documents where `customerId != request.auth.uid` or `customerPhone != request.auth.token.phone_number`.
2. **Immutable Audit Trail:**
   - Deletions in `audit_logs` and `customer_ledgers` are blocked at the Firestore security rule level (`allow delete: if false`).
   - If an owner edits or deletes a daily milk entry, a new audit entry is recorded, and the running ledger balance is recalculated via atomic Firestore transaction.
3. **Tamper-Proof Payment Verification:**
   - Customers can create payment documents only in `PENDING` state.
   - Only the authenticated owner or trusted Cloud Function webhooks can transition payment status to `PAID`.
   - Customers cannot mark bills as paid or edit their own ledger.
4. **App Check & Rate Limiting:**
   - Firebase App Check protects Firestore and Cloud Functions endpoints from spoofed requests and API abuse.

---

## 3. Financial Logic & Accounting Engine

### Accrual Sales vs. Cash Accounting:
Local dairy owners often struggle to distinguish between milk delivered on credit (billed sales) and actual cash received. Smart Dairy explicitly computes both:
- **Billed Milk Sales:** Total monetary value of all milk delivered during the period.
- **Actual Cash Collections:** Realized cash and verified UPI received during the period.
- **Net Cash Profit:**
  $$\text{Net Cash Profit} = \text{Actual Cash Collections} - \text{Total Dairy Expenses}$$
- **Net Billed Profit:**
  $$\text{Net Billed Profit} = \text{Billed Milk Sales} - \text{Total Dairy Expenses}$$

### Running Ledger (Digital Khata):
The ledger follows a double-entry inspired single-account format:
- **Debit Entry (`DEBIT`):** Increases customer outstanding balance (e.g., daily milk delivery, bill generation).
- **Credit Entry (`CREDIT`):** Decreases customer outstanding balance (e.g., payment received, discount).
- **Balance Invariant:**
  $$\text{Balance}_{\text{after}} = \text{Balance}_{\text{before}} + \Delta_{\text{debit}} - \Delta_{\text{credit}}$$
  - $\text{Balance} > 0$: Customer owes money to dairy owner.
  - $\text{Balance} < 0$: Customer has paid advance money.
  - $\text{Balance} = 0$: Account fully settled.

---

## 4. Payment Integration & UPI Protocol

### NPCI UPI Intent Specification:
Payments use the official National Payments Corporation of India (NPCI) URI schema:
```
upi://pay?pa={UPI_ID}&pn={NAME}&am={AMOUNT}&tn={NOTE}&cu=INR
```
- Deep links target specific payment apps:
  - Google Pay: `tez://upi/pay?...`
  - PhonePe: `phonepe://pay?...`
  - Paytm: `paytmmp://pay?...`
  - BHIM: `bhim://pay?...`
  - Fallback: System UPI chooser (`upi://pay?...`)

### Dynamic QR Code Generation:
- Powered by `qr_flutter` on mobile screen and `pdf.Barcode.qrCode()` in printable PDF bills.
- Encodes the exact payable amount and bill reference for error-free scanning.

---

## 5. Offline Tolerance & Data Integrity
- Firestore local caching enables owners to enter daily milk even in areas with poor rural connectivity. Writes are queued locally and synchronized automatically when network returns.
- Critical multi-collection updates (e.g. Milk Entry + Customer Balance + Ledger + Audit Log) always execute inside `db.runTransaction()` to guarantee all-or-nothing atomicity.

