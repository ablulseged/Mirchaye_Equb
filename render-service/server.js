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
  const envValue = process.env.FIREBASE_SERVICE_ACCOUNT;
  console.log(`FIREBASE_SERVICE_ACCOUNT length: ${envValue.length} characters`);
  console.log(`First 50 characters: ${envValue.substring(0, 50)}...`);
  
  // Check if it looks like base64 first (contains non-JSON characters)
  if (!envValue.trim().startsWith('{')) {
    console.log('Value does not start with "{", trying base64 decode...');
    try {
      const decoded = Buffer.from(envValue, 'base64').toString('utf-8');
      console.log('Base64 decoded successfully, attempting JSON parse...');
      serviceAccount = JSON.parse(decoded);
      console.log('✅ Successfully parsed FIREBASE_SERVICE_ACCOUNT from base64');
    } catch (base64Err) {
      console.error('❌ Failed to decode as base64, trying direct JSON parse...');
      try {
        serviceAccount = JSON.parse(envValue);
        console.log('✅ Successfully parsed FIREBASE_SERVICE_ACCOUNT as JSON');
      } catch (jsonErr) {
        console.error('❌ Error parsing FIREBASE_SERVICE_ACCOUNT environment variable:');
        console.error('Base64 decode error:', base64Err.message);
        console.error('JSON parse error:', jsonErr.message);
        console.error('Value preview (first 100 chars):', envValue.substring(0, 100));
        console.error('');
        console.error('⚠️  TROUBLESHOOTING:');
        console.error('1. Make sure you copied the ENTIRE JSON from Firebase Console');
        console.error('2. The JSON should start with "{" and end with "}"');
        console.error('3. Remove any extra spaces or line breaks at the start/end');
        console.error('4. In Render, paste it as a single-line JSON (Render will handle formatting)');
        console.error('5. Do NOT wrap it in quotes - paste the JSON directly');
        process.exit(1);
      }
    }
  } else {
    // Try direct JSON parse first
    try {
      console.log('Attempting to parse FIREBASE_SERVICE_ACCOUNT as JSON...');
      serviceAccount = JSON.parse(envValue);
      console.log('✅ Successfully parsed FIREBASE_SERVICE_ACCOUNT as JSON');
    } catch (e) {
      console.log('Failed to parse as JSON, trying base64 decode...');
      try {
        const decoded = Buffer.from(envValue, 'base64').toString('utf-8');
        serviceAccount = JSON.parse(decoded);
        console.log('✅ Successfully parsed FIREBASE_SERVICE_ACCOUNT from base64');
      } catch (err) {
        console.error('❌ Error parsing FIREBASE_SERVICE_ACCOUNT environment variable:');
        console.error('JSON parse error:', e.message);
        console.error('Base64 decode error:', err.message);
        console.error('Value preview (first 100 chars):', envValue.substring(0, 100));
        console.error('');
        console.error('⚠️  TROUBLESHOOTING:');
        console.error('1. Make sure you copied the ENTIRE JSON from Firebase Console');
        console.error('2. The JSON should start with "{" and end with "}"');
        console.error('3. Remove any extra spaces or line breaks at the start/end');
        console.error('4. In Render, paste it as a single-line JSON (Render will handle formatting)');
        console.error('5. Do NOT wrap it in quotes - paste the JSON directly');
        process.exit(1);
      }
    }
  }
} else {
  console.error('❌ FIREBASE_SERVICE_ACCOUNT environment variable is not set.');
  console.error('Please set this in Render Dashboard → Environment → Add Environment Variable');
  process.exit(1);
}

try {
  console.log('Initializing Firebase Admin SDK...');
  const firebaseConfig = {
    credential: admin.credential.cert(serviceAccount),
  };
  
  // Add databaseURL if provided (optional, only needed for Realtime Database)
  if (process.env.FIREBASE_DATABASE_URL) {
    firebaseConfig.databaseURL = process.env.FIREBASE_DATABASE_URL;
    console.log('Using custom databaseURL from environment variable');
  } else if (serviceAccount.project_id) {
    // Auto-generate databaseURL from project ID (common pattern)
    firebaseConfig.databaseURL = `https://${serviceAccount.project_id}-default-rtdb.firebaseio.com`;
    console.log(`Using auto-generated databaseURL: ${firebaseConfig.databaseURL}`);
  }
  
  admin.initializeApp(firebaseConfig);
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