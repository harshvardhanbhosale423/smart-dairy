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

  /// Add customer with atomic ledger opening balance and app user credentials
  Future<void> addCustomer(CustomerModel customer, {double openingBalance = 0.0}) async {
    final batch = _firestore.batch();
    final custRef = _firestore.collection('customers').doc(customer.id);

    final cleanUsername = (customer.username != null && customer.username!.isNotEmpty)
        ? customer.username!.trim().toLowerCase()
        : customer.phone.trim();
    final cleanPassword = (customer.password != null && customer.password!.isNotEmpty)
        ? customer.password!.trim()
        : '123456';

    final userId = customer.userId ?? 'cust_user_${customer.id}';

    final customerToSave = customer.copyWith(
      userId: userId,
      username: cleanUsername,
      password: cleanPassword,
    );

    final customerData = customerToSave.toMap();
    customerData['currentBalance'] = openingBalance;
    batch.set(custRef, customerData);

    // Create or link app user login document
    final userRef = _firestore.collection('users').doc(userId);
    batch.set(userRef, {
      'uid': userId,
      'phone': customer.phone.trim(),
      'username': cleanUsername,
      'password': cleanPassword,
      'role': 'customer',
      'status': 'approved',
      'name': customer.name.trim(),
      'dairyId': customer.ownerId,
      'customerId': customer.id,
      'morningQuota': customer.morningQuota,
      'eveningQuota': customer.eveningQuota,
      'address': customer.address.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // If there is an opening balance, create an initial Ledger entry for audit
    if (openingBalance != 0.0) {
      final ledgerRef = _firestore.collection('customer_ledgers').doc();
      batch.set(ledgerRef, {
        'id': ledgerRef.id,
        'ownerId': customer.ownerId,
        'customerId': customer.id,
        'customerName': customer.name,
        'customerPhone': customer.phone,
        'customerUserId': userId,
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
      'details': 'New customer added with credentials: ${customer.name} ($cleanUsername)',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Update customer details and user credentials
  Future<void> updateCustomer(CustomerModel customer) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('customers').doc(customer.id), customer.toMap());

    if (customer.userId != null) {
      final cleanUsername = (customer.username != null && customer.username!.isNotEmpty)
          ? customer.username!.trim().toLowerCase()
          : customer.phone.trim();

      final userUpdate = <String, dynamic>{
        'name': customer.name.trim(),
        'phone': customer.phone.trim(),
        'username': cleanUsername,
        'morningQuota': customer.morningQuota,
        'eveningQuota': customer.eveningQuota,
        'address': customer.address.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (customer.password != null && customer.password!.isNotEmpty) {
        userUpdate['password'] = customer.password!.trim();
      }

      batch.update(_firestore.collection('users').doc(customer.userId), userUpdate);
    }

    await batch.commit();
  }

  /// Change customer status (active, paused, inactive)
  Future<void> updateCustomerStatus(String customerId, String newStatus) async {
    await _firestore
        .collection('customers')
        .doc(customerId)
        .update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Delete customer
  Future<void> deleteCustomer(String customerId, [String? ownerId]) async {
    await _firestore.collection('customers').doc(customerId).delete();
  }
}
