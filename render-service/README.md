# Render Notification Service

This service handles push notifications for the Flutter app using Firebase Cloud Messaging (FCM).

## Setup on Render

1. **Create a new Web Service on Render**
   - Go to https://dashboard.render.com
   - Click "New +" → "Web Service"
   - Connect your GitHub repository

2. **Configure the service**
   - **Name**: notification-service (or any name you prefer)
   - **Environment**: Node
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: Free tier is fine for testing

3. **Set Root Directory** ⚠️ **IMPORTANT**
   - **During Creation**: In the configuration form, find the "Root Directory" field (usually below the build/start commands)
   - **After Creation**: Go to your service → **Settings** tab → Scroll to "Root Directory" section
   - **Value**: Set it to `render-service` (this tells Render where to find your `package.json` and `server.js` files)
   - If you update it after creation, Render will automatically redeploy

4. **Set Environment Variables** ⚠️ **IMPORTANT**
   
   **Option 1 (Recommended): Use Base64**
   - Add `FIREBASE_SERVICE_ACCOUNT_BASE64` with Base64-encoded JSON
   - Generate Base64: `cat serviceAccountKey.json | base64` (or use online tool)
   - See `ENVIRONMENT_SETUP.md` for detailed step-by-step instructions
   
   **Option 2: Use Direct JSON**
   - Add `FIREBASE_SERVICE_ACCOUNT` with your Firebase service account JSON
   - ⚠️ Must have escaped `\n` in private_key (not real newlines)
   - See `ENVIRONMENT_SETUP.md` for detailed step-by-step instructions
   
   To get the service account JSON:
   - Go to Firebase Console → Project Settings → Service Accounts
   - Click "Generate New Private Key"
   - Download the JSON file

5. **Deploy**
   - Click "Create Web Service"
   - Render will build and deploy your service
   - Note the service URL (e.g., `https://notification-service.onrender.com`)

6. **Test the connection**
   - Visit `https://YOUR_SERVICE_URL/test` in your browser
   - You should see: `{"status":"connected","message":"Render notification service is running",...}`

## Update Flutter App

Update the `renderApiUrl` in `lib/services/notification_service.dart`:
```dart
static const String renderApiUrl = 'https://YOUR_SERVICE_URL';
```

Replace `YOUR_SERVICE_URL` with your actual Render service URL. 