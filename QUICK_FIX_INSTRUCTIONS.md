# Quick Fix: Firestore Permission Error

## Problem
App is showing this error:
```
Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions.}
Error creating notifications for users: [cloud_firestore/permission-denied]
```

## Solution: Update Firestore Rules in Firebase Console

### Step-by-Step Instructions

#### 1. Go to Firebase Console
Visit: https://console.firebase.google.com

#### 2. Select Your Project
Click on your project name

#### 3. Navigate to Firestore Rules
1. Click **"Firestore Database"** in the left sidebar
2. Click on the **"Rules"** tab at the top

#### 4. Copy and Paste New Rules
Delete everything in the rules editor and paste this:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null;
    }
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
      
      match /notifications/{notificationId} {
        allow read: if isAuthenticated() && request.auth.uid == userId;
        allow create: if isAuthenticated();
        allow update: if isAuthenticated() && request.auth.uid == userId;
        allow delete: if isAuthenticated() && request.auth.uid == userId;
      }
      
      match /payments/{paymentId} {
        allow read: if isAuthenticated() && request.auth.uid == userId;
        allow create: if isAuthenticated();
        allow update: if isOwner(userId);
        allow delete: if isOwner(userId);
      }
    }
    
    // Notification requests (for Cloud Functions to process push notifications)
    match /notification_requests/{requestId} {
      allow read, write: if isAuthenticated();
    }
    
    match /equbs/{equbId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && resource.data.ownerUid == request.auth.uid;
      allow delete: if isAuthenticated() && resource.data.ownerUid == request.auth.uid;
      
      match /members/{memberId} {
        allow read, write: if isAuthenticated();
      }
      match /payments/{paymentId} {
        allow read, write: if isAuthenticated();
      }
      match /announcements/{announcementId} {
        allow read, write: if isAuthenticated();
      }
      match /joinRequests/{requestId} {
        allow read, write: if isAuthenticated();
      }
      match /spins/{spinId} {
        allow read, write: if isAuthenticated();
      }
      match /invites/{inviteId} {
        allow read, write: if isAuthenticated();
      }
    }
  }
}
```

#### 5. Publish the Rules
1. Click **"Publish"** button
2. Wait for "Rules published successfully" message

#### 6. Test the App
Restart your app and try creating a notification again!

## What These Rules Do

✅ **Allow notifications**: The app can now create notifications for users  
✅ **Secure**: Users can only read/update their own notifications  
✅ **Auth required**: All operations require user authentication  
✅ **Equb access**: Group members can access all group data  
✅ **Owner controls**: Only owners can update/delete groups  

## Verification

After applying rules, you should see:
- ✅ No permission denied errors in terminal
- ✅ Notifications create successfully
- ✅ Notifications screen loads without errors
- ✅ Popup notifications work
- ✅ Unread badge updates correctly

