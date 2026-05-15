<img width="606" height="1280" alt="photo_2026-05-16_00-20-27" src="https://github.com/user-attachments/assets/f2ec0d56-15c8-45bd-bfa9-c95a705a4585" />


<img width="606" height="1280" alt="photo_2026-05-16_00-20-40" src="https://github.com/user-attachments/assets/1a91d3f6-ae0d-46e5-81ee-02ca9fc7b1d2" />


<img width="606" height="1280" alt="photo_2026-05-16_00-20-47" src="https://github.com/user-attachments/assets/89662d3b-0dea-40a3-af5c-43c8cff5cf9c" />


<img width="606" height="1280" alt="photo_2026-05-16_00-20-51" src="https://github.com/user-attachments/assets/bc6a638b-f1b0-497c-b776-fc0ab3b47f76" />



<img width="606" height="1280" alt="photo_2026-05-16_00-20-56" src="https://github.com/user-attachments/assets/1004642f-8929-4182-9892-8bb74314e722" />



<img width="606" height="1280" alt="photo_2026-05-16_00-21-07" src="https://github.com/user-attachments/assets/a83a700f-0483-41f7-8d48-5817f9b2c869" />




<img width="606" height="1280" alt="photo_2026-05-16_00-21-11" src="https://github.com/user-attachments/assets/0e407fea-0c64-4bdf-beee-e736f3891720" />




<img width="606" height="1280" alt="photo_2026-05-16_00-22-06" src="https://github.com/user-attachments/assets/75d093d9-0d9f-46ae-aac5-77aaca53e1e1" />



<img width="606" height="1280" alt="photo_2026-05-16_00-22-19" src="https://github.com/user-attachments/assets/eb1a939e-df3c-42d8-9381-e177ce72a618" />



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
