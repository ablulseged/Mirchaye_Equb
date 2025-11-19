import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'equb_service.dart';
import 'user_service.dart';

/// System group types enum
enum SystemGroupType {
  birrAmount,      // 1. By contribution amount (Birr ranges)
  department,      // 2. By department
  college,         // 3. By college
  studentYear,     // 4. By student year/level
  memberType,      // 5. By member type (new/experienced)
  university,      // 6. By university
  paymentFrequency, // 7. By payment frequency
  category,        // 8. By category (family, friends, etc.)
  gender,          // 9. By gender
  location,        // 10. By location/region
}

/// Service for managing automatic system-generated groups based on various criteria
class SystemGroupService {
  SystemGroupService._internal();
  static final SystemGroupService _instance = SystemGroupService._internal();
  factory SystemGroupService() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EqubService _equbService = EqubService();
  final UserService _userService = UserService();

  CollectionReference<Map<String, dynamic>> get _equbs => _db.collection('equbs');
  CollectionReference<Map<String, dynamic>> get _systemGroups => _db.collection('systemGroups');

  /// Get group type identifier string
  String _getGroupTypeId(SystemGroupType type, Map<String, dynamic> criteria) {
    switch (type) {
      case SystemGroupType.birrAmount:
        final amount = criteria['amount'] as double;
        if (amount <= 500) return 'birr_0_500';
        if (amount <= 1000) return 'birr_500_1000';
        if (amount <= 2000) return 'birr_1000_2000';
        if (amount <= 5000) return 'birr_2000_5000';
        return 'birr_5000_plus';
      case SystemGroupType.department:
        return 'dept_${criteria['department'] ?? 'unknown'}';
      case SystemGroupType.college:
        return 'college_${criteria['college'] ?? 'unknown'}';
      case SystemGroupType.studentYear:
        return 'year_${criteria['year'] ?? 'unknown'}';
      case SystemGroupType.memberType:
        return 'member_${criteria['type'] ?? 'new'}';
      case SystemGroupType.university:
        return 'univ_${criteria['university'] ?? 'unknown'}';
      case SystemGroupType.paymentFrequency:
        return 'freq_${criteria['frequency'] ?? 'monthly'}';
      case SystemGroupType.category:
        return 'cat_${criteria['category'] ?? 'general'}';
      case SystemGroupType.gender:
        return 'gender_${criteria['gender'] ?? 'all'}';
      case SystemGroupType.location:
        return 'loc_${criteria['location'] ?? 'unknown'}';
    }
  }

