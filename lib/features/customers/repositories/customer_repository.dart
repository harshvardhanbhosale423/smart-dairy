import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import '../../../core/services/local_database_service.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService();

  /// Stream of all customers for an owner
  Stream<List<CustomerModel>> getCustomersStream(String ownerId) {
    return _localDb.stream('customers', where: (c) => c['ownerId'] == ownerId).map((list) {
      final customers = list.map((doc) => CustomerModel.fromMap(doc, (doc['id'] ?? '').toString())).toList();
      customers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return customers;
    });
  }

  /// Get single customer
  Future<CustomerModel?> getCustomer(String customerId) async {
    final doc = _localDb.get('customers', customerId);
    if (doc != null) {
      return CustomerModel.fromMap(doc, customerId);
    }
    try {
      final snap = await _firestore.collection('customers').doc(customerId).get();
      if (!snap.exists || snap.data() == null) return null;
      final c = CustomerModel.fromMap(snap.data()!, snap.id);
      await _localDb.set('customers', c.id, snap.data()!);
      return c;
    } catch (_) {
      return null;
    }
  }

  /// Add customer with atomic ledger opening balance and app user credentials
  Future<void> addCustomer(CustomerModel customer, {double openingBalance = 0.0}) async {
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

    final userData = {
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
      'createdAt': Timestamp.now(),
    };

    // 1. Save to local offline database
    await _localDb.set('customers', customer.id, customerData);
    await _localDb.set('users', userId, userData);

    if (openingBalance != 0.0) {
      final ledgerId = 'ledger_${DateTime.now().millisecondsSinceEpoch}';
      await _localDb.set('customer_ledgers', ledgerId, {
        'id': ledgerId,
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
        'transactionDate': Timestamp.now(),
      });
    }

    // 2. Safe background cloud sync
    try {
      final batch = _firestore.batch();
      batch.set(_firestore.collection('customers').doc(customer.id), customerData);
      batch.set(_firestore.collection('users').doc(userId), userData);
      await batch.commit();
    } catch (_) {}
  }

  /// Update customer details and user credentials
  Future<void> updateCustomer(CustomerModel customer) async {
    final cleanUsername = (customer.username != null && customer.username!.isNotEmpty)
        ? customer.username!.trim().toLowerCase()
        : customer.phone.trim();

    // 1. Update locally
    await _localDb.update('customers', customer.id, customer.toMap());

    if (customer.userId != null) {
      final userUpdate = <String, dynamic>{
        'name': customer.name.trim(),
        'phone': customer.phone.trim(),
        'username': cleanUsername,
        'morningQuota': customer.morningQuota,
        'eveningQuota': customer.eveningQuota,
        'address': customer.address.trim(),
        'updatedAt': Timestamp.now(),
      };
      if (customer.password != null && customer.password!.isNotEmpty) {
        userUpdate['password'] = customer.password!.trim();
      }
      await _localDb.update('users', customer.userId!, userUpdate);
    }

    // 2. Safe background cloud sync
    try {
      final batch = _firestore.batch();
      batch.update(_firestore.collection('customers').doc(customer.id), customer.toMap());
      if (customer.userId != null) {
        batch.update(_firestore.collection('users').doc(customer.userId), {
          'name': customer.name.trim(),
          'phone': customer.phone.trim(),
          'username': cleanUsername,
          'morningQuota': customer.morningQuota,
          'eveningQuota': customer.eveningQuota,
          'address': customer.address.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Change customer status (active, paused, inactive)
  Future<void> updateCustomerStatus(String customerId, String newStatus) async {
    await _localDb.update('customers', customerId, {
      'status': newStatus,
      'updatedAt': Timestamp.now(),
    });

    try {
      await _firestore.collection('customers').doc(customerId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Delete customer
  Future<void> deleteCustomer(String customerId, [String? ownerId]) async {
    await _localDb.delete('customers', customerId);

    try {
      await _firestore.collection('customers').doc(customerId).delete();
    } catch (_) {}
  }
}
