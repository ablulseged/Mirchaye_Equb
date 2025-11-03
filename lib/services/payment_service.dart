import 'package:flutter/foundation.dart';

class PaymentService {
  PaymentService._internal();
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;

  // Chapa public key (test)
  // Replace with live key in production and secure appropriately
  static const String chapaPublicKey =
      'CHAPUBK_TEST-J40WxxVupDcrgqjDin7FnzASlNT6GCkc';

  bool get isUsingTestKeys => chapaPublicKey.contains('_TEST-');
}


