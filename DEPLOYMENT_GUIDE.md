# Deployment & Operations Guide
**Smart Dairy – Production Setup, Firebase Configuration & APK Build**

This guide provides end-to-end instructions for configuring Firebase, deploying backend rules and Cloud Functions, building the production Android APK, and executing automated database backups.

---

## 1. Firebase Project Setup

### Step 1.1: Create Firebase Project
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Create a new project named **`smart-dairy-app`**.
3. Enable Google Analytics (recommended).

### Step 1.2: Enable Authentication
1. In Firebase Console, navigate to **Build > Authentication > Sign-in method**.
2. Enable **Phone** provider.
3. Add your dairy owner testing phone numbers and test verification codes under **Phone numbers for testing** (e.g., `+91 98221 12233` with OTP `123456`) to test without consuming SMS quotas.

### Step 1.3: Enable Cloud Firestore
1. Navigate to **Build > Firestore Database**.
2. Click **Create database** in **Production mode**.
3. Select your closest Google Cloud region (e.g., `asia-south1` for Mumbai, India).

### Step 1.4: Enable Firebase Cloud Messaging (FCM)
1. Navigate to **Project Settings > Cloud Messaging**.
2. Ensure the Cloud Messaging API is enabled to support push notifications for bills and payment confirmations.

---

## 2. Deploying Security Rules & Cloud Functions

### Step 2.1: Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

### Step 2.2: Initialize and Select Project
```bash
firebase use smart-dairy-app
```

### Step 2.3: Deploy Firestore Rules & Indexes
```bash
# Deploys firestore.rules and composite indexes
firebase deploy --only firestore
```

### Step 2.4: Deploy Firebase Cloud Functions
```bash
cd firebase/functions
npm install
firebase deploy --only functions
```
The deployed functions include:
- `paymentWebhook`: Trusted server-side webhook endpoint for automated payment gateway notifications.
- `backupFirestore`: Automated daily scheduled backup export to Google Cloud Storage.

---

## 3. Android Production Release Build

### Step 3.1: Generate Release Keystore
Generate a 2048-bit RSA upload key using Java's `keytool`:
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

### Step 3.2: Configure `android/key.properties`
Create `android/key.properties` (do not commit this file to public git):
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=upload
storeFile=upload-keystore.jks
```

### Step 3.3: Build Signed Release APK
```bash
# Install dependencies
flutter pub get

# Run test suite
flutter test

# Build optimized release APK
flutter build apk --release --split-per-abi
```
The generated APKs will be located at:
`build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### Step 3.4: Build Google Play App Bundle (AAB)
```bash
flutter build appbundle --release
```
The bundle will be generated at:
`build/app/outputs/bundle/release/app-release.aab`

---

## 4. Automated Daily Database Backups

Cloud Firestore supports scheduled managed export operations:
1. Create a dedicated Google Cloud Storage bucket:
   ```bash
   gcloud storage buckets create gs://smart-dairy-app-backups --location=asia-south1
   ```
2. The Cloud Function in `firebase/functions/index.js` runs automatically every 24 hours (`0 0 * * *`) to export all Firestore collections to the backup bucket.
3. To execute an immediate manual backup:
   ```bash
   gcloud firestore export gs://smart-dairy-app-backups/manual-backup-$(date +%Y%m%d)
   ```

---

## 5. Production Verification Checklist

| Check | Description | Status |
|---|---|---|
| 📱 **Phone Auth** | Validated OTP delivery and fallback for rural connectivity | Verified |
| 🛡 **RBAC Rules** | Customers strictly blocked from viewing other customers' data or modifying records | Verified |
| 🥛 **Manual Milk Entry** | Prevents auto-fills, calculates morning + evening total and daily amount | Verified |
| 📖 **Digital Khata** | Double-entry inspired balance tracking with immutable audit trail | Verified |
| 🧾 **Billing Formula** | Total Milk × Rate + Prev Due - Paid = Final Payable | Verified |
| 💳 **UPI Verification** | Dynamic QR & UPI intent direct to owner; Zero trust for unverified claims | Verified |
| 💬 **WhatsApp Bill** | Formatted Marathi & English templates with PDF invoice | Verified |
| 📊 **P&L Reports** | Accrual sales vs. cash collections; Net cash profit = cash in - expenses | Verified |

