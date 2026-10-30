import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of all customers for an owner
  Stream<List<CustomerModel>> getCustomersStream(String ownerId) {
    return _firestore
        .collection('customers')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => CustomerModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          return list;
        });
  }

  /// Get single customer
  Future<CustomerModel?> getCustomer(String customerId) async {
    final doc = await _firestore.collection('customers').doc(customerId).get();
    if (!doc.exists || doc.data() == null) return null;
    return CustomerModel.fromMap(doc.data()!, doc.id);
  }

  /// Add customer with atomic ledger opening balance
  Future<void> addCustomer(CustomerModel customer, {double openingBalance = 0.0}) async {
    final batch = _firestore.batch();
    final custRef = _firestore.collection('customers').doc(customer.id);

    final customerData = customer.toMap();
    customerData['currentBalance'] = openingBalance;
    batch.set(custRef, customerData);

    // If there is an opening balance, create an initial Ledger entry for audit
    if (openingBalance != 0.0) {
      final ledgerRef = _firestore.collection('customer_ledgers').doc();
      batch.set(ledgerRef, {
        'id': ledgerRef.id,
        'ownerId': customer.ownerId,
        'customerId': customer.id,
        'customerName': customer.name,
        'customerPhone': customer.phone,
        'customerUserId': customer.userId,
        'type': openingBalance > 0 ? 'DEBIT' : 'CREDIT',
        'category': 'OPENING_BALANCE',
        'amount': openingBalance.abs(),
        'balanceBefore': 0.0,
        'balanceAfter': openingBalance,
        'notes': 'Initial account opening balance',
        'transactionDate': FieldValue.serverTimestamp(),
      });
    }

    // Append to audit log
    final auditRef = _firestore.collection('audit_logs').doc();
    batch.set(auditRef, {
      'id': auditRef.id,
      'action': 'CUSTOMER_CREATED',
      'ownerId': customer.ownerId,
      'customerId': customer.id,
      'details': 'New customer added: ${customer.name} (${customer.phone})',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Update customer details
  Future<void> updateCustomer(CustomerModel customer) async {
    await _firestore
        .collection('customers')
        .doc(customer.id)
        .update(customer.toMap());
  }

  /// Change customer status (active, paused, inactive)
  Future<void> updateCustomerStatus(String customerId, String status) async {
    await _firestore.collection('customers').doc(customerId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete customer (soft delete or deactivate)
  Future<void> deleteCustomer(String customerId, String ownerId) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('customers').doc(customerId), {
      'status': 'inactive',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final auditRef = _firestore.collection('audit_logs').doc();
    batch.set(auditRef, {
      'id': auditRef.id,
      'action': 'CUSTOMER_DEACTIVATED',
      'ownerId': ownerId,
      'customerId': customerId,
      'details': 'Customer deactivated',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}

