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
    final isNewUser = !snapshot.exists;

    if (isNewUser) {
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

  /// Toggle saved equb id in user's document
  Future<void> toggleSavedEqub(String equbId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final doc = _userDoc(user.uid);
    final snapshot = await doc.get();
    final data = snapshot.data() ?? {};
    final saved = List<String>.from(data['savedEqubs'] ?? []);
    if (saved.contains(equbId)) {
      await doc.update({
        'savedEqubs': FieldValue.arrayRemove([equbId]),
      });
    } else {
      await doc.update({
        'savedEqubs': FieldValue.arrayUnion([equbId]),
      });
    }
  }

  /// Toggle favorite equb id in user's document
  Future<void> toggleFavoriteEqub(String equbId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final doc = _userDoc(user.uid);
    final snapshot = await doc.get();
    final data = snapshot.data() ?? {};
    final fav = List<String>.from(data['favoriteEqubs'] ?? []);
    if (fav.contains(equbId)) {
      await doc.update({
        'favoriteEqubs': FieldValue.arrayRemove([equbId]),
      });
    } else {
      await doc.update({
        'favoriteEqubs': FieldValue.arrayUnion([equbId]),
      });
    }
  }

  /// Stream saved equb ids for current user
  Stream<List<String>> streamSavedEqubIds() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    return _userDoc(user.uid).snapshots().map((snap) {
      final data = snap.data() ?? {};
      final saved = List<String>.from(data['savedEqubs'] ?? []);
      return saved;
    });
  }

  /// Stream favorite equb ids for current user
  Stream<List<String>> streamFavoriteEqubIds() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    return _userDoc(user.uid).snapshots().map((snap) {
      final data = snap.data() ?? {};
      final fav = List<String>.from(data['favoriteEqubs'] ?? []);
      return fav;
    });
  }

  Future<void> updateProfile({
    String? displayName,
    String? phone,
    String? university,
    String? studentId,
    String? department,
    String? college,
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
    if (studentId != null) {
      data['studentId'] = studentId;
      // Auto-extract department and college from studentId if not provided
      if (department == null && college == null && studentId.isNotEmpty) {
        final parts = studentId.split('/');
        if (parts.length >= 3) {
          if (parts.length >= 4) {
            // Format: UNI/COLLEGE/DEPT/YEAR/ID
            data['college'] = parts[1];
            data['department'] = parts[2];
          } else {
            // Format: UNI/DEPT/YEAR/ID
            data['department'] = parts[1];
          }
        }
      }
    }
    if (department != null) data['department'] = department;
    if (college != null) data['college'] = college;
    await _userDoc(user.uid).update(data);
  }

  /// Get user's department and college from studentId or document
  Future<Map<String, String?>> getUserDepartmentAndCollege(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        String? department = data['department'] as String?;
        String? college = data['college'] as String?;
        final studentId = data['studentId'] as String? ?? '';

        // Extract from studentId if not directly stored
        if ((department == null || college == null) && studentId.isNotEmpty) {
          final parts = studentId.split('/');
          if (parts.length >= 3) {
            if (parts.length >= 4) {
              // Format: UNI/COLLEGE/DEPT/YEAR/ID
              college = college ?? parts[1];
              department = department ?? parts[2];
            } else {
              // Format: UNI/DEPT/YEAR/ID
              department = department ?? parts[1];
            }
          }
        }

        return {'department': department, 'college': college};
      }
      return {'department': null, 'college': null};
    } catch (e) {
      return {'department': null, 'college': null};
    }
  }

  Future<void> updatePhotoUrl(String photoUrl) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    // Ensure user document exists first
    await ensureUserDocument();

    await _userDoc(
      user.uid,
    ).update({'photoUrl': photoUrl, 'updatedAt': FieldValue.serverTimestamp()});
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

  /// Delete user account - removes user data from Firestore and Firebase Auth
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    final uid = user.uid;
    final userRef = _userDoc(uid);

    // Delete user's subcollections
    final batch = _db.batch();

    // Delete notifications
    final notificationsSnapshot = await userRef
        .collection('notifications')
        .get();
    for (var doc in notificationsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete payments
    final paymentsSnapshot = await userRef.collection('payments').get();
    for (var doc in paymentsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete user document
    batch.delete(userRef);

    // Remove user from all equb groups
    final equbsSnapshot = await _db.collection('equbs').get();
    for (var equbDoc in equbsSnapshot.docs) {
      final membersRef = equbDoc.reference.collection('members').doc(uid);
      final memberDoc = await membersRef.get();
      if (memberDoc.exists) {
        batch.delete(membersRef);
        // Update member count
        final currentMembers =
            (equbDoc.data()['currentMembers'] as num?)?.toInt() ?? 0;
        if (currentMembers > 0) {
          batch.update(equbDoc.reference, {
            'currentMembers': currentMembers - 1,
            'memberUids': FieldValue.arrayRemove([uid]),
          });
        }
      }
    }

    // Commit all deletions
    await batch.commit();

    // Delete Firebase Auth account
    await user.delete();
  }
}
