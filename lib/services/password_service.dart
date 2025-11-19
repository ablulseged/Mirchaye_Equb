import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PasswordService {
  PasswordService._internal();
  static final PasswordService _instance = PasswordService._internal();
  factory PasswordService() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _keySalt = 'password_salt';
  static const _keyHash = 'password_hash';

  Future<bool> hasPassword() async {
    final h = await _storage.read(key: _keyHash);
    return h != null;
  }

  /// Set a new password. Stores a random salt and the SHA256(salt + password) hash.
  Future<void> setPassword(String password) async {
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    await _storage.write(key: _keySalt, value: base64Encode(salt));
    await _storage.write(key: _keyHash, value: hash);
  }

  /// Validate a password against stored hash
  Future<bool> validatePassword(String password) async {
    final saltB64 = await _storage.read(key: _keySalt);
    final hashStored = await _storage.read(key: _keyHash);
    if (saltB64 == null || hashStored == null) return false;
    final salt = base64Decode(saltB64);
    final hash = _hashPassword(password, salt);
    return hash == hashStored;
  }

  Future<void> clearPassword() async {
    await _storage.delete(key: _keySalt);
    await _storage.delete(key: _keyHash);
  }

  // Helpers
  List<int> _generateSalt([int length = 16]) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  String _hashPassword(String password, List<int> salt) {
    final bytes = <int>[]
      ..addAll(salt)
      ..addAll(utf8.encode(password));
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
