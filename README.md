# WealthFlow

A premium Flutter app for tracking **Systematic Withdrawal Plans (SWP)** and daily expenses — with Firebase cloud sync, Google/Apple social login, and a stunning animated UI.

---

## Features

### Investments & SWP Tracker
- Add and manage investment portfolios
- Record withdrawals with date and remarks
- Real-time balance tracking with progress rings
- Charts: pie allocation, balance timeline, monthly bar chart

### Expense Logger
- Conversational chat-style expense entry
- 10 categories (Food, Shopping, Fuel, Health, etc.)
- Daily and monthly totals with category breakdown

### Reports
- Across all investments and expenses
- Visual charts with fl_chart

### Auth & Sync
- Google Sign-In
- Apple Sign-In (iOS/macOS)
- All data synced to Firebase Firestore per user
- Each user's data is private and isolated

### UI/UX
- Animated splash screen with rising chart bars
- Dark login screen with Google/Apple buttons
- Light & dark theme toggle
- Material 3 design with Inter font

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x |
| State Management | Riverpod 2.6 |
| Navigation | go_router 14 |
| Database | Cloud Firestore |
| Authentication | Firebase Auth |
| Google Login | google_sign_in |
| Apple Login | sign_in_with_apple |
| Charts | fl_chart |
| Animations | flutter_animate |
| Fonts | Google Fonts (Inter) |

---

## Project Structure

```
lib/
├── core/
│   ├── theme/          # AppTheme, AppColors
│   └── utils/          # formatters (currency, date)
├── data/
│   ├── models/         # Investment, Withdrawal, Expense
│   ├── repositories/   # Firestore CRUD for each model
│   └── services/       # AuthService (Google + Apple sign-in)
├── providers/          # Riverpod providers
│   ├── auth_provider.dart
│   ├── database_provider.dart
│   ├── investment_provider.dart
│   ├── withdrawal_provider.dart
│   ├── expense_provider.dart
│   └── theme_provider.dart
├── router/
│   └── app_router.dart # go_router with auth redirect guard
├── screens/
│   ├── splash/         # Animated splash screen
│   ├── auth/           # Login screen
│   ├── dashboard/      # Investment list + stats
│   ├── investments/    # Add investment, detail + charts
│   ├── withdrawals/    # Add withdrawal
│   ├── expenses/       # Expense list + chat entry
│   ├── reports/        # Reports screen
│   └── settings/       # User profile + sign out + theme
└── widgets/            # Shared UI components
```

---

## Firestore Data Structure

```
users/
  {uid}/
    investments/
      {investmentId}    → investorName, initialAmount, investmentDate, notes, createdAt
    withdrawals/
      {withdrawalId}    → investmentId, amount, withdrawalDate, remarks, createdAt
    expenses/
      {expenseId}       → category, categoryColor, amount, note, date, createdAt
```

Security rules ensure each user can only access their own data.

---

## Firebase Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project
3. Enable **Authentication** → Sign-in method → **Google** (and **Apple** if needed)
4. Enable **Firestore Database** → Create database → Production mode

### 2. Firestore Security Rules

In Firebase Console → Firestore → Rules, publish:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 3. Connect Flutter App

Install FlutterFire CLI and configure:

```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```

This generates `lib/firebase_options.dart` automatically.

### 4. Android — Google Sign-In SHA-1

Get your debug SHA-1:

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android
```

Add the SHA-1 in Firebase Console → Project Settings → Your Android app → Add fingerprint.

### 5. iOS — Apple Sign-In

In Xcode → Signing & Capabilities → add **Sign in with Apple** capability.
Also enable Apple as a sign-in provider in Firebase Console → Authentication.

---

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Build release APK (Android)
flutter build apk --release

# Build release IPA (iOS)
flutter build ipa --release
```

---

## Screenshots

| Splash | Login | Dashboard |
|---|---|---|
| Animated chart bars + teal logo | Google / Apple sign-in | Investment portfolio overview |

| Investment Detail | Add Withdrawal | Settings |
|---|---|---|
| Charts + withdrawal history | Balance banner + form | User profile + sign out |

---

## Version

`1.0.0` — Initial release
