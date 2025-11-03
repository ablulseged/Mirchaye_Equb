/**
 * Cloud Function to send push notifications
 * 
 * Setup Instructions:
 * 1. Install Firebase CLI: npm install -g firebase-tools
 * 2. Login: firebase login
 * 3. Initialize: firebase init functions
 * 4. Copy this file to functions/index.js
 * 5. Deploy: firebase deploy --only functions
 * 
 * This function listens for new documents in 'notification_requests' collection
 * and sends push notifications via FCM.
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendPushNotification = functions.firestore
  .document('notification_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    
    // Only process pending notifications
    if (data.status !== 'pending') {
      console.log('Skipping non-pending notification');
      return null;
    }

    const { fcmToken, title, body, data: notificationData } = data;

    if (!fcmToken) {
      console.error('No FCM token provided');
      return null;
    }

    // Prepare notification payload
    const message = {
      token: fcmToken,
      notification: {
        title: title || 'New Notification',
        body: body || '',
      },
      data: {
        ...notificationData,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'notifications_channel',
          sound: 'default',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    try {
      // Send notification via FCM
      const response = await admin.messaging().send(message);
      console.log('Successfully sent notification:', response);

      // Update request status to completed
      await snap.ref.update({
        status: 'completed',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: response,
      });

      return { success: true, messageId: response };
    } catch (error) {
      console.error('Error sending notification:', error);

      // Update request status to failed
      await snap.ref.update({
        status: 'failed',
        error: error.message,
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: false, error: error.message };
    }
  });
