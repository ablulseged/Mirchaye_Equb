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
console.log('FIREBASE_SERVICE_ACCOUNT_BASE64 is set:', !!process.env.FIREBASE_SERVICE_ACCOUNT_BASE64);

// Option 1: Use Base64 encoded value (recommended for multiline JSON)
if (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
  console.log('Using FIREBASE_SERVICE_ACCOUNT_BASE64...');
  try {
    const decoded = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64, 'base64').toString('utf-8');
    console.log('Base64 decoded successfully, attempting JSON parse...');
    serviceAccount = JSON.parse(decoded);
    console.log('✅ Successfully parsed FIREBASE_SERVICE_ACCOUNT_BASE64');
  } catch (err) {
    console.error('❌ Error parsing FIREBASE_SERVICE_ACCOUNT_BASE64:');
    console.error('Error:', err.message);
    console.error('');
    console.error('⚠️  TROUBLESHOOTING:');
    console.error('1. Make sure your Base64 string is valid');
    console.error('2. Generate it using: cat serviceAccountKey.json | base64');
    console.error('3. Or use an online Base64 encoder');
    process.exit(1);
  }
} 
// Option 2: Use direct JSON (must have escaped newlines)
else if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  const envValue = process.env.FIREBASE_SERVICE_ACCOUNT.trim();
  console.log(`FIREBASE_SERVICE_ACCOUNT length: ${envValue.length} characters`);
  console.log(`First 50 characters: ${envValue.substring(0, 50)}...`);
  
  // Normalize newlines: replace real newlines with escaped \n in private_key
  // This handles cases where the JSON was pasted with actual line breaks
  let normalizedJson = envValue;
  
  // If it doesn't start with {, try base64 decode
  if (!envValue.startsWith('{')) {
    console.log('Value does not start with "{", trying base64 decode...');
    try {
      const decoded = Buffer.from(envValue, 'base64').toString('utf-8');
      console.log('Base64 decoded successfully, attempting JSON parse...');
      serviceAccount = JSON.parse(decoded);
      console.log('✅ Successfully parsed FIREBASE_SERVICE_ACCOUNT from base64');
    } catch (base64Err) {
      console.error('❌ Failed to decode as base64');
      console.error('Error:', base64Err.message);
      console.error('');
      console.error('⚠️  Try using FIREBASE_SERVICE_ACCOUNT_BASE64 instead (see Option 1 above)');
      process.exit(1);
    }
  } else {
    // Try parsing as JSON directly
    try {
      console.log('Attempting to parse FIREBASE_SERVICE_ACCOUNT as JSON...');
      
      // Handle real newlines in private_key field by escaping them
      // This is a common issue when copying JSON with actual line breaks
      if (envValue.includes('\n') || envValue.includes('\r')) {
        console.log('Detected real line breaks, normalizing...');
        // Replace actual newlines in the private_key value with escaped \n
        normalizedJson = envValue
          .replace(/-----BEGIN PRIVATE KEY-----[\r\n]+/g, '-----BEGIN PRIVATE KEY-----\\n')
          .replace(/[\r\n]+-----END PRIVATE KEY-----/g, '\\n-----END PRIVATE KEY-----')
          .replace(/(?<!\\n)[\r\n]+(?!-----)/g, '\\n');
      }
      
      serviceAccount = JSON.parse(normalizedJson);
      console.log('✅ Successfully parsed FIREBASE_SERVICE_ACCOUNT as JSON');
    } catch (e) {
      console.error('❌ Error parsing FIREBASE_SERVICE_ACCOUNT as JSON:');
      console.error('Error:', e.message);
      console.error('Value preview (first 100 chars):', envValue.substring(0, 100));
      console.error('');
      console.error('⚠️  TROUBLESHOOTING:');
      console.error('Option 1 (Recommended): Use Base64 encoding');
      console.error('  1. Generate Base64: cat serviceAccountKey.json | base64');
      console.error('  2. Set FIREBASE_SERVICE_ACCOUNT_BASE64 in Render with the Base64 string');
      console.error('');
      console.error('Option 2: Fix the JSON newlines');
      console.error('  1. Replace all real line breaks in private_key with literal \\n');
      console.error('  2. The private_key should look like: "-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----\\n"');
      console.error('  3. Make sure the JSON is valid (use a JSON validator)');
      process.exit(1);
    }
  }
} else {
  console.error('❌ Neither FIREBASE_SERVICE_ACCOUNT nor FIREBASE_SERVICE_ACCOUNT_BASE64 is set.');
  console.error('');
  console.error('Please set one of these in Render Dashboard → Environment:');
  console.error('  1. FIREBASE_SERVICE_ACCOUNT_BASE64 (recommended) - Base64 encoded JSON');
  console.error('  2. FIREBASE_SERVICE_ACCOUNT - Direct JSON with escaped \\n in private_key');
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
      priority: 'high', // High priority for heads-up notifications
      notification: {
        channelId: 'notifications_channel',
        sound: 'default',
        priority: 'high', // High priority for heads-up
        visibility: 'public', // Show on lock screen
        defaultSound: true,
        defaultVibrateTimings: true,
        defaultLightSettings: true,
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