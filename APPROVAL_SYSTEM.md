# Restaurant Approval System

## Overview

The FoodSaver app now implements a role-based registration and approval system with the following requirements:

- **Customers**: Can register through the app and are auto-approved
- **Restaurants**: Can register through the app but require admin approval before they can log in
- **Admins**: Can ONLY be created manually in Firebase Console (not through the app)

## Implementation Details

### 1. User Model Updates

**File**: `lib/data/models/user/user_model.dart`

Added `isApproved` field to track approval status:
- `true` for customers and admins (auto-approved)
- `false` for restaurants (pending approval)

```dart
class UserModel {
  final bool isApproved; // For restaurant approval

  UserModel({
    // ...
    this.isApproved = true, // Customers auto-approved
  });
}
```

### 2. Authentication Repository Updates

**File**: `lib/data/repositories/auth_repository.dart`

#### Login Method (lines 22-60)
- Checks if user is a restaurant with `isApproved = false`
- Signs out unapproved restaurants with clear error message
- Customers and approved restaurants can log in normally

```dart
Future<UserModel> login(String email, String password) async {
  // ... authentication code ...

  // Check if restaurant account is approved
  if (user.role == UserRole.restaurant && !user.isApproved) {
    await _firebaseAuth.signOut();
    throw Exception(
      'Your restaurant account is pending admin approval. '
      'Please wait for approval before logging in.',
    );
  }

  return user;
}
```

#### Register Method (lines 62-107)
- Sets `isApproved = true` for customers
- Sets `isApproved = false` for restaurants

```dart
Future<UserModel> register({...}) async {
  final user = UserModel(
    // ...
    isApproved: role == UserRole.customer, // true for customers, false for restaurants
  );
}
```

### 3. Registration Screen

**File**: `lib/ui/screens/auth/register_screen.dart`

Features:
- Modern UI with role selection (Customer or Restaurant only)
- Form validation for name, email, phone, password
- Different messaging based on role:
  - Customers: Immediate access after registration
  - Restaurants: Shows "Pending Approval" dialog after registration
- Warning message for restaurants about approval requirement

**Role Selection**:
```dart
UserRole _selectedRole = UserRole.customer;

// Two role cards: Customer and Restaurant (no Admin option)
```

**Success Handling**:
```dart
if (_selectedRole == UserRole.restaurant) {
  _showPendingApprovalDialog(); // Shows approval pending message
} else {
  // Customer auto-approved, navigates to home
}
```

### 4. Admin Approval Screen

**File**: `lib/ui/screens/admin/pending_approvals_screen.dart`

Features:
- Real-time stream of pending restaurant registrations
- Beautiful cards showing restaurant details:
  - Restaurant name
  - Email
  - Phone number
  - Registration date
- Approve/Reject actions
- Updates `isApproved` field in Firestore

**Query**:
```dart
_firestore
  .collection('users')
  .where('role', isEqualTo: 'restaurant')
  .where('isApproved', isEqualTo: false)
  .orderBy('createdAt', descending: true)
  .snapshots()
```

**Approve Action**:
```dart
await _firestore.collection('users').doc(userId).update({
  'isApproved': true,
  'updatedAt': Timestamp.now(),
});
```

### 5. Firestore Security Rules

**File**: `firestore.rules`

Key rules for the approval system:

```javascript
match /users/{userId} {
  // Anyone can read user profiles
  allow read: if isAuthenticated();

  // Users can create their own document during registration
  // Customers: isApproved must be true
  // Restaurants: isApproved must be false
  allow create: if isAuthenticated() &&
                  request.auth.uid == userId &&
                  (
                    (request.resource.data.role == 'customer' &&
                     request.resource.data.isApproved == true) ||
                    (request.resource.data.role == 'restaurant' &&
                     request.resource.data.isApproved == false)
                  );

  // Users can update their profile (except role and isApproved)
  allow update: if isAuthenticated() &&
                  request.auth.uid == userId &&
                  request.resource.data.role == resource.data.role &&
                  request.resource.data.isApproved == resource.data.isApproved;

  // Only admins can update isApproved field
  allow update: if isAdmin();

  // Only admins can delete users (for rejecting restaurants)
  allow delete: if isAdmin();
}

match /meals/{mealId} {
  // Only APPROVED restaurants can create meals
  allow create: if isAuthenticated() &&
                  isRestaurant() &&
                  isApproved();
}
```

