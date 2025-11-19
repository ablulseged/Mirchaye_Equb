import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  BiometricService._internal();
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _keyEnabled = 'biometric_enabled';
  static const _keyCredEmail = 'biometric_cred_email';
  static const _keyCredPassword = 'biometric_cred_password';

  /// Returns whether device supports biometric auth and has enrolled biometrics
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;

      final List<BiometricType> types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } on PlatformException catch (e) {
      if (kDebugMode) print('Biometric availability check failed: $e');
      return false;
    }
  }

  /// Attempt biometric authentication; returns true on success
  Future<bool> authenticate({String reason = 'Authenticate'}) async {
    try {
      // First try biometric-only authentication
      try {
        final bool didAuthenticate = await _auth.authenticate(
          localizedReason: reason,
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
        if (didAuthenticate) return true;
      } catch (e) {
        // ignore and try fallback below
        if (kDebugMode)
          print('Biometric-only auth failed, will try device credential: $e');
      }

      // If biometric-only failed or returned false, try allowing device credential fallback
      final bool didAuthenticateFallback = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return didAuthenticateFallback;
    } on PlatformException catch (e) {
      if (kDebugMode) print('Biometric auth failed: $e');
      return false;
    }
  }

  /// Persist user's biometric enabled preference in secure storage
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyEnabled, value: enabled ? '1' : '0');
  }

  /// Returns stored preference (defaults to false)
  Future<bool> getBiometricEnabled() async {
    final v = await _storage.read(key: _keyEnabled);
    return v == '1';
  }

  /// Store user credentials securely on-device. These are used to sign in
  /// after a successful biometric unlock. NOTE: This stores credentials
  /// only on the device (flutter_secure_storage) and does not upload them
  /// to any server or to Firebase.
  Future<void> storeCredentials({
    required String email,
    required String password,
  }) async {
    await _storage.write(key: _keyCredEmail, value: email);
    await _storage.write(key: _keyCredPassword, value: password);
  }

  /// Returns stored credentials or null when none exist
  Future<Map<String, String>?> getStoredCredentials() async {
    final email = await _storage.read(key: _keyCredEmail);
    final password = await _storage.read(key: _keyCredPassword);
    if (email == null || password == null) return null;
    return {'email': email, 'password': password};
  }

  /// Clears stored credentials from device secure storage
  Future<void> clearStoredCredentials() async {
    await _storage.delete(key: _keyCredEmail);
    await _storage.delete(key: _keyCredPassword);
  }
}
