# VigilionX — Mobile-Based Citizen Emergency Alert System

A production-ready Flutter + Firebase mobile application for citizen emergency alerts with real-time GPS tracking, SOS alerts, safe trip monitoring, and trusted contact management.

## 🚀 Features

- **🔐 Secure Authentication** — Firebase Auth (email/password) with signup, login, password reset
- **👥 Trusted Contacts** — Full CRUD for emergency contacts with relation categories
- **🆘 SOS Emergency Alert** — One-tap manual SOS with GPS location capture and notification dispatch
- **📍 Real-Time GPS Tracking** — Live location tracking with Google Maps and polyline trail
- **🗺️ Google Maps Integration** — Map preview on dashboard, full-screen tracking, trip destination mapping
- **🛤️ Safe Trip Monitoring** — Set destination & ETA → app monitors → auto-alerts contacts if overdue
- **⏰ Automatic Delay Alerts** — Trip ETA exceeded → automatic SOS to all trusted contacts
- **☁️ Cloud Firestore** — Real-time data for contacts, trips, SOS alerts, and alert logs
- **🔔 Push Notifications** — FCM + local notifications for emergency channels

## 🏗️ Architecture

```
lib/
├── config/           # Theme, constants, routes
├── models/           # Data models (User, Contact, Trip, SOSAlert, AlertLog)
├── providers/        # State management (Auth, Contacts, SOS, Trip)
├── services/         # Firebase services (Auth, Firestore, Location, Notification)
├── screens/          # 14 screens organized by feature
│   ├── splash/
│   ├── onboarding/
│   ├── auth/         # Login, Signup, Forgot Password
│   ├── home/         # Dashboard
│   ├── contacts/     # Trusted contacts management
│   ├── sos/          # Emergency SOS
│   ├── tracking/     # Live GPS tracking
│   ├── trip/         # Safe trip + history
│   ├── alerts/       # Alert history
│   ├── profile/
│   └── settings/
├── widgets/          # Reusable UI components
├── utils/            # Validators, helpers
├── main.dart
└── app.dart
```

**Pattern:** MVVM with Provider for reactive state management.

## 📋 Prerequisites

- Flutter SDK ≥ 3.0
- Firebase project with Auth, Firestore, and FCM enabled
- Google Maps API key
- Android Studio / VS Code with Flutter extensions

## ⚙️ Setup

### 1. Firebase Configuration

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Email/Password** authentication
3. Create a **Cloud Firestore** database
4. Enable **Cloud Messaging**
5. Download config files:
   - **Android**: Place `google-services.json` in `android/app/`
   - **iOS**: Place `GoogleService-Info.plist` in `ios/Runner/`

### 2. Google Maps API Key

1. Enable **Maps SDK for Android/iOS** in Google Cloud Console
2. Add your API key:
   - **Android**: `android/app/src/main/AndroidManifest.xml`
     ```xml
     <meta-data android:name="com.google.android.geo.API_KEY"
                android:value="YOUR_API_KEY"/>
     ```
   - **iOS**: `ios/Runner/AppDelegate.swift`
     ```swift
     GMSServices.provideAPIKey("YOUR_API_KEY")
     ```

### 3. Install & Run

```bash
cd vigilion_x
flutter pub get
flutter run
```

## 🔒 Firestore Collections

| Collection | Purpose |
|---|---|
| `users` | User profiles |
| `emergency_contacts` | Trusted emergency contacts |
| `trips` | Safe trip records |
| `sos_alerts` | SOS alert records |
| `alert_logs` | Notification delivery logs |

## 📱 Screens

| Screen | Description |
|---|---|
| Splash | Animated entrance |
| Onboarding | Feature walkthrough (3 pages) |
| Login/Signup | Firebase Auth forms |
| Home Dashboard | Map preview, stats, SOS FAB, active trip |
| SOS | Pulsing emergency button with confirmation |
| Contacts | Add/edit/delete emergency contacts |
| Live Tracking | Google Maps with real-time location |
| Safe Trip | Start monitored trip with ETA |
| Trip History | All past trips with status |
| Alert History | SOS alert log with locations |
| Profile | View/edit user info |
| Settings | Permissions, logout |

## 🎨 Design

- **Theme**: Dark-first with emergency red (#E53935) + cyan accent (#00E5FF)
- **Typography**: Urbanist font family
- **Components**: Glassmorphic cards, gradient buttons, animated micro-interactions
- **Animations**: Pulse effects, ripple rings, slide transitions
