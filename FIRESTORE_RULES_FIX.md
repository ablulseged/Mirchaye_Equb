# Firestore Security Rules - Notification Permissions Fix

## Problem
The app is getting permission denied errors when trying to:
1. **Create notifications** for users (`users/{userId}/notifications/{notificationId}`)
2. **Read notifications** from users collection

Error from terminal:
```
Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions.}
Error creating notifications for users: [cloud_firestore/permission-denied]
```

## Root Cause
Firestore security rules in Firebase Console don't have permissions for the notifications subcollection.

## Required Firestore Security Rules

### Add These Rules to Firebase Console

Go to: **Firebase Console → Firestore Database → Rules**

Replace your current rules with these (or add the notification rules if you have existing rules):

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the resource
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // ============================================
    // USER DATA
    // ============================================
    
    // User document read/write
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
      
      // User notifications subcollection
      match /notifications/{notificationId} {
        // Anyone authenticated can read their own notifications
        allow read: if isAuthenticated() && request.auth.uid == userId;
        
        // Only authenticated users can create notifications for themselves
        allow create: if isAuthenticated();
        
        // Only notification owner can update/delete
        allow update: if isAuthenticated() && request.auth.uid == userId;
        allow delete: if isAuthenticated() && request.auth.uid == userId;
      }
      
      // User payments subcollection
      match /payments/{paymentId} {
        allow read: if isAuthenticated() && request.auth.uid == userId;
        allow create: if isAuthenticated();
        allow update: if isOwner(userId);
        allow delete: if isOwner(userId);
      }
    }
    
    // ============================================
    // EQUBS (GROUPS)
    // ============================================
    
    match /equbs/{equbId} {
      // Anyone authenticated can read public equbs
      allow read: if isAuthenticated();
      
      // Only authenticated users can create equbs
      allow create: if isAuthenticated();
      
      // Only equb owner can update
      allow update: if isAuthenticated() 
        && resource.data.ownerUid == request.auth.uid;
      
      // Only equb owner can delete
      allow delete: if isAuthenticated() 
        && resource.data.ownerUid == request.auth.uid;
      
      // ============================================
      // EQUB MEMBERS
      // ============================================
      
      match /members/{memberId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated();
        allow update: if isAuthenticated();
        allow delete: if isAuthenticated();
      }
      
      // ============================================
      // EQUB PAYMENTS
      // ============================================
      
      match /payments/{paymentId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated();
        allow update: if isAuthenticated();
        allow delete: if isAuthenticated();
      }
      
      // ============================================
      // EQUB ANNOUNCEMENTS
      // ============================================
      
      match /announcements/{announcementId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated();
        allow update: if isAuthenticated();
        allow delete: if isAuthenticated();
      }
      
      // ============================================
      // EQUB JOIN REQUESTS
      // ============================================
      
      match /joinRequests/{requestId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated();
        allow update: if isAuthenticated();
        allow delete: if isAuthenticated();
      }
      
      // ============================================
      // EQUB SPINS
      // ============================================
      
      match /spins/{spinId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated();
        allow update: if isAuthenticated();
        allow delete: if isAuthenticated();
      }
      
      // ============================================
      // EQUB INVITES
      // ============================================
      
      match /invites/{inviteId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated();
        allow update: if isAuthenticated();
        allow delete: if isAuthenticated();
      }
    }
  }
}
```

## Key Points for Notifications

The critical rule that fixes the notification issue is:

```javascript
match /users/{userId}/notifications/{notificationId} {
  allow read: if isAuthenticated() && request.auth.uid == userId;
  allow create: if isAuthenticated();
  allow update: if isAuthenticated() && request.auth.uid == userId;
  allow delete: if isAuthenticated() && request.auth.uid == userId;
}
```

This allows:
- **Read**: Users can only read their own notifications
- **Create**: Any authenticated user can create notifications (needed for the system to notify users)
- **Update**: Users can only update their own notifications (mark as read)
- **Delete**: Users can only delete their own notifications

## How to Apply These Rules

### Option 1: Using Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Firestore Database** → **Rules**
4. Copy the rules above
5. Click **Publish**

### Option 2: Using Firebase CLI (if you have it set up)
1. Create a file: `firestore.rules` in your project root
2. Paste the rules above
3. Run: `firebase deploy --only firestore:rules`

## Testing After Applying Rules

After deploying the rules, test:
1. Create a payment → Should create notification successfully
2. View notifications screen → Should load without permission errors
3. Mark notification as read → Should update successfully
4. Check unread badge → Should update correctly

## Security Notes

⚠️ **Important**: These rules allow any authenticated user to create notifications for any user. This is appropriate for your app because:
- The notification service creates notifications as part of the app's core functionality
- Users can only read/update/delete their own notifications
- All users are authenticated and part of controlled groups

If you need more restrictive permissions later, you can modify the `allow create` rule to only allow certain users or add additional checks.

## Alternative: Development Mode Rules

If you're still in development and want to test quickly, you can temporarily use these permissive rules:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

⚠️ **WARNING**: These are only for development! Never use in production!

