# قسطك | Qestak

**Installment Tracking App** — Track and manage installment payments with ease.

---

## Features

### Customer Side
- Login with **Phone Number + National ID**
- View total loan, monthly installment, paid/remaining amounts
- Payment progress ring visualization
- Payment history with timestamps
- Upcoming installment reminders
- Bilingual interface (Arabic / English)

### Admin Side
- Manage customer profiles (add, edit, delete)
- Record payments (cash, transfer, QR)
- View overall statistics with pie charts
- Search and filter customers by status
- Export data to **Excel (.xlsx)** or **CSV**
- Generate QR codes for payment confirmation
- Push notification reminders for due dates

---

## Setup Instructions

### 1. Prerequisites
- Flutter SDK >= 3.2.0
- Dart >= 3.2.0
- Firebase account
- Android Studio or VS Code with Flutter extensions

### 2. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project named **"Qestak"**
3. Enable **Cloud Firestore** (start in test mode)
4. Enable **Firebase Cloud Messaging** for push notifications

#### Android
1. Add an Android app with package name: `com.qestak.app`
2. Download `google-services.json` → place in `android/app/`
3. Follow Firebase's Android setup instructions for Gradle files

#### iOS
1. Add an iOS app with bundle ID: `com.qestak.app`
2. Download `GoogleService-Info.plist` → place in `ios/Runner/`
3. Follow Firebase's iOS setup instructions

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run the App
```bash
flutter run
```

### 5. Default Admin Credentials
On first launch, a default admin account is created:
- **Email:** admin@qestak.com
- **Password:** admin123

> **Important:** Change these credentials in production via Firebase Console.

---

## Project Structure

```
lib/
├── main.dart                  # App entry point
├── config/
│   ├── theme.dart             # App theme & colors
│   └── routes.dart            # Named routes
├── models/
│   └── customer.dart          # Customer & Payment models
├── services/
│   ├── firestore_service.dart # Firebase Firestore operations
│   ├── export_service.dart    # Excel/CSV export
│   └── notification_service.dart # Push notifications
├── providers/
│   ├── auth_provider.dart     # Authentication state
│   ├── customer_provider.dart # Customer data state
│   └── locale_provider.dart   # Language switching
├── screens/
│   ├── splash_screen.dart
│   ├── settings_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── admin_login_screen.dart
│   ├── customer/
│   │   ├── customer_dashboard.dart
│   │   └── payment_history_screen.dart
│   └── admin/
│       ├── admin_dashboard.dart
│       ├── add_customer_screen.dart
│       ├── edit_customer_screen.dart
│       ├── customer_details_screen.dart
│       └── statistics_screen.dart
├── widgets/
│   ├── info_card.dart
│   └── payment_progress_ring.dart
└── l10n/
    └── app_localizations.dart # Arabic + English translations
```

---

## Firestore Data Structure

### `customers` collection
| Field              | Type      | Description              |
|--------------------|-----------|--------------------------|
| name               | string    | الاسم                    |
| phone              | string    | رقم التليفون              |
| nationalId         | string    | الرقم القومي              |
| loanAmount         | number    | إجمالي القرض              |
| installmentValue   | number    | قيمة القسط                |
| paidAmount         | number    | المبلغ المدفوع            |
| totalInstallments  | number    | عدد الأقساط               |
| paidInstallments   | number    | الأقساط المدفوعة          |
| startDate          | timestamp | تاريخ البداية             |
| dueDates           | array     | مواعيد الاستحقاق          |
| payments           | array     | سجل المدفوعات            |
| status             | string    | active / completed / overdue |
| phoneSearch        | string    | For search indexing       |
| nameSearch         | string    | For search indexing       |

### `admins` collection
| Field    | Type   | Description     |
|----------|--------|-----------------|
| email    | string | Admin email     |
| password | string | Admin password  |
| name     | string | Admin name      |

### `payment_logs` collection (audit trail)
| Field      | Type      | Description         |
|------------|-----------|---------------------|
| customerId | string    | Reference to customer |
| amount     | number    | Payment amount       |
| date       | timestamp | Payment date         |
| method     | string    | cash / transfer / qr |

---

## Security Notes

This is a prototype. For production:

1. **Replace plaintext admin passwords** with Firebase Authentication
2. **Tighten Firestore rules** — restrict writes to authenticated admin users
3. **Encrypt National IDs** at rest
4. **Add rate limiting** on login attempts
5. **Use Firebase App Check** to prevent abuse
6. **Hash sensitive data** before storing

---

## License
Private — All rights reserved.
