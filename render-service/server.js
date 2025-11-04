const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin SDK
let serviceAccount;

if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  try {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } catch (e) {
    try {
      serviceAccount = JSON.parse(Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT, 'base64').toString('ascii'));
    } catch (err) {
      console.error('Error parsing FIREBASE_SERVICE_ACCOUNT environment variable:', err);
      process.exit(1);
    }
  }
} else {
  console.error('FIREBASE_SERVICE_ACCOUNT environment variable is not set.');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// API endpoint to send push notifications
app.post('/api/send-notification', async (req, res) => {
  const { fcmToken, title, body, data } = req.body;

  if (!fcmToken || !title || !body) {
    return res.status(400).send({ error: 'Missing fcmToken, title, or body' });
  }

  const message = {
    token: fcmToken,
    notification: {
      title: title,
      body: body,
    },
    data: {
      ...data,
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
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    res.status(200).send({ success: true, messageId: response });
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).send({ success: false, error: error.message });
  }
});

// Basic health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// Test connection endpoint
app.get('/test', (req, res) => {
  res.status(200).json({ 
    status: 'connected', 
    message: 'Render notification service is running',
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
}); 