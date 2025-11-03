import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  UserService._internal();
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<void> ensureUserDocument() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = _userDoc(user.uid);
    final snapshot = await doc.get();
    if (!snapshot.exists) {
      await doc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'phone': user.phoneNumber,
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      // Return an empty stream if no user is logged in
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }
    return _userDoc(user.uid).snapshots();
  }

  Future<void> updateProfile({
    String? displayName,
    String? phone,
    String? university,
    String? studentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    
    // Ensure user document exists first
    await ensureUserDocument();
    
    final Map<String, dynamic> data = {
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (displayName != null) data['displayName'] = displayName;
    if (phone != null) data['phone'] = phone;
    if (university != null) data['university'] = university;
    if (studentId != null) data['studentId'] = studentId;
    await _userDoc(user.uid).update(data);
  }

  Future<void> updatePhotoUrl(String photoUrl) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    
    // Ensure user document exists first
    await ensureUserDocument();
    
    await _userDoc(user.uid).update({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get a user's photo URL by their UID
  Future<String?> getUserPhotoUrl(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      if (doc.exists) {
        return doc.data()?['photoUrl'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Stream a user's photo URL by their UID
  Stream<String?> streamUserPhotoUrl(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data()?['photoUrl'] as String?;
      }
      return null;
    });
  }

  /// Stream a user's full document by their UID
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUser(String uid) {
    return _userDoc(uid).snapshots();
  }
}


