import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PaymentLocalStore {
  static const String _key = 'local_payments_v1';

  static Future<void> addPayment(Map<String, dynamic> payment) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? <String>[];
    final updated = List<String>.from(existing)..insert(0, jsonEncode(payment));
    await prefs.setStringList(_key, updated);
  }

  static Future<List<Map<String, dynamic>>> getPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? <String>[];
    return existing.map<Map<String, dynamic>>((e) {
      try {
        return (jsonDecode(e) as Map<String, dynamic>);
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((m) => m.isNotEmpty).toList(growable: false);
  }
}


