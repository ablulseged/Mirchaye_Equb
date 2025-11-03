import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'payment_local_store.dart';
import 'user_service.dart';
import 'notification_service.dart';

class EqubService {
  EqubService._internal();
  static final EqubService _instance = EqubService._internal();
  factory EqubService() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _equbs => _db.collection('equbs');

  Future<String> createEqubGroup({
    required String name,
    required String description,
    required String category,
    required double contributionAmount,
    required String paymentFrequency,
    required int groupSize,
    required DateTime startDate,
    required double latePenaltyPercentage,
    required double emergencyFundPercentage,
    required bool allowEarlyExit,
    required bool isPublic,
    required bool requireApproval,
    List<String> invitedMemberEmails = const [],
    String? coverImageUrl,
  }) async {
    final String uid = _auth.currentUser!.uid;
    final now = DateTime.now();

    // Get owner's photo URL from UserService
    final ownerPhotoUrl = await UserService().getUserPhotoUrl(uid);

    final doc = await _equbs.add({
      'name': name,
      'description': description,
      'category': category,
      'contributionAmount': contributionAmount,
      'paymentFrequency': paymentFrequency,
      'maxMembers': groupSize,
      'currentMembers': 1,
      'startDate': Timestamp.fromDate(startDate),
      'latePenaltyPercentage': latePenaltyPercentage,
      'emergencyFundPercentage': emergencyFundPercentage,
      'allowEarlyExit': allowEarlyExit,
      'isPublic': isPublic,
      'requireApproval': requireApproval,
      'ownerUid': uid,
      'ownerEmail': _auth.currentUser?.email,
      'ownerPhotoUrl': ownerPhotoUrl,
      'coverImageUrl': coverImageUrl,
      'memberUids': [uid],
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    // add owner as member
    await doc.collection('members').doc(uid).set({
      'uid': uid,
      'role': 'owner',
      'joinedAt': Timestamp.fromDate(now),
      // Store basic identity for easy display/spin
      'name': _auth.currentUser?.displayName,
      'email': _auth.currentUser?.email,
    });

    // store invited emails for approval flow
    if (invitedMemberEmails.isNotEmpty) {
      for (final email in invitedMemberEmails) {
        await doc.collection('invites').add({
          'email': email,
          'status': 'pending',
          'createdAt': Timestamp.fromDate(now),
        });
      }
    }

    return doc.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamPublicEqubs() {
    // Avoid requiring a composite index by removing orderBy here.
    // Sort can be done client-side for small result sets.
    return _equbs.where('isPublic', isEqualTo: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamOwnedEqubsByCurrentUser() {
    final uid = _auth.currentUser!.uid;
    return _equbs.where('ownerUid', isEqualTo: uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamEqubsWhereMember() {
    final uid = _auth.currentUser!.uid;
    return _equbs.where('memberUids', arrayContains: uid).snapshots();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamJoinedEqubsByScan() {
    final uid = _auth.currentUser!.uid;
    return _equbs.snapshots().asyncMap((snapshot) async {
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> result = [];
      for (final doc in snapshot.docs) {
        try {
          final member = await doc.reference.collection('members').doc(uid).get();
          if (member.exists) result.add(doc);
        } catch (_) {
          // Ignore permission errors per group
        }
      }
      return result;
    });
  }

  Stream<List<Map<String, dynamic>>> streamJoinedEqubsDetailed() {
    final uid = _auth.currentUser!.uid;
    return _db
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .asyncMap((snap) async {
      final futures = snap.docs.map((memberDoc) async {
        final equbRef = memberDoc.reference.parent.parent!;
        final equbDoc = await equbRef.get();
        final data = equbDoc.data() as Map<String, dynamic>?;
        if (data == null) return null;
        return {
          'id': equbDoc.id,
          ...data,
          'memberRole': memberDoc.data()['role'],
        };
      }).toList();
      final results = await Future.wait(futures);
      return results.whereType<Map<String, dynamic>>().toList();
    });
  }

  Future<int> countOwnedEqubsByCurrentUser() async {
    final uid = _auth.currentUser!.uid;
    final snap = await _equbs.where('ownerUid', isEqualTo: uid).get();
    return snap.size;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamEqub(String equbId) {
    return _equbs.doc(equbId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMembers(String equbId) {
    return _equbs.doc(equbId).collection('members').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamPaymentsForPeriod(
    String equbId,
    String period,
  ) {
    return _equbs
        .doc(equbId)
        .collection('payments')
        .where('period', isEqualTo: period)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamPaymentsByEqub(
      String equbId) {
    return _equbs
        .doc(equbId)
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamPaymentsByUser() {
    final uid = _auth.currentUser!.uid;
    return _db
        .collection('users')
        .doc(uid)
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String> recordPayment({
    required String equbId,
    String? equbName,
    required double amount,
    required String currency,
    required String method,
    String? bankName,
    String? screenshotName,
    required String reference,
    String? chapaReferenceId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final now = Timestamp.now();
    final Map<String, dynamic> payload = {
      'uid': user.uid,
      'userEmail': user.email,
      'equbId': equbId,
      'equbName': equbName,
      'amount': amount,
      'currency': currency,
      'method': method,
      'bankName': bankName,
      'screenshotName': screenshotName,
      'reference': reference,
      'chapaReferenceId': chapaReferenceId,
      'status': 'completed',
      'createdAt': now,
    };

    String lastId = '';
    try {
      final ref = await _equbs.doc(equbId).collection('payments').add(payload);
      lastId = ref.id;
    } catch (_) {}
    try {
      final ref = await _db.collection('users').doc(user.uid).collection('payments').add(payload);
      lastId = ref.id;
    } catch (_) {}
    // Always save locally so History works offline/when rules block
    try {
      await PaymentLocalStore.addPayment(payload);
    } catch (_) {}

    // Optional: add announcement for visibility in group feed
    try {
      await _equbs.doc(equbId).collection('announcements').add({
        'type': 'payment',
        'message': 'Payment received: ' + amount.toStringAsFixed(2) + ' ' + currency,
        'reference': reference,
        'senderUid': user.uid,
        'createdAt': now,
      });
    } catch (_) {
      // Ignore if rules disallow
    }

    // Create confirmation notification for the payer
    try {
      await NotificationService().createNotification(
        userId: user.uid,
        title: 'Payment Confirmed',
        message: 'Your payment of ${amount.toStringAsFixed(2)} $currency has been recorded',
        type: 'payment',
        equbId: equbId,
        equbName: equbName,
        data: {'reference': reference, 'method': method},
      );
    } catch (e) {
      print('Error creating payment confirmation notification: $e');
    }

    // Create notifications for all other group members
    try {
      final membersSnap = await _equbs.doc(equbId).collection('members').get();
      final memberUids = membersSnap.docs.map((doc) => doc.id).where((uid) => uid != user.uid).toList();
      
      if (memberUids.isNotEmpty) {
        await NotificationService().createNotificationForUsers(
          userIds: memberUids,
          title: 'Payment Received',
          message: 'Payment of ${amount.toStringAsFixed(2)} $currency received',
          type: 'payment',
          equbId: equbId,
          equbName: equbName,
          data: {'reference': reference, 'method': method},
        );
      }
    } catch (e) {
      print('Error creating notifications for group members: $e');
    }

    return lastId;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSpins(String equbId) {
    return _equbs.doc(equbId).collection('spins').orderBy('createdAt', descending: false).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamJoinRequests(String equbId) {
    return _equbs.doc(equbId).collection('joinRequests').snapshots();
  }

  Future<void> approveJoinRequest({
    required String equbId,
    required String userId,
  }) async {
    final equbRef = _equbs.doc(equbId);
    final memberRef = equbRef.collection('members').doc(userId);
    final reqRef = equbRef.collection('joinRequests').doc(userId);

    // Ensure only the owner can approve
    final equbSnap = await equbRef.get();
    final ownerUid = equbSnap.data()?['ownerUid'];
    if (_auth.currentUser?.uid != ownerUid) {
      throw Exception('Only the group owner can approve requests.');
    }

    await _db.runTransaction((tx) async {
      final memberSnap = await tx.get(memberRef);
      final reqSnap = await tx.get(reqRef);
      final reqData = reqSnap.data();
      if (!memberSnap.exists) {
        tx.set(memberRef, {
          'uid': userId,
          'role': 'member',
          'joinedAt': Timestamp.now(),
          // Use name/email captured on join request to avoid extra permissions
          'name': reqData != null ? (reqData['name'] as String?) : null,
          'email': reqData != null ? (reqData['email'] as String?) : null,
        });
        tx.update(equbRef, {
          'currentMembers': FieldValue.increment(1),
          'memberUids': FieldValue.arrayUnion([userId]),
        });
      }
      tx.update(reqRef, {
        'status': 'approved',
        'approvedAt': Timestamp.now(),
      });
    });
  }

  Future<void> declineJoinRequest({
    required String equbId,
    required String userId,
  }) async {
    final reqRef = _equbs.doc(equbId).collection('joinRequests').doc(userId);
    await reqRef.update({
      'status': 'declined',
      'declinedAt': Timestamp.now(),
    });
  }

  Future<void> addAnnouncement({
    required String equbId,
    required String message,
    String? language,
  }) async {
    await _equbs.doc(equbId).collection('announcements').add({
      'message': message,
      'language': language,
      'createdAt': Timestamp.now(),
      'senderUid': _auth.currentUser?.uid,
      'likeCount': 0,
      'likedBy': [],
    });
    
    // Create notifications for all members
    try {
      final membersSnap = await _equbs.doc(equbId).collection('members').get();
      final equbSnap = await _equbs.doc(equbId).get();
      final equbData = equbSnap.data();
      final equbName = equbData?['name'] ?? 'Group';
      final memberUids = membersSnap.docs.map((doc) => doc.id).where((uid) => uid != _auth.currentUser?.uid).toList();
      
      if (memberUids.isNotEmpty) {
        await NotificationService().createNotificationForUsers(
          userIds: memberUids,
          title: 'New Announcement',
          message: message,
          type: 'general',
          equbId: equbId,
          equbName: equbName,
        );
      }
    } catch (_) {
      // Ignore notification errors
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAnnouncements(String equbId) {
    return _equbs.doc(equbId).collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream all announcements from multiple groups and format them for recent activity
  Stream<List<Map<String, dynamic>>> streamAllGroupAnnouncements(List<String> equbIds) {
    if (equbIds.isEmpty) {
      return Stream.value([]);
    }

    // Collect all announcements from all groups
    final streams = equbIds.map((equbId) => 
      streamAnnouncements(equbId)
    ).toList();

    return _mergeAnnouncementStreams(streams, equbIds);
  }

  Stream<List<Map<String, dynamic>>> _mergeAnnouncementStreams(
    List<Stream<QuerySnapshot<Map<String, dynamic>>>> streams,
    List<String> equbIds,
  ) async* {
    final Map<int, QuerySnapshot<Map<String, dynamic>>> latest = {};
    
    // Listen to all streams and update latest snapshots
    for (int i = 0; i < streams.length; i++) {
      streams[i].listen((snapshot) {
        latest[i] = snapshot;
      });
    }
    
    // Periodically emit combined and sorted announcements
    await for (var _ in Stream.periodic(const Duration(milliseconds: 500))) {
      final allAnnouncements = <Map<String, dynamic>>[];
      
      for (int i = 0; i < equbIds.length; i++) {
        final snapshot = latest[i];
        if (snapshot == null) continue;
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          
          // Determine activity type and icon based on announcement type
          String title = 'New Announcement';
          String description = data['message'] as String? ?? '';
          String iconName = 'campaign';
          Color iconColor = const Color(0xFF6F35A5);
          
          final type = data['type'] as String?;
          if (type == 'payment') {
            title = 'Payment Received';
            iconName = 'payment';
            iconColor = const Color(0xFF2E7D32);
          } else if (type == 'join_request') {
            title = 'New Join Request';
            iconName = 'person_add';
            iconColor = const Color(0xFF6F35A5);
          } else if (type == 'spin_winner') {
            title = 'Spin Winner';
            iconName = 'check_circle';
            iconColor = const Color(0xFF2E7D32);
          }
          
          allAnnouncements.add({
            'title': title,
            'description': description,
            'iconName': iconName,
            'iconColor': iconColor,
            'createdAt': createdAt,
            'equbId': equbIds[i],
            'announcementId': doc.id,
            'time': createdAt != null ? _formatTime(createdAt) : 'Just now',
          });
        }
      }
      
      // Sort by date, most recent first
      allAnnouncements.sort((a, b) {
        final dateA = a['createdAt'] as DateTime?;
        final dateB = b['createdAt'] as DateTime?;
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });
      
      yield allAnnouncements;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> toggleLike({
    required String equbId,
    required String announcementId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You must be logged in to like announcements.');
    }

    final announcementRef = _equbs.doc(equbId).collection('announcements').doc(announcementId);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(announcementRef);
      if (!snapshot.exists) {
        throw Exception('Announcement not found');
      }

      final data = snapshot.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final isLiked = likedBy.contains(currentUser.uid);

      if (isLiked) {
        likedBy.remove(currentUser.uid);
      } else {
        likedBy.add(currentUser.uid);
      }

      transaction.update(announcementRef, {
        'likeCount': likedBy.length,
        'likedBy': likedBy,
      });
    });
  }

  Future<Map<String, dynamic>?> spinWinner(String equbId) async {
    final membersSnap = await _equbs.doc(equbId).collection('members').get();
    if (membersSnap.size == 0) return null;
    final docs = membersSnap.docs;
    docs.shuffle();
    final winner = docs.first;
    final winnerData = winner.data();
    await _equbs.doc(equbId).collection('spins').add({
      'winnerUid': winner.id,
      'winner': winnerData,
      'createdAt': Timestamp.now(),
    });
    // Optional: also add an announcement for visibility
    await _equbs.doc(equbId).collection('announcements').add({
      'message': 'Spin winner: ${winnerData['name'] ?? winnerData['email'] ?? winner.id}',
      'createdAt': Timestamp.now(),
      'senderUid': _auth.currentUser?.uid,
      'type': 'spin_winner',
    });
    
    // Create notifications for all members
    try {
      final equbSnap = await _equbs.doc(equbId).get();
      final equbData = equbSnap.data();
      final equbName = equbData?['name'] ?? 'Group';
      final memberUids = docs.map((doc) => doc.id).toList();
      
      await NotificationService().createNotificationForUsers(
        userIds: memberUids,
        title: 'Spin Winner',
        message: '${winnerData['name'] ?? winnerData['email'] ?? winner.id} won the spin!',
        type: 'spin_winner',
        equbId: equbId,
        equbName: equbName,
        data: {'winnerUid': winner.id},
      );
    } catch (_) {
      // Ignore notification errors
    }
    
    return {'uid': winner.id, ...winnerData};
  }

  Future<void> saveSpinResult({
    required String equbId,
    required String winnerUid,
    required Map<String, dynamic> winnerData,
  }) async {
    await _equbs.doc(equbId).collection('spins').add({
      'winnerUid': winnerUid,
      'winner': winnerData,
      'createdAt': Timestamp.now(),
    });
    await _equbs.doc(equbId).collection('announcements').add({
      'message': 'Spin winner: ${winnerData['name'] ?? winnerData['email'] ?? winnerUid}',
      'createdAt': Timestamp.now(),
      'senderUid': _auth.currentUser?.uid,
      'type': 'spin_winner',
    });
    
    // Create notifications for all members
    try {
      final membersSnap = await _equbs.doc(equbId).collection('members').get();
      final equbSnap = await _equbs.doc(equbId).get();
      final equbData = equbSnap.data();
      final equbName = equbData?['name'] ?? 'Group';
      final memberUids = membersSnap.docs.map((doc) => doc.id).toList();
      
      await NotificationService().createNotificationForUsers(
        userIds: memberUids,
        title: 'Spin Winner',
        message: '${winnerData['name'] ?? winnerData['email'] ?? winnerUid} won the spin!',
        type: 'spin_winner',
        equbId: equbId,
        equbName: equbName,
        data: {'winnerUid': winnerUid},
      );
    } catch (_) {
      // Ignore notification errors
    }
  }

  Future<void> requestToJoin({
    required String equbId,
    String? message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to send a join request.');
    }
    final String uid = user.uid;
    final now = DateTime.now();
    final docRef = _equbs.doc(equbId);

    // Validate group exists
    final equbSnap = await docRef.get();
    if (!equbSnap.exists) {
      throw Exception('Group not found.');
    }

    // Check already a member
    final memberSnap = await docRef.collection('members').doc(uid).get();
    if (memberSnap.exists) {
      throw Exception('You are already a member of this group.');
    }

    // Check existing request
    final reqDoc = await docRef.collection('joinRequests').doc(uid).get();
    if (reqDoc.exists) {
      final status = (reqDoc.data()?['status'] ?? 'pending').toString();
      if (status == 'pending') {
        throw Exception('Join request already pending approval.');
      }
      if (status == 'approved') {
        throw Exception('Your request was already approved.');
      }
      if (status == 'declined') {
        throw Exception('Your previous request was declined.');
      }
    }

    await docRef.collection('joinRequests').doc(uid).set({
      'uid': uid,
      'email': user.email,
      'name': user.displayName,
      'message': message,
      'status': 'pending',
      'requestedAt': Timestamp.fromDate(now),
    });

    // Optional: notify owner via announcements feed. Ignore if rules disallow.
    try {
      await docRef.collection('announcements').add({
        'type': 'join_request',
        'message': 'Join request from: ${user.displayName ?? user.email ?? uid}',
        'requesterUid': uid,
        'createdAt': Timestamp.fromDate(now),
      });
    } catch (_) {
      // Announcements write is optional; ignore permission errors here.
    }

    // Create notification for the group owner
    try {
      final equbData = equbSnap.data();
      final ownerUid = equbData?['ownerUid'];
      final equbName = equbData?['name'] ?? 'Group';
      
      if (ownerUid != null) {
        await NotificationService().createNotification(
          userId: ownerUid as String,
          title: 'New Join Request',
          message: '${user.displayName ?? user.email ?? "Someone"} wants to join $equbName',
          type: 'join_request',
          equbId: equbId,
          equbName: equbName,
          data: {'requesterUid': uid},
        );
      }
    } catch (_) {
      // Ignore notification errors
    }
  }

  /// Update equb settings - only owner can update
  Future<void> updateEqub({
    required String equbId,
    String? name,
    String? description,
    String? category,
    double? contributionAmount,
    String? paymentFrequency,
    int? maxMembers,
    DateTime? startDate,
    double? latePenaltyPercentage,
    double? emergencyFundPercentage,
    bool? allowEarlyExit,
    bool? isPublic,
    bool? requireApproval,
    String? coverImageUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You must be logged in to update an equb.');
    }

    // Verify ownership
    final equbDoc = await _equbs.doc(equbId).get();
    if (!equbDoc.exists) {
      throw Exception('Equb not found.');
    }

    final ownerUid = equbDoc.data()?['ownerUid'] as String?;
    if (ownerUid != currentUser.uid) {
      throw Exception('Only the group owner can update settings.');
    }

    // Build update data
    final updateData = <String, dynamic>{
      'updatedAt': Timestamp.now(),
    };

    if (name != null) updateData['name'] = name;
    if (description != null) updateData['description'] = description;
    if (category != null) updateData['category'] = category;
    if (contributionAmount != null) updateData['contributionAmount'] = contributionAmount;
    if (paymentFrequency != null) updateData['paymentFrequency'] = paymentFrequency;
    if (maxMembers != null) updateData['maxMembers'] = maxMembers;
    if (startDate != null) updateData['startDate'] = Timestamp.fromDate(startDate);
    if (latePenaltyPercentage != null) updateData['latePenaltyPercentage'] = latePenaltyPercentage;
    if (emergencyFundPercentage != null) updateData['emergencyFundPercentage'] = emergencyFundPercentage;
    if (allowEarlyExit != null) updateData['allowEarlyExit'] = allowEarlyExit;
    if (isPublic != null) updateData['isPublic'] = isPublic;
    if (requireApproval != null) updateData['requireApproval'] = requireApproval;
    if (coverImageUrl != null) updateData['coverImageUrl'] = coverImageUrl;

    await _equbs.doc(equbId).update(updateData);
  }

  /// Delete equb - only owner can delete
  Future<void> deleteEqub(String equbId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You must be logged in to delete an equb.');
    }

    // Verify ownership
    final equbDoc = await _equbs.doc(equbId).get();
    if (!equbDoc.exists) {
      throw Exception('Equb not found.');
    }

    final ownerUid = equbDoc.data()?['ownerUid'] as String?;
    if (ownerUid != currentUser.uid) {
      throw Exception('Only the group owner can delete the equb.');
    }

    // Delete all subcollections first (Firestore doesn't delete them automatically)
    final batch = _db.batch();
    
    // Delete members
    final membersSnapshot = await _equbs.doc(equbId).collection('members').get();
    for (var doc in membersSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete payments
    final paymentsSnapshot = await _equbs.doc(equbId).collection('payments').get();
    for (var doc in paymentsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete spins
    final spinsSnapshot = await _equbs.doc(equbId).collection('spins').get();
    for (var doc in spinsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete join requests
    final requestsSnapshot = await _equbs.doc(equbId).collection('joinRequests').get();
    for (var doc in requestsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete announcements
    final announcementsSnapshot = await _equbs.doc(equbId).collection('announcements').get();
    for (var doc in announcementsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete invites
    final invitesSnapshot = await _equbs.doc(equbId).collection('invites').get();
    for (var doc in invitesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete main equb document
    batch.delete(_equbs.doc(equbId));

    await batch.commit();
  }

  /// Check if current user is the owner of an equb
  Future<bool> isOwner(String equbId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final equbDoc = await _equbs.doc(equbId).get();
    if (!equbDoc.exists) return false;

    final ownerUid = equbDoc.data()?['ownerUid'] as String?;
    return ownerUid == currentUser.uid;
  }

  /// Remove a member from an equb - only owner can remove
  Future<void> removeMember({
    required String equbId,
    required String memberUid,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You must be logged in to remove a member.');
    }

    // Verify ownership
    final equbDoc = await _equbs.doc(equbId).get();
    if (!equbDoc.exists) {
      throw Exception('Equb not found.');
    }

    final ownerUid = equbDoc.data()?['ownerUid'] as String?;
    if (ownerUid != currentUser.uid) {
      throw Exception('Only the group owner can remove members.');
    }

    final equbRef = _equbs.doc(equbId);
    
    // Check if member exists
    final memberDoc = await equbRef.collection('members').doc(memberUid).get();
    if (!memberDoc.exists) {
      throw Exception('Member not found.');
    }

    // Check if trying to remove owner
    final memberRole = memberDoc.data()?['role'] as String?;
    if (memberRole == 'owner') {
      throw Exception('Cannot remove the group owner.');
    }

    // Update equb document
    await equbRef.update({
      'currentMembers': FieldValue.increment(-1),
      'memberUids': FieldValue.arrayRemove([memberUid]),
    });

    // Remove from members subcollection
    await equbRef.collection('members').doc(memberUid).delete();
  }
}