  /// Extract user attributes for grouping
  Future<Map<String, dynamic>> _getUserAttributes(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      
      final studentId = userData['studentId'] as String? ?? '';
      final university = userData['university'] as String? ?? '';
      
      // Extract department and college from studentId (format: UNI/DEPT/YEAR/ID or UNI/COLLEGE/DEPT/YEAR/ID)
      String? department;
      String? college;
      String? year;
      
      if (studentId.isNotEmpty) {
        final parts = studentId.split('/');
        if (parts.length >= 3) {
          // Try to extract department and year
          department = parts.length >= 2 ? parts[1] : null;
          year = parts.length >= 3 ? parts[2] : null;
          // If 4+ parts, assume college is second part
          if (parts.length >= 4) {
            college = parts[1];
            department = parts[2];
            year = parts[3];
          }
        }
      }
      
      // Get user creation date to determine member type
      final createdAt = userData['createdAt'] as Timestamp?;
      final isNewMember = createdAt == null || 
          DateTime.now().difference(createdAt.toDate()).inDays < 90;
      
      return {
        'department': department,
        'college': college,
        'university': university,
        'year': year,
        'memberType': isNewMember ? 'new' : 'experienced',
        'studentId': studentId,
      };
    } catch (e) {
      return {};
    }
  }

  /// Find or create a system group for a user based on criteria
  Future<String> findOrCreateSystemGroup({
    required SystemGroupType type,
    required Map<String, dynamic> criteria,
    double? contributionAmount,
    String? paymentFrequency,
    int? maxMembers,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Get user attributes
    final userAttrs = await _getUserAttributes(userId);
    
    // Build criteria based on type
    Map<String, dynamic> groupCriteria = {};
    String groupName = '';
    String groupDescription = '';
    
    switch (type) {
      case SystemGroupType.birrAmount:
        final amount = contributionAmount ?? criteria['amount'] ?? 1000.0;
        groupCriteria = {'amountRange': _getBirrRange(amount), 'amount': amount};
        groupName = 'Birr ${amount.toStringAsFixed(0)} Group';
        groupDescription = 'System group for ${_getBirrRange(amount)} Birr contributions';
        break;
      case SystemGroupType.department:
        final dept = criteria['department'] ?? userAttrs['department'] ?? 'General';
        groupCriteria = {'department': dept};
        groupName = '$dept Department Group';
        groupDescription = 'System group for $dept department members';
        break;
      case SystemGroupType.college:
        final coll = criteria['college'] ?? userAttrs['college'] ?? 'General';
        groupCriteria = {'college': coll};
        groupName = '$coll College Group';
        groupDescription = 'System group for $coll college members';
        break;
      case SystemGroupType.studentYear:
        final year = criteria['year'] ?? userAttrs['year'] ?? 'All';
        groupCriteria = {'year': year};
        groupName = 'Year $year Student Group';
        groupDescription = 'System group for Year $year students';
        break;
      case SystemGroupType.memberType:
        final mType = criteria['type'] ?? userAttrs['memberType'] ?? 'new';
        groupCriteria = {'memberType': mType};
        groupName = '${mType == 'new' ? 'New' : 'Experienced'} Members Group';
        groupDescription = 'System group for ${mType == 'new' ? 'new' : 'experienced'} members';
        break;
      case SystemGroupType.university:
        final univ = criteria['university'] ?? userAttrs['university'] ?? 'General';
        groupCriteria = {'university': univ};
        groupName = '$univ University Group';
        groupDescription = 'System group for $univ university members';
        break;
      case SystemGroupType.paymentFrequency:
        final freq = criteria['frequency'] ?? paymentFrequency ?? 'monthly';
        groupCriteria = {'frequency': freq};
        groupName = '${_capitalizeString(freq)} Payment Group';
        groupDescription = 'System group for ${freq} payment frequency';
        break;
      case SystemGroupType.category:
        final cat = criteria['category'] ?? 'general';
        groupCriteria = {'category': cat};
        groupName = '${_capitalizeString(cat)} Category Group';
        groupDescription = 'System group for $cat category';
        break;
      case SystemGroupType.gender:
        final gender = criteria['gender'] ?? 'all';
        groupCriteria = {'gender': gender};
        groupName = '${_capitalizeString(gender)} Members Group';
        groupDescription = 'System group for ${gender} members';
        break;
      case SystemGroupType.location:
        final loc = criteria['location'] ?? 'General';
        groupCriteria = {'location': loc};
        groupName = '$loc Location Group';
        groupDescription = 'System group for $loc location';
        break;
    }

    final typeId = _getGroupTypeId(type, groupCriteria);
    
    // Find existing group with available space
    // Note: Firestore doesn't support equality on nested maps, so we query by typeId only
    // and filter client-side for criteria match
    // Also, we avoid orderBy and where on currentMembers to prevent requiring composite indexes
    final existingGroupsQuery = await _equbs
        .where('isSystemGenerated', isEqualTo: true)
        .where('systemGroupType', isEqualTo: typeId)
        .get();
    
    // Filter by criteria match and available space client-side
    final matchingGroups = existingGroupsQuery.docs.where((doc) {
      final data = doc.data();
      final storedCriteria = data['systemGroupCriteria'] as Map<String, dynamic>? ?? {};
      final currentMembers = (data['currentMembers'] as num?)?.toInt() ?? 0;
      final maxMembersValue = maxMembers ?? 10;
      
      // Check if all criteria match
      bool criteriaMatch = true;
      for (final key in groupCriteria.keys) {
        if (storedCriteria[key] != groupCriteria[key]) {
          criteriaMatch = false;
          break;
        }
      }
      
      // Also check if group has available space
      return criteriaMatch && currentMembers < maxMembersValue;
    }).toList();
    
    // Sort by currentMembers ascending (least full first) client-side
    matchingGroups.sort((a, b) {
      final membersA = (a.data()['currentMembers'] as num?)?.toInt() ?? 0;
      final membersB = (b.data()['currentMembers'] as num?)?.toInt() ?? 0;
      return membersA.compareTo(membersB);
    });

    if (matchingGroups.isNotEmpty) {
      return matchingGroups.first.id;
    }

    // No available group found, create a new one
    return await _createSystemGroup(
      type: type,
      typeId: typeId,
      criteria: groupCriteria,
      name: groupName,
      description: groupDescription,
      contributionAmount: contributionAmount ?? 1000.0,
      paymentFrequency: paymentFrequency ?? 'monthly',
      maxMembers: maxMembers ?? 10,
    );
  }

  /// Create a new system group
  Future<String> _createSystemGroup({
    required SystemGroupType type,
    required String typeId,
    required Map<String, dynamic> criteria,
    required String name,
    required String description,
    required double contributionAmount,
    required String paymentFrequency,
    required int maxMembers,
  }) async {
    // Get the next group number for this type
    // Try to get from systemGroups collection, but fallback to counting existing groups
    int groupNumber = 1;
    try {
      final groupCountDoc = await _systemGroups.doc(typeId).get();
      if (groupCountDoc.exists) {
        groupNumber = (groupCountDoc.data()?['count'] ?? 0) + 1;
      } else {
        // Fallback: count existing groups of this type
        final existingGroups = await _equbs
            .where('isSystemGenerated', isEqualTo: true)
            .where('systemGroupType', isEqualTo: typeId)
            .get();
        groupNumber = existingGroups.docs.length + 1;
      }
    } catch (e) {
      // If permission denied, count existing groups directly
      print('Note: Could not access systemGroups collection, counting existing groups: $e');
      try {
        final existingGroups = await _equbs
            .where('isSystemGenerated', isEqualTo: true)
            .where('systemGroupType', isEqualTo: typeId)
            .get();
        groupNumber = existingGroups.docs.length + 1;
      } catch (e2) {
        print('Could not count existing groups, using default: $e2');
        groupNumber = 1;
      }
    }

    final fullName = '$name #$groupNumber';
    
    // Create the equb group
    final equbId = await _equbService.createEqubGroup(
      name: fullName,
      description: '$description (Auto-generated)',
      category: criteria['category'] ?? 'system', // Use the actual category
      contributionAmount: contributionAmount,
      paymentFrequency: paymentFrequency,
      groupSize: maxMembers,
      startDate: DateTime.now().add(const Duration(days: 7)),
      latePenaltyPercentage: 5.0,
      emergencyFundPercentage: 2.0,
      allowEarlyExit: false,
      isPublic: true,
      requireApproval: false,
    );

    // Mark as system generated and set owner to "System"
    await _equbs.doc(equbId).update({
      'isSystemGenerated': true,
      'systemGroupType': typeId,
      'systemGroupCriteria': criteria,
      'systemGroupNumber': groupNumber,
      'ownerUid': 'system', // System groups have no specific owner
      'ownerEmail': 'system@equb.app',
      'ownerName': 'System',
      'isSystemOwned': true, // Flag to identify system-owned groups
    });

    // Update group count (skip if permission denied - not critical)
    try {
      await _systemGroups.doc(typeId).set({
        'type': typeId,
        'count': groupNumber,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Ignore permission errors for systemGroups collection - not critical
      print('Note: Could not update systemGroups collection (may not exist): $e');
    }

    print('✅ Created system group: $fullName (ID: $equbId)');
    return equbId;
  }

  /// Get Birr range for amount-based grouping
  String _getBirrRange(double amount) {
    if (amount <= 500) return '0-500';
    if (amount <= 1000) return '500-1000';
    if (amount <= 2000) return '1000-2000';
    if (amount <= 5000) return '2000-5000';
    return '5000+';
  }

  /// Capitalize first letter of a string
  String _capitalizeString(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  /// Auto-join user to appropriate category-based system groups
  Future<List<String>> autoJoinSystemGroups(String userId) async {
    final userAttrs = await _getUserAttributes(userId);
    
    // Define different categories for system groups
    final List<String> categories = [
      'family',
      'friends',
      'work',
      'college',
      'savings',
      'general',
      'emergency',
      'education',
      'health',
      'business',
    ];
    
    final List<String> joinedGroupIds = [];
    
    try {
      // First, auto-join mirchaye groups (no approval needed)
      await autoJoinMirchayeGroups(userId);
      
      // Get all joined mirchaye groups
      final mirchayeGroups = await _equbs
          .where('isSystemGenerated', isEqualTo: true)
          .where('isMirchayeGroup', isEqualTo: true)
          .get();
      
      for (final doc in mirchayeGroups.docs) {
        final memberDoc = await doc.reference.collection('members').doc(userId).get();
        if (memberDoc.exists) {
          joinedGroupIds.add(doc.id);
        }
      }

      // Create and join category-based groups
      for (final category in categories) {
        try {
          final categoryGroup = await findOrCreateSystemGroup(
            type: SystemGroupType.category,
            criteria: {'category': category},
            contributionAmount: 1000.0,
            paymentFrequency: 'monthly',
            maxMembers: 10, // When full, will auto-create another
          );
          
          // Try to join the group
          final joined = await _autoJoinGroup(userId, categoryGroup);
          
          // If group is full after join attempt, create a new one and join that
          if (!joined) {
            final newGroup = await findOrCreateSystemGroup(
              type: SystemGroupType.category,
              criteria: {'category': category},
              contributionAmount: 1000.0,
              paymentFrequency: 'monthly',
              maxMembers: 10,
            );
            await _autoJoinGroup(userId, newGroup);
            joinedGroupIds.add(newGroup);
          } else {
            joinedGroupIds.add(categoryGroup);
          }
        } catch (e) {
          print('Error joining category group $category: $e');
        }
      }
    } catch (e) {
      print('Error auto-joining system groups: $e');
    }

    return joinedGroupIds;
  }

  /// Auto-join a user to a group
  /// Returns true if successfully joined, false if group is full
  Future<bool> _autoJoinGroup(String userId, String equbId) async {
    try {
      final equbRef = _equbs.doc(equbId);
      final memberRef = equbRef.collection('members').doc(userId);
      
      // Check if already a member
      final memberDoc = await memberRef.get();
      if (memberDoc.exists) return true;

      // Get user data
      final userDoc = await _db.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};
      final authUser = _auth.currentUser;
      
      bool joined = false;
      await _db.runTransaction((tx) async {
        final equbSnap = await tx.get(equbRef);
        final memberSnap = await tx.get(memberRef);
        
        if (!memberSnap.exists && equbSnap.exists) {
          final equbData = equbSnap.data()!;
          final currentMembers = equbData['currentMembers'] as int? ?? 0;
          final maxMembers = equbData['maxMembers'] as int? ?? 10;
          
          if (currentMembers < maxMembers) {
            // Add member
            tx.set(memberRef, {
              'uid': userId,
              'role': 'member',
              'joinedAt': Timestamp.now(),
              'name': authUser?.displayName ?? userData['displayName'],
              'email': authUser?.email ?? userData['email'],
            });
            
            // Update equb
            final newMemberCount = currentMembers + 1;
            tx.update(equbRef, {
              'currentMembers': FieldValue.increment(1),
              'memberUids': FieldValue.arrayUnion([userId]),
            });
            
            joined = true;
            
            // If group becomes full after this join, trigger creation of new group
            if (newMemberCount >= maxMembers) {
              // Schedule async check and creation of new group
              checkAndCreateNewGroupIfFull(equbId).then((newGroupId) {
                if (newGroupId != null) {
                  print('✅ Auto-created new group $newGroupId because group $equbId is full');
                }
              }).catchError((e) {
                print('Error creating new group after full: $e');
              });
            }
          }
        }
      });
      
      return joined;
    } catch (e) {
      print('Error auto-joining group: $e');
      return false;
    }
  }

  /// Check if a group is full and create a new one if needed
  Future<String?> checkAndCreateNewGroupIfFull(String equbId) async {
    try {
      final equbDoc = await _equbs.doc(equbId).get();
      if (!equbDoc.exists) return null;

      final data = equbDoc.data()!;
      if (!(data['isSystemGenerated'] as bool? ?? false)) return null;

      final currentMembers = data['currentMembers'] as int? ?? 0;
      final maxMembers = data['maxMembers'] as int? ?? 10;

      if (currentMembers >= maxMembers) {
        // Group is full, create a new one
        final typeId = data['systemGroupType'] as String?;
        final criteria = data['systemGroupCriteria'] as Map<String, dynamic>? ?? {};
        
        if (typeId != null) {
          // Determine SystemGroupType from typeId
          SystemGroupType? type;
          if (typeId.startsWith('birr_')) type = SystemGroupType.birrAmount;
          else if (typeId.startsWith('dept_')) type = SystemGroupType.department;
          else if (typeId.startsWith('college_')) type = SystemGroupType.college;
          else if (typeId.startsWith('year_')) type = SystemGroupType.studentYear;
          else if (typeId.startsWith('member_')) type = SystemGroupType.memberType;
          else if (typeId.startsWith('univ_')) type = SystemGroupType.university;
          else if (typeId.startsWith('freq_')) type = SystemGroupType.paymentFrequency;
          else if (typeId.startsWith('cat_')) type = SystemGroupType.category;
          else if (typeId.startsWith('gender_')) type = SystemGroupType.gender;
          else if (typeId.startsWith('loc_')) type = SystemGroupType.location;

          if (type != null) {
            return await findOrCreateSystemGroup(
              type: type,
              criteria: criteria,
              contributionAmount: data['contributionAmount'] as double?,
              paymentFrequency: data['paymentFrequency'] as String?,
              maxMembers: maxMembers,
            );
          }
        }
      }
    } catch (e) {
      print('Error checking group capacity: $e');
    }
    return null;
  }

  /// Create 10 specific "mirchaye" groups
  Future<void> createMirchayeGroups() async {
    try {
      // Check if mirchaye groups already exist by checking for isMirchayeGroup flag
      final existingMirchaye = await _equbs
          .where('isSystemGenerated', isEqualTo: true)
          .where('isMirchayeGroup', isEqualTo: true)
          .limit(1)
          .get();

      if (existingMirchaye.docs.isNotEmpty) {
        print('✅ Mirchaye groups already exist');
        return;
      }

      // Create 10 mirchaye groups
      for (int i = 1; i <= 10; i++) {
        try {
          final groupName = 'mirchaye $i';
          
          // Create the equb group directly (no approval needed)
          final equbId = await _equbService.createEqubGroup(
            name: groupName,
            description: 'System group mirchaye $i (Auto-join, no approval needed)',
            category: 'general',
            contributionAmount: 1000.0,
            paymentFrequency: 'monthly',
            groupSize: 10,
            startDate: DateTime.now().add(const Duration(days: 7)),
            latePenaltyPercentage: 5.0,
            emergencyFundPercentage: 2.0,
            allowEarlyExit: false,
            isPublic: true,
            requireApproval: false, // No approval needed - auto-join
          );

          // Mark as system generated mirchaye group
          await _equbs.doc(equbId).update({
            'isSystemGenerated': true,
            'systemGroupType': 'mirchaye',
            'systemGroupNumber': i,
            'ownerUid': 'system',
            'ownerEmail': 'system@equb.app',
            'ownerName': 'System',
            'isSystemOwned': true,
            'isMirchayeGroup': true,
            'autoJoin': true, // Auto-join enabled
          });

          print('✅ Created system group: $groupName (ID: $equbId)');
        } catch (e) {
          print('⚠️ Error creating mirchaye group $i: $e');
        }
      }
    } catch (e) {
      print('⚠️ Error creating mirchaye groups: $e');
    }
  }

  /// Initialize default system groups for all categories if they don't exist
  Future<void> initializeDefaultSystemGroups() async {
    try {
      // First create mirchaye groups
      await createMirchayeGroups();

      final List<String> categories = [
        'family',
        'friends',
        'work',
        'college',
        'savings',
        'general',
        'emergency',
        'education',
        'health',
        'business',
      ];

      for (final category in categories) {
        try {
          // Check if any group exists for this category
          final typeId = _getGroupTypeId(SystemGroupType.category, {'category': category});
          final existingGroups = await _equbs
              .where('isSystemGenerated', isEqualTo: true)
              .where('systemGroupType', isEqualTo: typeId)
              .limit(1)
              .get();

          // If no groups exist for this category, create the first one
          if (existingGroups.docs.isEmpty) {
            await findOrCreateSystemGroup(
              type: SystemGroupType.category,
              criteria: {'category': category},
              contributionAmount: 1000.0,
              paymentFrequency: 'monthly',
              maxMembers: 10,
            );
            print('✅ Created default system group for category: $category');
          }
        } catch (e) {
          print('⚠️ Error creating default group for $category: $e');
        }
      }
    } catch (e) {
      print('⚠️ Error initializing default system groups: $e');
    }
  }

  /// Stream all system groups (including mirchaye groups)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamSystemGroups() {
    // Note: Firestore requires a composite index for where + orderBy queries
    // To avoid requiring an index, we query without orderBy and sort client-side
    return _equbs
        .where('isSystemGenerated', isEqualTo: true)
        .snapshots();
  }

  /// Auto-join user to mirchaye groups (no approval needed)
  Future<void> autoJoinMirchayeGroups(String userId) async {
    try {
      // Get all mirchaye groups
      final mirchayeGroups = await _equbs
          .where('isSystemGenerated', isEqualTo: true)
          .where('isMirchayeGroup', isEqualTo: true)
          .get();

      for (final doc in mirchayeGroups.docs) {
        try {
          await _autoJoinGroup(userId, doc.id);
        } catch (e) {
          print('Error auto-joining mirchaye group ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('Error auto-joining mirchaye groups: $e');
    }
  }

  /// Get system groups by type
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getSystemGroupsByType(
    SystemGroupType type,
    Map<String, dynamic> criteria,
  ) async {
    final typeId = _getGroupTypeId(type, criteria);
    final snapshot = await _equbs
        .where('isSystemGenerated', isEqualTo: true)
        .where('systemGroupType', isEqualTo: typeId)
        .get();
    
    // Filter by criteria match client-side (Firestore doesn't support equality on nested maps)
    return snapshot.docs.where((doc) {
      final data = doc.data();
      final storedCriteria = data['systemGroupCriteria'] as Map<String, dynamic>? ?? {};
      // Check if all criteria match
      for (final key in criteria.keys) {
        if (storedCriteria[key] != criteria[key]) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}

/// Extension for String capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

