# Agrothink

A Flutter application for intelligent agricultural management and decision support, powered by generative AI.

## Getting Started

This project is a Flutter application for agricultural management with built-in analytics and AI-powered recommendations.

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase as per the FIREBASE_SETUP.md file
4. Run `flutter run` to start the application

## Application Overview

AgroThink is a comprehensive Flutter application designed for the agricultural sector, featuring a dual interface for both farmers and government officials. It moves beyond simple data display, leveraging **Generative AI** and **Computer Vision** to provide hyper-personalized farming plans, automated task scheduling, and real-time agricultural intelligence.

### Core Features

1. **AI Chatbot Assistant**
   - Leverages a Large Language Model to provide instant, conversational advice on farming techniques, pest control, crop selection, and more.

2. **AI-Powered Plant Disease Detection**
   - Uses a Computer Vision AI model to analyze photos of crops/plants.
   - Identifies diseases with high accuracy and provides detailed treatment recommendations.
   - Maintains a history of previous scans for tracking and reference.

3. **AI-Generated Planting Guides**
   - Dynamically generates comprehensive, step-by-step planting guides.
   * The AI tailors each guide to the specific seed (identified by name or photo) and the farmer's exact geographical location for hyper-personalized advice.

4. **AI-Automated Task Management**
   - Features a smart To-Do list with a calendar view.
   * Can automatically parse an AI-generated planting guide to suggest and schedule all necessary farming tasks, from soil preparation to harvest.

5. **Government Information Hub**
   - A centralized feed that displays important updates on weather conditions, official market prices, and agricultural news.
   - All content in this hub is published and managed directly by authorized government officials through their own interface.

6. **Dual User Interface**
   - **Farmer Dashboard**: A rich, interactive interface providing access to the full suite of AI tools (Chatbot, Disease Detection, Guide Generator, Task Manager) and the Information Hub.
   - **Government Dashboard**: A secure administrative portal that allows officials to publish and manage the content seen by farmers. It also serves as the foundation for future data analytics on agricultural trends.

## Project Structure

For beginners, here's how the project is organized:

```
lib/
├── config/            # App configuration files
│   ├── constants.dart # App-wide constants
│   ├── routes.dart    # Navigation routes
│   └── theme.dart     # UI theme settings
│
├── models/            # Data models
│   ├── user_model.dart
│   ├── chatbot_message_model.dart
│   ├── disease_detection_model.dart
│   └── news_model.dart
│
├── providers/         # State management
│   ├── auth_provider.dart
│   ├── chatbot_provider.dart
│   ├── disease_detection_provider.dart
│   └── news_provider.dart
│
├── screens/           # App screens
│   ├── auth/          # Authentication screens
│   ├── onboarding/    # Onboarding screens
│   ├── user/          # Farmer user screens
│   └── government/    # Government official screens
│
├── widgets/           # Reusable UI components
│   ├── custom_app_bar.dart
│   ├── custom_button.dart
│   ├── feature_card.dart
│   └── ...
│
└── main.dart          # App entry point
```

## Technical Architecture

### Frontend Design

- **Provider Pattern**: The app uses the Provider package for state management
- **Widget Composition**: UI screens are built from reusable widget components
- **Route Management**: Navigation handled through named routes in the AppRoutes class

### Backend Integration

- **Firebase Authentication**: Handles user registration, login, and session management
- **Cloud Firestore**: Stores user data, messages, disease detection history, and news
- **Firebase Storage**: Stores images for disease detection

### Data Flow

1. User interactions trigger methods in provider classes
2. Providers execute logic and Firebase operations
3. Results update the app state, notifying listeners
4. UI rebuilds with the updated data

### User Authentication

- Regular users (farmers) can register and login with email and password
- Government officials use special credentials with domain validation
- User type determines which dashboard is shown after login

## Building and Distributing APK

To build and distribute the APK:

1. Run the build script:
   ```
   ./build_apk.sh
   ```

2. The script will:
   - Clean the project
   - Get dependencies
   - Build a release APK
   - Copy it to the `distribution` folder with a date-based version name
   - Display the APK location and size

3. The built APK will be available at:
   - Original: `build/app/outputs/flutter-apk/app-release.apk`
   - Versioned copy: `distribution/agrothink_YYYYMMDD.apk`
   - Latest version: `distribution/agrothink_latest.apk`

4. Share the APK through your preferred distribution method:
   - Host the distribution folder on a web server
   - Share via email, cloud storage, or direct download
   - Users can follow instructions in `APK_INSTALLATION.md` for installation

## Deploying Firestore Rules

To fix the permission denied error, deploy the updated Firestore security rules:

1. Install Firebase CLI if you haven't already:
   ```
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```
   firebase login
   ```

3. Initialize Firebase in your project (if not already done):
   ```
   firebase init
   ```
   - Select Firestore when prompted for which services to configure
   - When asked about rules file, point to the location of your `firestore.rules` file

4. Deploy the security rules:
   ```
   firebase deploy --only firestore:rules
   ```

## For Beginners: Getting Started with Development

If you're new to the project, here are some tips to help you navigate the codebase:

1. Start by looking at the `main.dart` file to understand how the app initializes
2. Explore the `screens` folder to see the different app screens
3. Look at the `providers` folder to understand how state is managed
4. Check the `models` folder to understand the data structures used
5. The UI components in the `widgets` folder are reused throughout the app

To make changes:
1. For UI changes, modify the relevant screen or widget files
2. For business logic changes, modify the provider classes
3. For data structure changes, modify the model classes
4. Run the app to test your changes using `flutter run`