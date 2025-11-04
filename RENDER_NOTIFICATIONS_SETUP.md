# Render Notifications Setup Guide

This guide explains how to set up push notifications using Render instead of Firebase Cloud Functions.

## Prerequisites

1. A Render account (sign up at https://render.com)
2. Firebase service account key (JSON file)
3. Your Render service URL after deployment

## Step 1: Deploy Render Service

1. Navigate to the `render-service` directory
2. Follow the instructions in `render-service/README.md` to deploy the service on Render
3. Make sure to set the `FIREBASE_SERVICE_ACCOUNT` environment variable in Render dashboard

## Step 2: Update Flutter App Configuration

1. Open `lib/services/notification_service.dart`
2. Find the line: `static const String renderApiUrl = 'YOUR_RENDER_API_URL_HERE';`
3. Replace `YOUR_RENDER_API_URL_HERE` with your actual Render service URL
   - Example: `static const String renderApiUrl = 'https://notification-service.onrender.com';`

## Step 3: Test Connection

You can test the connection in several ways:

### Method 1: Using a Browser
Visit: `https://YOUR_RENDER_SERVICE_URL/test`
You should see a JSON response indicating the service is running.

### Method 2: Using Flutter App
The app includes a connection test feature. Check the app logs when notifications are triggered.

### Method 3: Using curl (Command Line)
```bash
curl https://YOUR_RENDER_SERVICE_URL/test
```

## How It Works

1. When a notification is created in your Flutter app, `NotificationService` sends an HTTP POST request to your Render service
2. The Render service receives the request, validates the data, and uses Firebase Admin SDK to send the FCM message
3. The FCM message is delivered to the user's device as a push notification

## Troubleshooting

- **Service not responding**: Check Render dashboard for deployment status
- **Notifications not sending**: Verify `FIREBASE_SERVICE_ACCOUNT` environment variable is set correctly
- **Connection errors**: Ensure your Render service URL is correct in `notification_service.dart` 