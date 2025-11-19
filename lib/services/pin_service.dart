import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  PinService._internal();
  static final PinService _instance = PinService._internal();
  factory PinService() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _keySalt = 'pin_salt';
  static const _keyHash = 'pin_hash';

  Future<bool> hasPin() async {
    final h = await _storage.read(key: _keyHash);
    return h != null;
  }

  /// Set a new PIN. Stores a random salt and the SHA256(salt + pin) hash.
  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _keySalt, value: base64Encode(salt));
    await _storage.write(key: _keyHash, value: hash);
  }

  /// Validate a PIN against stored hash
  Future<bool> validatePin(String pin) async {
    final saltB64 = await _storage.read(key: _keySalt);
    final hashStored = await _storage.read(key: _keyHash);
    if (saltB64 == null || hashStored == null) return false;
    final salt = base64Decode(saltB64);
    final hash = _hashPin(pin, salt);
    return hash == hashStored;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _keySalt);
    await _storage.delete(key: _keyHash);
  }

  // Helpers
  List<int> _generateSalt([int length = 16]) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  String _hashPin(String pin, List<int> salt) {
    final bytes = <int>[]
      ..addAll(salt)
      ..addAll(utf8.encode(pin));
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
