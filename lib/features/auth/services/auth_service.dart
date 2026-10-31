import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../customers/models/customer_model.dart';
import '../../../core/utils/security_helper.dart';
import '../../../core/services/local_database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService();

  static const String _prefUserKey = 'logged_in_uid';

  User? get currentFirebaseUser => _auth.currentUser;

  /// Ensure an anonymous Firebase Auth session exists so Firestore rules allow reads/writes
  Future<void> _ensureFirebaseAuth() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (_) {}
  }

  /// Login using Username or Mobile Number and Password with 5-attempt rate limiting
  Future<UserModel> loginWithUsernameAndPassword({
    required String identifier,
    required String password,
  }) async {
    await _ensureFirebaseAuth();

    final cleanId = identifier.trim().toLowerCase();
    final cleanPhone = identifier.trim().replaceAll(RegExp(r'\D'), '');

    // 1. Check if identifier/device is locked out
    final lockout = await SecurityHelper.checkLockout(cleanId);
    if (lockout.isLocked) {
      throw 'सुरक्षिततेसाठी हे खाते १५ मिनिटांसाठी लॉक करण्यात आले आहे. कृपया ${lockout.formattedRemainingTime} नंतर पुन्हा प्रयत्न करा.';
    }

    Map<String, dynamic>? userMap;
    String? userDocId;

    // 2. Query Local Database first (works 100% offline, immune to permission denied)
    final localUsers = _localDb.query('users', where: (u) {
      final uName = (u['username'] ?? '').toString().trim().toLowerCase();
      final uPhone = (u['phone'] ?? '').toString().trim();
      return uName == cleanId || (cleanPhone.isNotEmpty && uPhone.endsWith(cleanPhone));
    });

    if (localUsers.isNotEmpty) {
      userMap = localUsers.first;
      userDocId = (userMap['uid'] ?? userMap['id'] ?? '').toString();
    } else {
      // 3. Fallback to Cloud Firestore
      try {
        var snap = await _firestore
            .collection('users')
            .where('username', isEqualTo: cleanId)
            .limit(1)
            .get();

        if (snap.docs.isEmpty && cleanPhone.isNotEmpty) {
          var phoneQuery = cleanPhone;
          if (phoneQuery.length > 10) {
            phoneQuery = phoneQuery.substring(phoneQuery.length - 10);
          }
          snap = await _firestore
              .collection('users')
              .where('phone', isEqualTo: phoneQuery)
              .limit(1)
              .get();
        }

        if (snap.docs.isNotEmpty) {
          userDocId = snap.docs.first.id;
          userMap = snap.docs.first.data();
          await _localDb.set('users', userDocId, userMap);
        }
      } catch (e) {
        debugPrint('Firestore query note: $e');
      }
    }

    if (userMap == null || userDocId == null || userDocId.isEmpty) {
      final remaining = await SecurityHelper.recordFailedAttempt(cleanId);
      if (remaining == 0) {
        throw 'तुम्ही ५ वेळा चुकीची माहिती टाकली आहे! सुरक्षिततेसाठी हे खाते १५ मिनिटांसाठी लॉक करण्यात आले आहे.';
      }
      throw 'युझरनेम किंवा मोबाईल नंबर सापडला नाही! (शिल्लक प्रयत्न: $remaining/5)';
    }

    final user = UserModel.fromMap(userMap, userDocId);

    // 4. Verify Password (supports SHA-256 and legacy plain text)
    final isValid = SecurityHelper.verifyPassword(password, user.password);
    if (!isValid) {
      final remaining = await SecurityHelper.recordFailedAttempt(cleanId);
      if (remaining == 0) {
        throw 'तुम्ही सलग ५ वेळा चुकीचा पासवर्ड टाकला आहे! सुरक्षिततेसाठी हे खाते १५ मिनिटांसाठी लॉक करण्यात आले आहे.';
      }
      throw 'चुकीचा पासवर्ड! कृपया पुन्हा प्रयत्न करा. (शिल्लक प्रयत्न: $remaining/5)';
    }

    // 5. Check Approval Status for Customers
    if (user.isCustomer) {
      if (user.isPending) {
        throw 'तुमचे खाते अद्याप डेअरी मालकाकडून मंजूर केलेले नाही. कृपया मालकांशी संपर्क साधा किंवा मंजुरीची वाट पहा.';
      }
      if (user.status == 'rejected') {
        throw 'डेअरी मालकांनी तुमचा अर्ज नाकारला आहे.';
      }
    }

    // 6. Successful login: Reset attempt counter immediately
    await SecurityHelper.resetAttempts(cleanId);

    // Upgrade plain text password to SHA-256 hash locally & on cloud
    final hashed = SecurityHelper.hashPassword(password.trim());
    if (user.password.trim() == password.trim() && user.password != hashed) {
      await _localDb.update('users', user.uid, {'password': hashed});
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'password': hashed,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    // Save session in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefUserKey, user.uid);

    return user;
  }

  /// Register Owner Account
  Future<UserModel> registerOwner({
    required String username,
    required String password,
    required String phone,
    required String ownerName,
    required String dairyName,
    required String upiId,
    required String address,
    int cowCount = 5,
    double defaultMilkRate = 60.0,
  }) async {
    await _ensureFirebaseAuth();

    final cleanUsername = username.trim().toLowerCase();
    var cleanPhone = phone.trim().replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length > 10) cleanPhone = cleanPhone.substring(cleanPhone.length - 10);

    // Check if username already taken locally or on cloud
    final localExisting = _localDb.query('users', where: (u) => (u['username'] ?? '').toString().toLowerCase() == cleanUsername);
    if (localExisting.isNotEmpty) {
      throw 'हे युझरनेम आधीच वापरले आहे! कृपया दुसरे युझरनेम निवडा.';
    }

    final uid = _auth.currentUser?.uid ?? 'owner_${DateTime.now().millisecondsSinceEpoch}';
    final hashedPassword = SecurityHelper.hashPassword(password.trim());
    final user = UserModel(
      uid: uid,
      phone: cleanPhone,
      username: cleanUsername,
      password: hashedPassword,
      role: 'owner',
      status: 'approved',
      name: ownerName.trim(),
      dairyId: uid,
      createdAt: DateTime.now(),
    );

    final dairyProfile = {
      'id': uid,
      'ownerId': uid,
      'dairyName': dairyName.trim(),
      'ownerName': ownerName.trim(),
      'ownerPhone': cleanPhone,
      'ownerUpiId': upiId.trim(),
      'cowCount': cowCount,
      'defaultMilkRate': defaultMilkRate,
      'address': address.trim(),
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    // 1. Save to Local Database (immediate, 100% reliable)
    await _localDb.set('users', uid, user.toMap());
    await _localDb.set('dairy_profiles', uid, dairyProfile);

    // 2. Safe background cloud sync
    try {
      final batch = _firestore.batch();
      batch.set(_firestore.collection('users').doc(uid), user.toMap());
      batch.set(_firestore.collection('dairy_profiles').doc(uid), dairyProfile);
      await batch.commit();
    } catch (e) {
      debugPrint('Cloud sync note: $e');
    }

    // 3. Save session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefUserKey, uid);

    return user;
  }

  /// Customer Self-Registration (Pending Owner Approval)
  Future<UserModel> registerCustomerSelf({
    required String name,
    required String phone,
    required String username,
    required String password,
    required String address,
    required String dairyId,
    double morningQuota = 1.0,
    double eveningQuota = 1.0,
  }) async {
    await _ensureFirebaseAuth();

    final cleanUsername = username.trim().toLowerCase();
    var cleanPhone = phone.trim().replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length > 10) cleanPhone = cleanPhone.substring(cleanPhone.length - 10);

    // Check if username is taken
    final localExisting = _localDb.query('users', where: (u) => (u['username'] ?? '').toString().toLowerCase() == cleanUsername);
    if (localExisting.isNotEmpty) {
      throw 'हे युझरनेम आधीच वापरले आहे! कृपया दुसरे युझरनेम निवडा.';
    }

    final uid = 'cust_reg_${DateTime.now().millisecondsSinceEpoch}';
    final user = UserModel(
      uid: uid,
      phone: cleanPhone,
      username: cleanUsername,
      password: SecurityHelper.hashPassword(password.trim()),
      role: 'customer',
      status: 'pending', // Requires Owner approval
      name: name.trim(),
      dairyId: dairyId,
      address: address.trim(),
      morningQuota: morningQuota,
      eveningQuota: eveningQuota,
      createdAt: DateTime.now(),
    );

    // 1. Save locally
    await _localDb.set('users', uid, user.toMap());

    // 2. Safe background cloud sync
    try {
      await _firestore.collection('users').doc(uid).set(user.toMap());
    } catch (_) {}

    return user;
  }

  /// Create Customer Account with Credentials directly by Dairy Owner
  Future<String> createCustomerWithCredentials({
    required String ownerId,
    required CustomerModel customer,
    required String username,
    required String password,
  }) async {
    await _ensureFirebaseAuth();

    final cleanUsername = username.trim().toLowerCase();
    var cleanPhone = customer.phone.trim().replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length > 10) cleanPhone = cleanPhone.substring(cleanPhone.length - 10);

    final custId = 'cust_${DateTime.now().millisecondsSinceEpoch}';
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';

    final customerWithCredentials = customer.copyWith(
      id: custId,
      userId: userId,
      username: cleanUsername,
      password: password.trim(),
    );

    final user = UserModel(
      uid: userId,
      phone: cleanPhone,
      username: cleanUsername,
      password: SecurityHelper.hashPassword(password.trim()),
      role: 'customer',
      status: 'approved',
      name: customer.name.trim(),
      dairyId: ownerId,
      customerId: custId,
      morningQuota: customer.morningQuota,
      eveningQuota: customer.eveningQuota,
      address: customer.address,
      createdAt: DateTime.now(),
    );

    // 1. Save locally
    await _localDb.set('customers', custId, customerWithCredentials.toMap());
    await _localDb.set('users', userId, user.toMap());

    // 2. Cloud sync
    try {
      final batch = _firestore.batch();
      batch.set(_firestore.collection('customers').doc(custId), customerWithCredentials.toMap());
      batch.set(_firestore.collection('users').doc(userId), user.toMap());
      await batch.commit();
    } catch (_) {}

    return custId;
  }

  /// Approve Self-Registered Customer by Dairy Owner
  Future<void> approveCustomer({
    required UserModel pendingUser,
    required double milkRate,
    double? morningQuota,
    double? eveningQuota,
  }) async {
    final custId = 'cust_${DateTime.now().millisecondsSinceEpoch}';
    final morning = morningQuota ?? pendingUser.morningQuota ?? 1.0;
    final evening = eveningQuota ?? pendingUser.eveningQuota ?? 1.0;

    final customer = CustomerModel(
      id: custId,
      ownerId: pendingUser.dairyId ?? '',
      userId: pendingUser.uid,
      name: pendingUser.name ?? '',
      phone: pendingUser.phone,
      username: pendingUser.username,
      password: pendingUser.password,
      address: pendingUser.address ?? '',
      morningQuota: morning,
      eveningQuota: evening,
      milkRate: milkRate,
      joiningDate: DateTime.now(),
      status: 'active',
      currentBalance: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 1. Update locally
    await _localDb.set('customers', custId, customer.toMap());
    await _localDb.update('users', pendingUser.uid, {
      'status': 'approved',
      'customerId': custId,
      'morningQuota': morning,
      'eveningQuota': evening,
      'updatedAt': Timestamp.now(),
    });

    // 2. Cloud sync
    try {
      final batch = _firestore.batch();
      batch.set(_firestore.collection('customers').doc(custId), customer.toMap());
      batch.update(_firestore.collection('users').doc(pendingUser.uid), {
        'status': 'approved',
        'customerId': custId,
        'morningQuota': morning,
        'eveningQuota': evening,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } catch (_) {}
  }

  /// Reject Self-Registered Customer
  Future<void> rejectCustomer(String uid) async {
    await _localDb.update('users', uid, {
      'status': 'rejected',
      'updatedAt': Timestamp.now(),
    });

    try {
      await _firestore.collection('users').doc(uid).update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Stream pending approvals for dairy owner
  Stream<List<UserModel>> streamPendingApprovals(String ownerId) {
    return _localDb.stream('users', where: (u) {
      return (u['dairyId'] == ownerId || u['ownerId'] == ownerId) && u['status'] == 'pending';
    }).map((list) {
      return list.map((m) => UserModel.fromMap(m, (m['uid'] ?? m['id'] ?? '').toString())).toList();
    });
  }

  /// Restore saved session on app launch
  Future<UserModel?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString(_prefUserKey);
      if (uid == null) return null;

      final localData = _localDb.get('users', uid);
      if (localData != null) {
        final user = UserModel.fromMap(localData, uid);
        if (user.isCustomer && !user.isApproved) {
          await prefs.remove(_prefUserKey);
          return null;
        }
        return user;
      }

      // Try cloud fallback
      await _ensureFirebaseAuth();
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        await prefs.remove(_prefUserKey);
        return null;
      }

      final user = UserModel.fromMap(doc.data()!, doc.id);
      await _localDb.set('users', user.uid, user.toMap());
      return user;
    } catch (_) {
      return null;
    }
  }

  /// Get current user profile by UID
  Future<UserModel?> getUserProfile(String uid) async {
    final localData = _localDb.get('users', uid);
    if (localData != null) {
      return UserModel.fromMap(localData, uid);
    }
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  /// Get list of available dairy profiles
  Future<List<Map<String, dynamic>>> getAvailableDairies() async {
    final list = _localDb.getAll('dairy_profiles');
    if (list.isNotEmpty) return list;

    try {
      final snap = await _firestore.collection('dairy_profiles').get();
      final cloudList = snap.docs.map((d) => d.data()).toList();
      for (final item in cloudList) {
        if (item['id'] != null) {
          await _localDb.set('dairy_profiles', item['id'].toString(), item);
        }
      }
      return cloudList;
    } catch (_) {
      return list;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefUserKey);
      await _auth.signOut();
    } catch (_) {}
  }
}
