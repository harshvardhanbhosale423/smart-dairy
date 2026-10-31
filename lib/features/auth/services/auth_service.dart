import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../customers/models/customer_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  /// Login using Username or Mobile Number and Password
  Future<UserModel> loginWithUsernameAndPassword({
    required String identifier,
    required String password,
  }) async {
    await _ensureFirebaseAuth();

    final cleanId = identifier.trim().toLowerCase();
    final cleanPhone = identifier.trim().replaceAll(RegExp(r'\D'), '');

    QuerySnapshot<Map<String, dynamic>> snapshot;

    // 1. Try querying by username
    snapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: cleanId)
        .limit(1)
        .get();

    // 2. If not found and identifier contains phone digits, search by phone
    if (snapshot.docs.isEmpty && cleanPhone.isNotEmpty) {
      var phoneQuery = cleanPhone;
      if (phoneQuery.length > 10) {
        phoneQuery = phoneQuery.substring(phoneQuery.length - 10);
      }
      snapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phoneQuery)
          .limit(1)
          .get();
    }

    if (snapshot.docs.isEmpty) {
      throw 'युझरनेम किंवा मोबाईल नंबर सापडला नाही! (User not found)';
    }

    final userDoc = snapshot.docs.first;
    final user = UserModel.fromMap(userDoc.data(), userDoc.id);

    // Verify Password
    if (user.password.trim() != password.trim()) {
      throw 'चुकीचा पासवर्ड! कृपया पुन्हा प्रयत्न करा. (Incorrect password)';
    }

    // Check Approval Status for Customers
    if (user.isCustomer) {
      if (user.isPending) {
        throw 'तुमचे खाते अद्याप डेअरी मालकाकडून मंजूर केलेले नाही. कृपया मालकांशी संपर्क साधा किंवा मंजुरीची वाट पहा.';
      }
      if (user.status == 'rejected') {
        throw 'डेअरी मालकांनी तुमचा अर्ज नाकारला आहे.';
      }
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

    // Check if username already taken
    final existingUser = await _firestore
        .collection('users')
        .where('username', isEqualTo: cleanUsername)
        .limit(1)
        .get();

    if (existingUser.docs.isNotEmpty) {
      throw 'हे युझरनेम आधीच वापरले आहे! कृपया दुसरे युझरनेम निवडा.';
    }

    final uid = _auth.currentUser?.uid ?? 'owner_${DateTime.now().millisecondsSinceEpoch}';
    final user = UserModel(
      uid: uid,
      phone: cleanPhone,
      username: cleanUsername,
      password: password.trim(),
      role: 'owner',
      status: 'approved',
      name: ownerName.trim(),
      dairyId: uid,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();

    // 1. User doc
    final userRef = _firestore.collection('users').doc(uid);
    batch.set(userRef, user.toMap());

    // 2. Dairy Profile doc
    final dairyRef = _firestore.collection('dairy_profiles').doc(uid);
    batch.set(dairyRef, {
      'ownerId': uid,
      'dairyName': dairyName.trim(),
      'ownerName': ownerName.trim(),
      'ownerPhone': cleanPhone,
      'ownerUpiId': upiId.trim(),
      'cowCount': cowCount,
      'defaultMilkRate': defaultMilkRate,
      'address': address.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Save session
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
    final existingUser = await _firestore
        .collection('users')
        .where('username', isEqualTo: cleanUsername)
        .limit(1)
        .get();

    if (existingUser.docs.isNotEmpty) {
      throw 'हे युझरनेम आधीच वापरले आहे! कृपया दुसरे युझरनेम निवडा.';
    }

    final uid = 'cust_reg_${DateTime.now().millisecondsSinceEpoch}';
    final user = UserModel(
      uid: uid,
      phone: cleanPhone,
      username: cleanUsername,
      password: password.trim(),
      role: 'customer',
      status: 'pending', // Requires Owner approval
      name: name.trim(),
      dairyId: dairyId,
      address: address.trim(),
      morningQuota: morningQuota,
      eveningQuota: eveningQuota,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(user.toMap());
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

    final custDocRef = _firestore.collection('customers').doc();
    final userDocRef = _firestore.collection('users').doc();

    final customerWithCredentials = customer.copyWith(
      id: custDocRef.id,
      userId: userDocRef.id,
      username: cleanUsername,
      password: password.trim(),
    );

    final user = UserModel(
      uid: userDocRef.id,
      phone: cleanPhone,
      username: cleanUsername,
      password: password.trim(),
      role: 'customer',
      status: 'approved',
      name: customer.name.trim(),
      dairyId: ownerId,
      customerId: custDocRef.id,
      morningQuota: customer.morningQuota,
      eveningQuota: customer.eveningQuota,
      address: customer.address,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(custDocRef, customerWithCredentials.toMap());
    batch.set(userDocRef, user.toMap());

    await batch.commit();
    return custDocRef.id;
  }

  /// Approve Self-Registered Customer by Dairy Owner
  Future<void> approveCustomer({
    required UserModel pendingUser,
    required double milkRate,
    double? morningQuota,
    double? eveningQuota,
  }) async {
    final custDocRef = _firestore.collection('customers').doc();

    final morning = morningQuota ?? pendingUser.morningQuota ?? 1.0;
    final evening = eveningQuota ?? pendingUser.eveningQuota ?? 1.0;

    final customer = CustomerModel(
      id: custDocRef.id,
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

    final batch = _firestore.batch();

    // 1. Create customer document
    batch.set(custDocRef, customer.toMap());

    // 2. Update user status to approved
    final userRef = _firestore.collection('users').doc(pendingUser.uid);
    batch.update(userRef, {
      'status': 'approved',
      'customerId': custDocRef.id,
      'morningQuota': morning,
      'eveningQuota': evening,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Reject Self-Registered Customer
  Future<void> rejectCustomer(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Restore saved session on app launch
  Future<UserModel?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString(_prefUserKey);
      if (uid == null) return null;

      await _ensureFirebaseAuth();
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        await prefs.remove(_prefUserKey);
        return null;
      }

      final user = UserModel.fromMap(doc.data()!, doc.id);
      if (user.isCustomer && !user.isApproved) {
        await prefs.remove(_prefUserKey);
        return null;
      }

      return user;
    } catch (_) {
      return null;
    }
  }

  /// Get current user profile by UID
  Future<UserModel?> getUserProfile(String uid) async {
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
    await _ensureFirebaseAuth();
    try {
      final snap = await _firestore.collection('dairy_profiles').get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {
      return [];
    }
  }

  /// Stream of Pending Approvals for an Owner
  Stream<List<UserModel>> streamPendingApprovals(String ownerId) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'customer')
        .where('dairyId', isEqualTo: ownerId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  /// Sign Out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefUserKey);
    try {
      await _auth.signOut();
    } catch (_) {}
  }
}
