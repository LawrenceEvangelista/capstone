# testapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

📚 KwentoPinoy – Flutter Story App

A children’s storybook app with narration, quizzes, and Firebase integration.

🚀 Project Overview

KwentoPinoy is a Flutter-based educational app featuring:

Interactive story flipbook

English/Tagalog toggle

Narration audio per page

Quiz per story (Firebase Realtime Database)

Favorites & Recently Viewed

Firebase Authentication (optional)

🛠 Team Setup Guide

This guide ensures any teammate can run the app without repeating MV’s machine-specific fixes.

1️⃣ Install Prerequisites
✔ Flutter SDK

Download (Windows/macOS):
https://flutter.dev/docs/get-started/install

Verify install:

flutter doctor

✔ Android Studio

Install + required SDK tools:

Android SDK 35 or 34

Android Platform Tools

Android Emulator

✔ Node.js

Download LTS:
https://nodejs.org/

Confirm:

node -v
npm -v

✔ Firebase CLI
npm install -g firebase-tools
firebase login

✔ FlutterFire CLI
dart pub global activate flutterfire_cli


Ensure PATH contains:

C:\Users\<yourUser>\AppData\Local\Pub\Cache\bin

2️⃣ Clone the Repository
git clone <repo-url>
cd testapp
flutter pub get

3️⃣ Firebase Setup (IMPORTANT)

You do NOT need to run flutterfire configure.

MV already generated & committed:

android/app/google-services.json

ios/Runner/GoogleService-Info.plist

lib/firebase_options.dart

These files automatically configure the project.

Just run the app normally.

4️⃣ Running the App

Start your Android emulator first.

Then:

flutter run

5️⃣ Common Errors & Fixes
❌ firebase: command not found

✔ Fix:

npm install -g firebase-tools
firebase login

❌ flutterfire: command not found

✔ Fix:

dart pub global activate flutterfire_cli


Then add to PATH:

C:\Users\<YourUser>\AppData\Local\Pub\Cache\bin

❌ Gradle / Android build errors

✔ Always run:

flutter clean
flutter pub get
flutter run

6️⃣ Project Structure
lib/
 ├── features/
 │   ├── stories/
 │   ├── quiz/
 │   ├── favorites/
 │   └── ...
 ├── core/
 ├── providers/
 ├── firebase_options.dart
assets/
android/
ios/
pubspec.yaml

7️⃣ Environment Rules

✔ Do NOT create a new Firebase project
✔ Do NOT replace google-services.json
✔ Do NOT run flutterfire configure unless the team decides
✔ Keep folder structure and filenames consistent

8️⃣ Contacts

For Firebase keys, debugging help, or contributions —
Ask MV (Project Lead).

🎉 You’re Ready!

Welcome to KwentoPinoy development.
Happy coding!
