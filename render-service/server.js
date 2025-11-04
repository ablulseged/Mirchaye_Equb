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

console.log('Starting Firebase Admin SDK initialization...');
console.log('FIREBASE_SERVICE_ACCOUNT is set:', !!process.env.FIREBASE_SERVICE_ACCOUNT);

if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  try {
    console.log('Attempting to parse FIREBASE_SERVICE_ACCOUNT as JSON...');
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    console.log('✅ Successfully parsed FIREBASE_SERVICE_ACCOUNT as JSON');
  } catch (e) {
    console.log('Failed to parse as JSON, trying base64 decode...');
    try {
      serviceAccount = JSON.parse(Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT, 'base64').toString('ascii'));
      console.log('✅ Successfully parsed FIREBASE_SERVICE_ACCOUNT from base64');
    } catch (err) {
      console.error('❌ Error parsing FIREBASE_SERVICE_ACCOUNT environment variable:');
      console.error('First error:', e.message);
      console.error('Second error:', err.message);
      console.error('Please ensure FIREBASE_SERVICE_ACCOUNT contains valid JSON');
      process.exit(1);
    }
  }
} else {
  console.error('❌ FIREBASE_SERVICE_ACCOUNT environment variable is not set.');
  console.error('Please set this in Render Dashboard → Environment → Add Environment Variable');
  process.exit(1);
}

try {
  console.log('Initializing Firebase Admin SDK...');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log('✅ Firebase Admin SDK initialized successfully');
} catch (error) {
  console.error('❌ Error initializing Firebase Admin SDK:', error.message);
  console.error('Please check your FIREBASE_SERVICE_ACCOUNT credentials');
  process.exit(1);
}

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
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`✅ Health check available at: /health`);
  console.log(`✅ Test endpoint available at: /test`);
  console.log(`✅ Notification endpoint available at: /api/send-notification`);
}); 