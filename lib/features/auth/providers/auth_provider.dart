import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../customers/models/customer_model.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.unauthenticated;
  UserModel? _currentUser;
  String? _errorMessage;
  List<UserModel> _pendingApprovals = [];
  StreamSubscription<List<UserModel>>? _approvalsSubscription;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  List<UserModel> get pendingApprovals => _pendingApprovals;
  int get pendingApprovalsCount => _pendingApprovals.length;
  bool get isOwner => _currentUser?.isOwner ?? false;
  bool get isCustomer => _currentUser?.isCustomer ?? false;

  AuthProvider() {
    restoreSession();
  }

  @override
  void dispose() {
    _approvalsSubscription?.cancel();
    super.dispose();
  }

  /// Restore saved session
  Future<void> restoreSession() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      _currentUser = await _authService.restoreSession();
      if (_currentUser != null) {
        _status = AuthStatus.authenticated;
        if (_currentUser!.isOwner) {
          _listenToPendingApprovals(_currentUser!.uid);
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Listen to pending customer approvals for Dairy Owner
  void _listenToPendingApprovals(String ownerId) {
    _approvalsSubscription?.cancel();
    _approvalsSubscription = _authService.streamPendingApprovals(ownerId).listen((list) {
      _pendingApprovals = list;
      notifyListeners();
    });
  }

  /// Login with Username or Phone & Password
  Future<bool> login(String identifier, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.loginWithUsernameAndPassword(
        identifier: identifier,
        password: password,
      );
      _status = AuthStatus.authenticated;
      if (_currentUser!.isOwner) {
        _listenToPendingApprovals(_currentUser!.uid);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Register Owner
  Future<bool> registerOwner({
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
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.registerOwner(
        username: username,
        password: password,
        phone: phone,
        ownerName: ownerName,
        dairyName: dairyName,
        upiId: upiId,
        address: address,
        cowCount: cowCount,
        defaultMilkRate: defaultMilkRate,
      );
      _status = AuthStatus.authenticated;
      _listenToPendingApprovals(_currentUser!.uid);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Self-Register Customer
  Future<bool> registerCustomerSelf({
    required String name,
    required String phone,
    required String username,
    required String password,
    required String address,
    required String dairyId,
    double morningQuota = 1.0,
    double eveningQuota = 1.0,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.registerCustomerSelf(
        name: name,
        phone: phone,
        username: username,
        password: password,
        address: address,
        dairyId: dairyId,
        morningQuota: morningQuota,
        eveningQuota: eveningQuota,
      );
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Approve Pending Customer (By Owner)
  Future<bool> approveCustomer({
    required UserModel pendingUser,
    required double milkRate,
    double? morningQuota,
    double? eveningQuota,
  }) async {
    try {
      await _authService.approveCustomer(
        pendingUser: pendingUser,
        milkRate: milkRate,
        morningQuota: morningQuota,
        eveningQuota: eveningQuota,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Reject Pending Customer (By Owner)
  Future<bool> rejectCustomer(String uid) async {
    try {
      await _authService.rejectCustomer(uid);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Owner creates customer with login credentials directly
  Future<String> createCustomerWithCredentials({
    required CustomerModel customer,
    required String username,
    required String password,
  }) async {
    if (_currentUser == null) throw 'Not logged in';
    return await _authService.createCustomerWithCredentials(
      ownerId: _currentUser!.uid,
      customer: customer,
      username: username,
      password: password,
    );
  }

  /// Get list of all dairies for customer registration dropdown
  Future<List<Map<String, dynamic>>> getAvailableDairies() async {
    return await _authService.getAvailableDairies();
  }

  /// Sign Out
  Future<void> signOut() async {
    _approvalsSubscription?.cancel();
    await _authService.signOut();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _pendingApprovals = [];
    notifyListeners();
  }
}
