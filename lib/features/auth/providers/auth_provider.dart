import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../settings/models/dairy_settings_model.dart';

enum AuthStatus { unauthenticated, authenticating, codeSent, authenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.unauthenticated;
  UserModel? _currentUser;
  DairySettingsModel? _dairySettings;
  String? _verificationId;
  String? _phoneNumber;
  String? _errorMessage;
  int _resendTimer = 60;
  Timer? _countdownTimer;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  DairySettingsModel? get dairySettings => _dairySettings;
  String? get verificationId => _verificationId;
  String? get phoneNumber => _phoneNumber;
  String? get errorMessage => _errorMessage;
  int get resendTimer => _resendTimer;
  bool get canResendOtp => _resendTimer == 0;
  bool get isOwner => _currentUser?.isOwner ?? false;
  bool get isCustomer => _currentUser?.isCustomer ?? false;

  AuthProvider() {
    _initCurrentUser();
  }

  Future<void> _initCurrentUser() async {
    final fbUser = _authService.currentFirebaseUser;
    if (fbUser != null) {
      _status = AuthStatus.authenticating;
      notifyListeners();
      _currentUser = await _authService.getUserProfile(fbUser.uid);
      _status = _currentUser != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Request OTP
  Future<bool> sendOtp(String phone) async {
    _status = AuthStatus.authenticating;
    _phoneNumber = phone;
    _errorMessage = null;
    notifyListeners();

    final completer = Completer<bool>();

    await _authService.sendOtp(
      phoneNumber: phone,
      onCodeSent: (vId) {
        _verificationId = vId;
        _status = AuthStatus.codeSent;
        _startTimer();
        notifyListeners();
        completer.complete(true);
      },
      onError: (msg) {
        _errorMessage = msg;
        _status = AuthStatus.error;
        notifyListeners();
        completer.complete(false);
      },
      onAutoVerify: (credential) async {
        try {
          final result = await FirebaseAuth.instance.signInWithCredential(credential);
          if (result.user != null) {
            _currentUser = await _authService.getUserProfile(result.user!.uid);
            _status = AuthStatus.authenticated;
            notifyListeners();
          }
        } catch (_) {}
      },
    );

    return completer.future;
  }

  /// Verify OTP
  Future<bool> verifyOtp(String code) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.verifyOtp(smsCode: code, verificationId: _verificationId);
      if (credential.user != null) {
        _currentUser = await _authService.getUserProfile(credential.user!.uid);
        _status = AuthStatus.authenticated;
        _stopTimer();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Register Owner
  Future<bool> registerOwner({
    required String ownerName,
    required String dairyName,
    required String upiId,
    required String address,
    int cowCount = 5,
    double defaultMilkRate = 60.0,
  }) async {
    final fbUser = _authService.currentFirebaseUser;
    if (fbUser == null) return false;

    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      await _authService.registerOwner(
        uid: fbUser.uid,
        phone: fbUser.phoneNumber ?? _phoneNumber ?? '',
        ownerName: ownerName,
        dairyName: dairyName,
        upiId: upiId,
        address: address,
        cowCount: cowCount,
        defaultMilkRate: defaultMilkRate,
      );

      _currentUser = await _authService.getUserProfile(fbUser.uid);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Link Customer Account
  Future<bool> linkCustomer({
    required String customerId,
    required String customerName,
  }) async {
    final fbUser = _authService.currentFirebaseUser;
    if (fbUser == null) return false;

    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      await _authService.linkCustomerUser(
        uid: fbUser.uid,
        phone: fbUser.phoneNumber ?? _phoneNumber ?? '',
        customerId: customerId,
        customerName: customerName,
      );

      _currentUser = await _authService.getUserProfile(fbUser.uid);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Check if phone number is registered by owner
  Future<Map<String, dynamic>?> checkCustomerPreRegistered(String phone) async {
    return await _authService.findCustomerByPhone(phone);
  }

  void _startTimer() {
    _resendTimer = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        _resendTimer--;
        notifyListeners();
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
  }

  Future<void> logout() async {
    await _authService.signOut();
    _currentUser = null;
    _dairySettings = null;
    _status = AuthStatus.unauthenticated;
    _stopTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}

