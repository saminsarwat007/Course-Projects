# Firebase Setup Instructions

Follow these steps to configure Firebase authentication for your Agrothink app:

## Step 1: Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and follow the setup wizard
3. Once created, click "Continue"

## Step 2: Register Your Android App

1. In your Firebase project, click the Android icon to add an Android app
2. Use package name: `com.agrothink.agrothink`
3. Add an optional nickname (e.g., "Agrothink Android")
4. Click "Register app"

## Step 3: Download and Add Configuration File

1. Download the `google-services.json` file
2. Replace the placeholder file at `android/app/google-services.json` with the downloaded file

## Step 4: Enable Authentication Methods

1. In the Firebase Console, go to "Authentication" in the left sidebar
2. Click "Get started" (if not already set up)
3. Enable "Email/Password" authentication method
4. Click "Save"

## Step 5: Set Up Firestore Database

1. In the Firebase Console, go to "Firestore Database" in the left sidebar
2. Click "Create database"
3. Start in test mode (for development) or production mode with specific security rules
4. Choose a location closest to your target users
5. Wait for the database to be provisioned

## Step 6: Security Rules (Important)

Update your Firestore security rules to secure your data. Here's a basic example:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read and write their own data
    match /users/{userId} {
      allow create;
      allow read, update, delete: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 7: Testing

1. Run the app
2. The Firebase authentication should now be working for:
   - User Registration / Sign Up
   - Login / Sign In
   - Password Recovery
   - Logout / Sign Out

## Troubleshooting

- **Build Errors**: Make sure you've added the google-services.json file and updated build.gradle files
- **Authentication Errors**: Check Firebase console logs
- **Database Access Issues**: Review security rules 