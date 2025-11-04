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

4. **Set Environment Variables**
   - Add `FIREBASE_SERVICE_ACCOUNT` with your Firebase service account JSON
   - To get the service account:
     - Go to Firebase Console → Project Settings → Service Accounts
     - Click "Generate New Private Key"
     - Copy the entire JSON and paste it as the environment variable value

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