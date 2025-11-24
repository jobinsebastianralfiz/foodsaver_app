# 🔥 Create Firebase Project - Quick Guide

## Option 1: Create via Firebase Console (Recommended - 5 minutes)

### Step 1: Go to Firebase Console
Open: https://console.firebase.google.com/

### Step 2: Create New Project
1. Click **"Add project"** or **"Create a project"**
2. **Project name:** `foodsaver-app`
3. Click **Continue**

### Step 3: Google Analytics (Optional)
- You can **disable** Google Analytics for now (faster setup)
- Or enable it if you want analytics
- Click **Create project**

### Step 4: Wait for Project Creation
- Firebase will create your project (takes ~30 seconds)
- Click **Continue** when done

### Step 5: Enable Authentication
1. In the left sidebar, click **Build** → **Authentication**
2. Click **Get started**
3. Click on **Email/Password**
4. Toggle **Enable** (first switch)
5. Click **Save**

### Step 6: Create Firestore Database
1. In the left sidebar, click **Build** → **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (for development)
4. Select your location (choose closest to you)
5. Click **Enable**

### Step 7: Get Your Project Configuration
Now run this command in your terminal to link your Flutter app:

```bash
flutterfire configure --project=foodsaver-app
```

**Select all platforms when prompted:**
- ✓ android
- ✓ ios
- ✓ macos
- ✓ web

---

## Option 2: Quick Command (If you prefer CLI)

You can also create and configure in one go:

```bash
# Login to Firebase
firebase login

# Create project and configure
flutterfire configure --project=foodsaver-app
```

When prompted, select **"<create a new project>"**

---

## ✅ After Project is Created

### 1. Configure Firestore Rules

#### Option A: Deploy from CLI (Recommended)
The project includes a `firestore.rules` file with all the necessary security rules:

```bash
# Deploy Firestore rules to your project
firebase deploy --only firestore:rules
```

#### Option B: Copy-Paste in Firebase Console
In Firebase Console → Firestore Database → Rules, copy the contents from `firestore.rules` file in your project root and click **Publish**.

The rules include:
- Users can read all user profiles
- Users can create their own profile during registration
- Only admins can approve restaurants (update `isApproved` field)
- Only approved restaurants can create meals
- Proper order access controls

### 2. Create Admin User (Manual Setup)

**IMPORTANT:** Admin users can ONLY be created manually in Firebase Console. They cannot register through the app.

#### Step 2.1: Create Admin in Firebase Authentication
1. In Firebase Console → Authentication → Users
2. Click **Add user**
3. Email: `admin@test.com`
4. Password: `admin123` (change this in production!)
5. Click **Add user**
6. Copy the **User UID** (you'll need it in the next step)

#### Step 2.2: Create Admin User Document in Firestore
1. Go to Firestore Database
2. Click **Start collection** (or add to existing `users` collection)
3. Collection ID: `users`
4. Document ID: [Paste the User UID from step 2.1]
5. Add these fields:
   - `email` (string): `admin@test.com`
   - `name` (string): `Admin User`
   - `phoneNumber` (string): `+1234567890` (optional)
   - `role` (string): `admin` ← **IMPORTANT**
   - `isApproved` (boolean): `true` ← **IMPORTANT**
   - `createdAt` (timestamp): Click the timestamp icon and select current time
   - `updatedAt` (null): Leave as null
6. Click **Save**

### 3. Test Customer Registration (Through App)

**Customers can register through the app:**
1. Run the app: `flutter run -d chrome`
2. Click "Register" on the login screen
3. Select "Customer" role
4. Fill in the registration form
5. Customer accounts are **auto-approved** and can log in immediately

### 4. Test Restaurant Registration (Through App)

**Restaurants can register but need admin approval:**
1. Click "Register" on the login screen
2. Select "Restaurant" role
3. Fill in the registration form
4. After registration, you'll see a "Pending Approval" message
5. The restaurant **cannot log in** until approved by an admin

### 5. Approve Restaurant Accounts (As Admin)

1. Log in as admin (`admin@test.com`)
2. Navigate to the Pending Approvals screen
3. Review and approve/reject restaurant registrations
4. Approved restaurants can now log in

---

## 🚀 Run Your App

After completing the setup:

```bash
# Stop any running instances
# Press 'q' in the terminal running flutter

# Restart the app
flutter run -d chrome
```

Now you can login with:
- `customer@test.com` / `test123`
- `restaurant@test.com` / `test123`
- `admin@test.com` / `test123`

---

## 🎯 Quick Test Checklist

- [ ] Firebase project created: `foodsaver-app`
- [ ] Email/Password authentication enabled
- [ ] Firestore database created
- [ ] Firestore rules configured
- [ ] Test users created in Authentication
- [ ] User documents added to Firestore `users` collection
- [ ] `flutterfire configure` run successfully
- [ ] `firebase_options.dart` file generated
- [ ] App runs without errors
- [ ] Can login with test accounts

---

## 💡 Pro Tips

1. **Copy Firebase Auth UIDs:** When creating Firestore user documents, copy the exact UID from Authentication → Users
2. **Test Mode:** Firestore test mode expires in 30 days - update rules before then
3. **Web Testing:** For web, you might need to enable the web app in Firebase Console

---

## 🆘 Troubleshooting

**"Project not found"**
- Make sure project name matches exactly: `foodsaver-app`
- Try: `firebase projects:list` to see all projects

**"User not found" when logging in**
- Verify user exists in Authentication
- Check user document exists in Firestore with correct UID

**"Permission denied" error**
- Check Firestore rules
- Verify user document has correct role field

---

**That's it! Your Firebase backend is ready!** 🎉
