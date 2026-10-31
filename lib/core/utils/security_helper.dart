import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockoutStatus {
  final bool isLocked;
  final int remainingSeconds;
  final int remainingAttempts;

  const LockoutStatus({
    required this.isLocked,
    required this.remainingSeconds,
    required this.remainingAttempts,
  });

  String get formattedRemainingTime {
    final minutes = (remainingSeconds / 60).floor();
    final seconds = remainingSeconds % 60;
    if (minutes > 0) {
      return '$minutes मि. $seconds सेकंद';
    }
    return '$seconds सेकंद';
  }
}

class SecurityHelper {
  static const String _salt = 'smart_dairy_salt_v1_secure_2026';
  static const int maxAttempts = 5;
  static const int lockoutMinutes = 15;

  /// Hash password using SHA-256 with application salt
  static String hashPassword(String password) {
    final bytes = utf8.encode('$_salt:$password');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify entered password against stored password
  /// Handles both SHA-256 hashed passwords and legacy plain-text passwords
  static bool verifyPassword(String enteredPassword, String storedPassword) {
    final enteredClean = enteredPassword.trim();
    final storedClean = storedPassword.trim();

    // 1. Direct match (plain-text legacy)
    if (enteredClean == storedClean) {
      return true;
    }

    // 2. SHA-256 hashed match
    final hashed = hashPassword(enteredClean);
    if (hashed == storedClean) {
      return true;
    }

    return false;
  }

  /// Format an identifier key for SharedPreferences
  static String _cleanKey(String identifier) {
    return identifier.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  /// Check current lockout status for an identifier or general device
  static Future<LockoutStatus> checkLockout(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cleanKey(identifier);
    final now = DateTime.now().millisecondsSinceEpoch;

    final lockedUntil = prefs.getInt('lockout_until_$key') ?? 0;
    final attempts = prefs.getInt('attempts_$key') ?? 0;

    if (lockedUntil > now) {
      final remainingSeconds = ((lockedUntil - now) / 1000).ceil();
      return LockoutStatus(
        isLocked: true,
        remainingSeconds: remainingSeconds > 0 ? remainingSeconds : 0,
        remainingAttempts: 0,
      );
    }

    // Lockout expired or never locked
    if (lockedUntil != 0 && lockedUntil <= now) {
      // Clear expired lockout
      await prefs.remove('lockout_until_$key');
      await prefs.remove('attempts_$key');
      return const LockoutStatus(
        isLocked: false,
        remainingSeconds: 0,
        remainingAttempts: maxAttempts,
      );
    }

    final remaining = maxAttempts - attempts;
    return LockoutStatus(
      isLocked: false,
      remainingSeconds: 0,
      remainingAttempts: remaining > 0 ? remaining : 0,
    );
  }

  /// Record a failed login attempt. Returns remaining attempts.
  /// If attempts reach 5, locks the account for 15 minutes.
  static Future<int> recordFailedAttempt(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cleanKey(identifier);
    final now = DateTime.now().millisecondsSinceEpoch;

    int currentAttempts = (prefs.getInt('attempts_$key') ?? 0) + 1;
    await prefs.setInt('attempts_$key', currentAttempts);

    if (currentAttempts >= maxAttempts) {
      final lockoutEndTime = now + (lockoutMinutes * 60 * 1000);
      await prefs.setInt('lockout_until_$key', lockoutEndTime);
      return 0;
    }

    return maxAttempts - currentAttempts;
  }

  /// Reset attempts on successful login
  static Future<void> resetAttempts(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cleanKey(identifier);
    await prefs.remove('attempts_$key');
    await prefs.remove('lockout_until_$key');
  }
}
