# Database Schema & Data Dictionary
**Smart Dairy – Cloud Firestore Data Architecture**

This document specifies the collections, subcollections, document fields, indexes, and validation constraints for the Smart Dairy database.

---

## Collections Overview

| Collection Name | Purpose | Primary Keys | Read Access | Write Access |
|---|---|---|---|---|
| `users` | User accounts & roles | Firebase Auth `uid` | Authenticated | Owner / Self |
| `dairy_profiles` | Dairy farm settings & UPI | Owner `uid` | Authenticated | Dairy Owner |
| `customers` | Household customer records | UUID `customerId` | Owner + Respective Customer | Dairy Owner |
| `milk_entries` | Daily manual milk records | UUID `entryId` | Owner + Respective Customer | Dairy Owner |
| `customer_ledgers` | Immutable Khata audit trail | UUID `ledgerId` | Owner + Respective Customer | Dairy Owner / Cloud Functions |
| `monthly_bills` | Monthly statement invoices | `bill_{customerId}_{YYYY-MM}` | Owner + Respective Customer | Dairy Owner |
| `payments` | Customer payment records | UUID `paymentId` | Owner + Respective Customer | Owner / Webhook / Customer (Pending only) |
| `expenses` | Dairy business expenses | UUID `expenseId` | Dairy Owner | Dairy Owner |
| `audit_logs` | Immutable system event log | UUID `logId` | Dairy Owner | System Append-Only |
| `app_settings` | System-wide metadata | Key identifier | Authenticated | Dairy Owner |

---

## Detailed Data Dictionary

### 1. `users` Collection
* **Document ID:** Firebase Auth `uid`
```json
{
  "uid": "String (Auth UID)",
  "phone": "String (+91XXXXXXXXXX)",
  "role": "String ('owner' | 'customer')",
  "name": "String (Full Name)",
  "dairyId": "String (Owner UID if owner)",
  "customerId": "String (Linked customer doc ID if customer)",
  "fcmToken": "String (Device push token)",
  "createdAt": "Timestamp"
}
```

### 2. `dairy_profiles` Collection
* **Document ID:** Owner `uid`
```json
{
  "ownerId": "String",
  "dairyName": "String (e.g. 'माऊली डेअरी फार्म')",
  "ownerName": "String",
  "ownerPhone": "String",
  "ownerUpiId": "String (e.g. '9822000000@okaxis')",
  "accountHolderName": "String",
  "cowCount": "Integer (e.g. 5)",
  "defaultMilkRate": "Double (e.g. 60.0)",
  "address": "String",
  "updatedAt": "Timestamp"
}
```

### 3. `customers` Collection
* **Document ID:** UUID `customerId`
```json
{
  "ownerId": "String",
  "userId": "String? (Linked Firebase UID if registered on app)",
  "name": "String (Customer Name)",
  "phone": "String (10-digit phone)",
  "address": "String",
  "morningQuota": "Double (Litres, default 1.0)",
  "eveningQuota": "Double (Litres, default 1.0)",
  "milkRate": "Double (₹/Litre, default 60.0)",
  "joiningDate": "Timestamp",
  "status": "String ('active' | 'paused' | 'inactive')",
  "currentBalance": "Double (Positive = Customer owes; Negative = Advance)",
  "notes": "String",
  "lastPaymentDate": "Timestamp?",
  "lastPaymentAmount": "Double?",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### 4. `milk_entries` Collection
* **Document ID:** UUID `entryId`
```json
{
  "ownerId": "String",
  "customerId": "String",
  "customerName": "String",
  "customerPhone": "String",
  "customerUserId": "String?",
  "date": "Timestamp (Midnight Normalized)",
  "morningQty": "Double (Litres)",
  "eveningQty": "Double (Litres)",
  "totalQty": "Double (morningQty + eveningQty)",
  "ratePerLitre": "Double (₹)",
  "totalAmount": "Double (totalQty * ratePerLitre)",
  "isZeroMilk": "Boolean (true if holiday/absent)",
  "notes": "String",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### 5. `customer_ledgers` Collection
* **Document ID:** UUID `ledgerId`
```json
{
  "id": "String",
  "ownerId": "String",
  "customerId": "String",
  "customerName": "String",
  "customerPhone": "String?",
  "customerUserId": "String?",
  "type": "String ('DEBIT' | 'CREDIT')",
  "category": "String ('DAILY_MILK' | 'MONTHLY_BILL' | 'PAYMENT_RECEIVED' | 'ADJUSTMENT' | 'OPENING_BALANCE')",
  "amount": "Double",
  "balanceBefore": "Double",
  "balanceAfter": "Double",
  "paymentMethod": "String? ('CASH' | 'UPI' | 'BANK_TRANSFER')",
  "transactionRef": "String?",
  "referenceId": "String? (Linked entry, bill, or payment ID)",
  "notes": "String",
  "transactionDate": "Timestamp"
}
```

### 6. `monthly_bills` Collection
* **Document ID:** `bill_{customerId}_{YYYY-MM}`
```json
{
  "id": "String",
  "ownerId": "String",
  "customerId": "String",
  "customerName": "String",
  "customerPhone": "String",
  "customerUserId": "String?",
  "yearMonth": "String (e.g. '2026-10')",
  "month": "Integer (1-12)",
  "year": "Integer",
  "totalMilkLitres": "Double",
  "appliedRate": "Double",
  "currentMonthMilkCharges": "Double (totalMilkLitres * appliedRate)",
  "previousBalance": "Double",
  "paidAmount": "Double",
  "finalPayable": "Double (previousBalance + currentCharges - paidAmount)",
  "status": "String ('PAID' | 'UNPAID' | 'PARTIALLY PAID')",
  "lastPaymentId": "String?",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### 7. `payments` Collection
* **Document ID:** UUID `paymentId`
```json
{
  "id": "String",
  "ownerId": "String",
  "customerId": "String",
  "customerName": "String",
  "customerPhone": "String",
  "customerUserId": "String?",
  "billId": "String?",
  "amount": "Double",
  "paymentMethod": "String ('UPI' | 'CASH' | 'BANK_TRANSFER')",
  "transactionRef": "String",
  "status": "String ('PAID' | 'PENDING' | 'FAILED')",
  "verifiedBy": "String ('OWNER_MANUAL' | 'OWNER_VERIFIED' | 'WEBHOOK_TRUSTED')",
  "notes": "String",
  "paymentDate": "Timestamp",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### 8. `expenses` Collection
* **Document ID:** UUID `expenseId`
```json
{
  "id": "String",
  "ownerId": "String",
  "category": "String ('cow_feed' | 'green_fodder' | 'dry_fodder' | 'veterinary' | 'medicines' | 'transportation' | 'electricity' | 'equipment' | 'other')",
  "amount": "Double",
  "description": "String",
  "paymentMethod": "String ('CASH' | 'UPI' | 'BANK')",
  "expenseDate": "Timestamp",
  "createdAt": "Timestamp"
}
```

### 9. `audit_logs` Collection (Strictly Append-Only)
* **Document ID:** UUID `logId`
```json
{
  "id": "String",
  "action": "String (e.g. 'MILK_ENTRY_DELETED', 'PAYMENT_RECORDED', 'CUSTOMER_CREATED')",
  "entityType": "String?",
  "entityId": "String?",
  "ownerId": "String",
  "customerId": "String?",
  "amount": "Double?",
  "details": "String",
  "timestamp": "Timestamp"
}
```

