# Mirchaye Equb

A Flutter mobile application for managing Equb groups - traditional rotating savings and credit associations.

## Features

- **Group Management**: Create or join Equb groups with customizable contribution amounts and member limits
- **Member Management**: Invite members, approve join requests, and track member contributions
- **Payment Tracking**: Record contributions, track payment history, and set up payment reminders
- **Spin Wheel**: Fair and transparent random selection for Equb rounds
- **Push Notifications**: Real-time notifications for payments, confirmations, and group updates
- **Multi-language Support**: Available in multiple languages
- **Theme Support**: Light and dark themes

## Tech Stack

- **Framework**: Flutter
- **Backend**: Firebase (Firestore, Authentication, Cloud Messaging)
- **Notification Service**: Render.com (Node.js/Express)
- **State Management**: Provider

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Firebase project setup
- Android Studio / VS Code

### Installation

1. Clone the repository:
```bash
git clone https://github.com/ablulseged/render.git
cd render
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update `firebase_options.dart` with your Firebase configuration

4. Run the app:
```bash
flutter run
```

## Notification Service

The app uses a Render.com service for sending push notifications:
- **Service URL**: `https://render-coz0.onrender.com`
- **Endpoint**: `/api/send-notification`

## Build

### Android APK
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## License

This project is private and proprietary.

good