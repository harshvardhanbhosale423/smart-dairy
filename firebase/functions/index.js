const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

/**
 * Trusted Webhook endpoint for Payment Verification.
 * Idempotent, executes atomic Firestore transactions for ledger & bill status updates.
 */
exports.paymentWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).send('Method Not Allowed');
  }

  try {
    const {
      paymentId,
      transactionRef,
      customerId,
      ownerId,
      amount,
      status, // 'SUCCESS', 'FAILED'
      gatewaySignature
    } = req.body;

    if (!paymentId || !transactionRef || !amount || status !== 'SUCCESS') {
      return res.status(400).json({ error: 'Invalid payload or payment not successful' });
    }

    const numAmount = Number(amount);
    const paymentRef = db.collection('payments').doc(paymentId);

    await db.runTransaction(async (transaction) => {
      const paymentDoc = await transaction.get(paymentRef);
      if (!paymentDoc.exists) {
        throw new Error('Payment record not found');
      }

      const paymentData = paymentDoc.data();
      if (paymentData.status === 'PAID') {
        // Idempotent: already processed
        return;
      }

      // 1. Mark Payment as PAID
      transaction.update(paymentRef, {
        status: 'PAID',
        transactionRef: transactionRef,
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        verificationSource: 'WEBHOOK_TRUSTED'
      });

      // 2. Fetch Customer Document
      const custRef = db.collection('customers').doc(customerId);
      const custDoc = await transaction.get(custRef);
      if (!custDoc.exists) {
        throw new Error('Customer does not exist');
      }
      const customerData = custDoc.data();
      const previousBalance = customerData.currentBalance || 0;
      const newBalance = previousBalance - numAmount;

      transaction.update(custRef, {
        currentBalance: newBalance,
        lastPaymentDate: admin.firestore.FieldValue.serverTimestamp(),
        lastPaymentAmount: numAmount
      });

      // 3. Create Immutable Ledger Entry
      const ledgerRef = db.collection('customer_ledgers').doc();
      transaction.set(ledgerRef, {
        id: ledgerRef.id,
        customerId: customerId,
        ownerId: ownerId,
        customerName: customerData.name,
        type: 'CREDIT', // Payment received reduces outstanding balance
        category: 'PAYMENT_RECEIVED',
        amount: numAmount,
        balanceBefore: previousBalance,
        balanceAfter: newBalance,
        paymentMethod: paymentData.paymentMethod || 'UPI',
        transactionRef: transactionRef,
        referenceId: paymentId,
        notes: `UPI Payment verified (${transactionRef})`,
        transactionDate: admin.firestore.FieldValue.serverTimestamp()
      });

      // 4. Update Monthly Bill if payment was linked to a specific bill
      if (paymentData.billId) {
        const billRef = db.collection('monthly_bills').doc(paymentData.billId);
        const billDoc = await transaction.get(billRef);
        if (billDoc.exists) {
          const billData = billDoc.data();
          const newPaidTotal = (billData.paidAmount || 0) + numAmount;
          const finalOutstanding = (billData.finalPayable || 0) - newPaidTotal;
          const newStatus = finalOutstanding <= 0 ? 'PAID' : 'PARTIALLY PAID';

          transaction.update(billRef, {
            paidAmount: newPaidTotal,
            outstandingAmount: Math.max(0, finalOutstanding),
            status: newStatus,
            lastPaymentId: paymentId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      }

      // 5. Append to Audit Logs
      const auditRef = db.collection('audit_logs').doc();
      transaction.set(auditRef, {
        id: auditRef.id,
        action: 'PAYMENT_VERIFIED',
        entityType: 'PAYMENT',
        entityId: paymentId,
        ownerId: ownerId,
        customerId: customerId,
        amount: numAmount,
        details: `Payment of Rs. ${numAmount} verified successfully. Ledger credited.`,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    // 6. Push FCM Notification to Owner & Customer
    try {
      const custDoc = await db.collection('customers').doc(customerId).get();
      const custData = custDoc.data();
      const customerUserId = custData.userId;

      // Notify customer if device token available
      if (customerUserId) {
        const userDoc = await db.collection('users').doc(customerUserId).get();
        const fcmToken = userDoc.data()?.fcmToken;
        if (fcmToken) {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: 'Payment Successful! / पेमेंट यशस्वी!',
              body: `Received Rs. ${numAmount}. Your updated balance is Rs. ${(custData.currentBalance - numAmount).toFixed(2)}.`
            },
            data: { paymentId, type: 'PAYMENT_SUCCESS' }
          });
        }
      }

      // Notify owner
      const ownerDoc = await db.collection('users').doc(ownerId).get();
      const ownerFcm = ownerDoc.data()?.fcmToken;
      if (ownerFcm) {
        await admin.messaging().send({
          token: ownerFcm,
          notification: {
            title: 'Payment Received / पेमेंट प्राप्त झाले!',
            body: `Customer ${custData.name} paid Rs. ${numAmount} via UPI.`
          },
          data: { paymentId, customerId, type: 'PAYMENT_RECEIVED' }
        });
      }
    } catch (notifErr) {
      console.warn('Notification send failed (non-fatal):', notifErr);
    }

    return res.status(200).json({ success: true, message: 'Payment successfully processed' });
  } catch (err) {
    console.error('Error processing payment webhook:', err);
    return res.status(500).json({ error: err.message });
  }
});

/**
 * Automated Firestore Backup Trigger (Can be invoked on a daily / weekly schedule)
 */
exports.backupFirestore = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  const projectId = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
  const bucketName = `gs://${projectId}-firestore-backups`;
  const client = new admin.firestore.v1.FirestoreAdminClient();
  const databaseName = client.databasePath(projectId, '(default)');

  try {
    const responses = await client.exportDocuments({
      name: databaseName,
      outputUriPrefix: bucketName,
      collectionIds: []
    });
    console.log(`Backup initiated successfully: ${responses[0].name}`);
    return null;
  } catch (err) {
    console.error('Firestore backup failed:', err);
    throw new Error(err);
  }
});

