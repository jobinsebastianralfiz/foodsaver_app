# 🔥 Firebase Setup Guide for FoodSaver App

This guide will help you complete the Firebase configuration for your FoodSaver app.

## ✅ What's Already Done

- ✓ Firebase dependencies added to `pubspec.yaml`
- ✓ FlutterFire CLI installed
- ✓ Authentication service and provider created
- ✓ User model with Firestore integration
- ✓ Login screen with Firebase Auth integration

## 🚀 Steps to Complete Setup

### Step 1: Configure Firebase Project

Run the FlutterFire configuration command:

```bash
flutterfire configure
```

**During configuration:**

1. **Select a project:**
   - Choose `<create a new project>`
   - Enter project name: **`foodsaver-app`**

   OR

   - Select your existing project: `locallabor-bc74b (locallabor)`

2. **Select platforms to configure:**
   - Use arrow keys to navigate
   - Press **Space** to select
   - Select: ✓ android, ✓ ios, ✓ macos, ✓ web
   - Press **Enter** to continue

3. **Wait for configuration:**
   - FlutterFire CLI will automatically:
     - Create/update Firebase apps for each platform
     - Generate `lib/firebase_options.dart` file
     - Configure Firebase for your project

### Step 2: Enable Email/Password Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (**foodsaver-app** or your chosen project)
3. Navigate to **Authentication** → **Sign-in method**
4. Click on **Email/Password**
5. Enable **Email/Password** authentication
6. Click **Save**

### Step 3: Set Up Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (for development)
4. Select a location close to your users
5. Click **Enable**

### Step 4: Configure Firestore Security Rules

In Firestore Console, go to **Rules** tab and update with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Meals collection
    match /meals/{mealId} {
      allow read: if true;
      allow write: if request.auth != null &&
        (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'restaurant' ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }

    // Orders collection
    match /orders/{orderId} {
      allow read: if request.auth != null &&
        (resource.data.userId == request.auth.uid ||
         resource.data.restaurantId == request.auth.uid ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
        (resource.data.userId == request.auth.uid ||
         resource.data.restaurantId == request.auth.uid);
    }
  }
}
```

### Step 5: Create Test User Accounts

#### Option A: Via Firebase Console

1. Go to **Authentication** → **Users**
2. Click **Add user**
3. Create test accounts:

   **Customer Account:**
   - Email: `customer@test.com`
   - Password: `test123`

   **Restaurant Account:**
   - Email: `restaurant@test.com`
   - Password: `test123`

   **Admin Account:**
   - Email: `admin@test.com`
   - Password: `test123`

4. After creating users, go to **Firestore Database**
5. Create a `users` collection
6. For each user, create a document with their Firebase UID as the document ID:

```json
{
  "email": "customer@test.com",
  "name": "Test Customer",
  "phoneNumber": "+1234567890",
  "role": "customer",
  "createdAt": [current timestamp],
  "updatedAt": null
}
```

#### Option B: Via App (After Firebase is configured)

The app's registration screen will automatically create the Firestore user document when a new user registers.

### Step 6: Test the App

1. Stop the running Flutter app (press `q` in terminal)
2. Restart the app:
   ```bash
   flutter run -d chrome
   ```

3. Try logging in with one of your test accounts
4. The app should authenticate and route you based on the user's role!

## 📱 App Behavior After Setup

### Authentication Flow

1. **App Launch** → Shows splash screen while checking auth status
2. **Not Authenticated** → Shows login screen
3. **Authenticated** → Routes to role-specific home:
   - `customer` → Customer home (browse meals)
   - `restaurant` → Restaurant dashboard
   - `admin` → Admin dashboard

### User Roles in Firestore

Each user document in the `users` collection should have:

```json
{
  "id": "firebase_uid",
  "email": "user@example.com",
  "name": "User Name",
  "phoneNumber": "+1234567890",
  "profilePhoto": "https://...",
  "role": "customer",  // or "restaurant" or "admin"
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": null
}
```

## 🔧 Troubleshooting

### Issue: "Firebase project not found"

**Solution:** Make sure you're logged into the correct Google account with Firebase access:
```bash
firebase login
flutterfire configure
```

### Issue: "User not found" error when logging in

**Solution:**
1. Verify the user exists in Firebase Console → Authentication
2. Check that the user document exists in Firestore → users collection
3. Ensure the document ID matches the Firebase UID

### Issue: "Permission denied" in Firestore

**Solution:**
1. Check Firestore Rules are configured correctly
2. For development, you can temporarily use test mode:
   ```javascript
   allow read, write: if true;
   ```
   **⚠️ Change this before production!**

### Issue: App crashes on startup

**Solution:**
1. Make sure `firebase_options.dart` was generated correctly
2. Check that all Firebase dependencies are installed:
   ```bash
   flutter pub get
   ```
3. Clear build cache:
   ```bash
   flutter clean
   flutter pub get
   ```

## 📚 Next Steps

After Firebase is configured:

1. ✅ Test authentication with different user roles
2. 🏗️ Build role-specific home screens
3. 🍔 Create meal browsing for customers
4. 📊 Create restaurant dashboard
5. 👨‍💼 Create admin panel

## 🆘 Need Help?

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)

---

**Once Firebase is configured, your authentication system will be fully functional!** 🎉