## User Flows

### Customer Registration Flow

1. User opens app → Login screen
2. Clicks "Register" button
3. Selects "Customer" role
4. Fills in registration form
5. Submits form
6. Account created with `isApproved = true`
7. Automatically logged in and navigated to customer home

### Restaurant Registration Flow

1. User opens app → Login screen
2. Clicks "Register" button
3. Selects "Restaurant" role
4. Sees warning: "Restaurant accounts require admin approval"
5. Fills in registration form
6. Submits form
7. Account created with `isApproved = false`
8. Sees dialog: "Registration Successful - Pending Admin Approval"
9. Cannot log in until admin approves
10. Returns to login screen

### Restaurant Approval Flow (Admin)

1. Admin logs in
2. Navigates to "Pending Approvals" screen
3. Sees list of restaurants awaiting approval
4. Reviews restaurant details
5. Clicks "Approve" button
6. Restaurant's `isApproved` field updated to `true`
7. Restaurant can now log in

### Restaurant Login Attempt (Unapproved)

1. Restaurant tries to log in
2. Authentication succeeds
3. System checks `isApproved` status
4. Finds `isApproved = false`
5. Signs user out immediately
6. Shows error: "Your restaurant account is pending admin approval"
7. Returns to login screen

## Admin User Creation

**IMPORTANT**: Admins can ONLY be created manually in Firebase Console.

### Steps:

1. **Firebase Authentication**:
   - Go to Firebase Console → Authentication → Users
   - Click "Add user"
   - Enter email and password
   - Copy the User UID

2. **Firestore Document**:
   - Go to Firestore Database
   - Collection: `users`
   - Document ID: [Paste User UID]
   - Fields:
     ```json
     {
       "email": "admin@example.com",
       "name": "Admin Name",
       "phoneNumber": "+1234567890",
       "role": "admin",
       "isApproved": true,
       "createdAt": [timestamp],
       "updatedAt": null
     }
     ```

## Testing Checklist

- [ ] Customer can register and log in immediately
- [ ] Restaurant can register but sees "pending approval" message
- [ ] Restaurant cannot log in before approval
- [ ] Admin can log in (created manually)
- [ ] Admin can see pending restaurant registrations
- [ ] Admin can approve restaurants
- [ ] Approved restaurants can log in successfully
- [ ] Unapproved restaurants see appropriate error message
- [ ] Firestore rules prevent unauthorized approval updates
- [ ] Firestore rules prevent unapproved restaurants from creating meals

## File Structure

```
lib/
├── data/
│   ├── models/
│   │   └── user/
│   │       └── user_model.dart          ← isApproved field added
│   └── repositories/
│       └── auth_repository.dart          ← Login/register approval logic
├── providers/
│   └── auth/
│       └── auth_provider.dart            ← Register method
└── ui/
    └── screens/
        ├── auth/
        │   ├── login_screen.dart         ← Updated with register navigation
        │   └── register_screen.dart      ← NEW: Registration UI
        └── admin/
            └── pending_approvals_screen.dart  ← NEW: Approval management

firestore.rules                           ← NEW: Security rules
```

## Next Steps

To complete the setup:

1. **Deploy Firestore Rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **Create Admin User** (follow instructions in CREATE_FIREBASE_PROJECT.md)

3. **Test the Flow**:
   - Register as customer → should auto-approve
   - Register as restaurant → should see pending message
   - Log in as admin → approve restaurant
   - Log in as restaurant → should work after approval

## Documentation Updates

Updated files:
- `CREATE_FIREBASE_PROJECT.md` - Added admin creation and approval workflow instructions
- `APPROVAL_SYSTEM.md` - This file, comprehensive system documentation
