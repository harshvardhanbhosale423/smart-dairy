import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../../settings/models/dairy_settings_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _verificationId;
  int? _resendToken;

  User? get currentFirebaseUser => _auth.currentUser;

  /// Send OTP to user's mobile number
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMessage) onError,
    required Function(PhoneAuthCredential credential) onAutoVerify,
  }) async {
    // Format to E.164 (India +91)
    var formattedPhone = phoneNumber.trim().replaceAll(RegExp(r'\D'), '');
    if (formattedPhone.length == 10) {
      formattedPhone = '+91$formattedPhone';
    } else if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+$formattedPhone';
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          onAutoVerify(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Authentication failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Verify OTP code submitted by user
  Future<UserCredential> verifyOtp({
    required String smsCode,
    String? verificationId,
  }) async {
    final effectiveVerificationId = verificationId ?? _verificationId;
    if (effectiveVerificationId == null) {
      throw Exception('Verification ID is missing. Request a new OTP.');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: effectiveVerificationId,
      smsCode: smsCode.trim(),
    );

    return await _auth.signInWithCredential(credential);
  }

  /// Get current user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  /// Check if a customer phone number is pre-registered by the dairy owner
  Future<Map<String, dynamic>?> findCustomerByPhone(String phone) async {
    var cleanPhone = phone.trim().replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length > 10) {
      cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
    }

    final snapshot = await _firestore
        .collection('customers')
        .where('phone', isEqualTo: cleanPhone)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return {'id': doc.id, ...doc.data()};
    }
    return null;
  }

  /// Register Owner Profile
  Future<void> registerOwner({
    required String uid,
    required String phone,
    required String ownerName,
    required String dairyName,
    required String upiId,
    required String address,
    int cowCount = 5,
    double defaultMilkRate = 60.0,
  }) async {
    final batch = _firestore.batch();

    // 1. User doc
    final userRef = _firestore.collection('users').doc(uid);
    batch.set(userRef, {
      'uid': uid,
      'phone': phone,
      'name': ownerName,
      'role': 'owner',
      'dairyId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Dairy Profile doc
    final dairyRef = _firestore.collection('dairy_profiles').doc(uid);
    batch.set(dairyRef, {
      'ownerId': uid,
      'dairyName': dairyName,
      'ownerName': ownerName,
      'ownerPhone': phone,
      'ownerUpiId': upiId,
      'cowCount': cowCount,
      'defaultMilkRate': defaultMilkRate,
      'address': address,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Register or Link Customer Profile
  Future<void> linkCustomerUser({
    required String uid,
    required String phone,
    required String customerId,
    required String customerName,
  }) async {
    final batch = _firestore.batch();

    // 1. User doc
    final userRef = _firestore.collection('users').doc(uid);
    batch.set(userRef, {
      'uid': uid,
      'phone': phone,
      'name': customerName,
      'role': 'customer',
      'customerId': customerId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Link UID into customers collection
    final custRef = _firestore.collection('customers').doc(customerId);
    batch.update(custRef, {
      'userId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

