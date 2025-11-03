# Push Notifications Setup Guide

## Overview
Your app now has Firebase Cloud Messaging (FCM) integrated for push notifications that appear on the phone even when the app is closed or in the background.

## What's Been Implemented

✅ **FCM Integration**
- Firebase Cloud Messaging package added
- Messaging service created to handle FCM tokens
- Notification service updated to trigger push notifications
- Android manifest configured for notifications

✅ **How It Works**
1. When you make a payment/create notification → Notification saved to Firestore
2. App creates a document in `notification_requests` collection
3. Cloud Function listens to this collection and sends push notification
4. User receives push notification on their phone (even if app is closed)

## Setup Required

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Set Up Cloud Functions (Required for Push Notifications)

Cloud Functions are needed to actually send push notifications. Here's how to set them up:

#### Option A: Using Firebase Console (Easiest)

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click **"Functions"** in the left sidebar
4. Click **"Get Started"** or **"Add Function"**
5. Copy the code from `cloud_functions/index.js`
6. Create a new function with this code
7. Deploy it

#### Option B: Using Firebase CLI (Recommended)

1. **Install Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Initialize Functions** (in your project root):
   ```bash
   firebase init functions
   ```
   - Select your Firebase project
   - Choose JavaScript
   - Install dependencies? Yes

4. **Copy Cloud Function Code**:
   - Copy `cloud_functions/index.js` to `functions/index.js`
   - Copy `cloud_functions/package.json` to `functions/package.json`

5. **Install Dependencies**:
   ```bash
   cd functions
   npm install
   ```

6. **Deploy**:
   ```bash
   firebase deploy --only functions
   ```

### Step 3: Update Firestore Rules

The Firestore rules have been updated to allow `notification_requests` collection. Make sure you've applied the latest rules from `firestore.rules` or `QUICK_FIX_INSTRUCTIONS.md`.

### Step 4: Test

1. **Restart your app** after installing dependencies
2. **Make a payment** or create any notification
3. **Check your phone** - you should receive a push notification even if the app is closed!

## How It Works

### Flow Diagram

```
User Action (Payment, etc.)
    ↓
NotificationService.createNotification()
    ↓
Saves to Firestore: users/{userId}/notifications/{id}
    ↓
Creates notification request: notification_requests/{id}
    ↓
Cloud Function triggers (sendPushNotification)
    ↓
Cloud Function sends FCM push notification
    ↓
User receives notification on phone! 📱
```

### FCM Token Storage

- When user logs in, FCM token is automatically saved to `users/{userId}/fcmToken`
- Token is refreshed automatically when it changes
- Cloud Function uses this token to send notifications

## Testing Push Notifications

### Test 1: App Closed
1. Close the app completely
2. Have another user make a payment in a group you're part of
3. You should receive a push notification

### Test 2: App in Background
1. Put app in background (press home button)
2. Have another user make a payment
3. You should receive a push notification

### Test 3: App in Foreground
1. Keep app open
2. Have another user make a payment
3. You should see the notification popup in the app

## Troubleshooting

### Notifications Not Appearing?

1. **Check FCM Token**:
   - Look in console logs for: `📱 FCM Token: ...`
   - Check Firestore: `users/{userId}/fcmToken` should exist

2. **Check Cloud Function**:
   - Go to Firebase Console → Functions
   - Check if function is deployed and running
   - Check function logs for errors

3. **Check Notification Permissions**:
   - On first launch, app should request notification permission
   - Check phone settings: Settings → Apps → Robot → Notifications

4. **Check Firestore Rules**:
   - Make sure `notification_requests` collection is allowed
   - Rules should include: `allow read, write: if isAuthenticated();`

5. **Check Android Manifest**:
   - Verify permissions are added (POST_NOTIFICATIONS, VIBRATE, etc.)

### Common Issues

**Issue**: "No FCM token found for user"
- **Solution**: Make sure user is logged in and app has requested notification permission

**Issue**: "Cloud Function not triggering"
- **Solution**: Check if function is deployed, check function logs in Firebase Console

**Issue**: "Notifications not showing when app is closed"
- **Solution**: This is usually a Cloud Function issue. Make sure it's deployed and working.

## What's Next?

After setting up Cloud Functions:
- ✅ Push notifications will work automatically
- ✅ Users will receive notifications even when app is closed
- ✅ All notification types supported (payments, join requests, spins, announcements)

## Security Notes

- FCM tokens are stored securely in Firestore
- Only authenticated users can create notification requests
- Cloud Functions handle sending notifications securely using Firebase Admin SDK
- No sensitive API keys needed in the app

## Support

If you encounter issues:
1. Check Firebase Console → Functions → Logs
2. Check app console logs for FCM token messages
3. Verify Firestore rules are applied
4. Make sure Cloud Function is deployed
