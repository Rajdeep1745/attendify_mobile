# Attendance App Guide

This document is meant to help a new developer or an AI agent understand the structure of this Flutter app quickly and know which files to inspect for each feature.

## 1. What this app does

This is a Flutter mobile app for managing attendance. It supports:

- user login and signup
- batch management
- face-based attendance capture using the camera
- manual attendance marking
- attendance overview, stats, and charts
- profile editing

The app talks to a backend API and stores auth data locally with SharedPreferences.

---

## 2. Tech stack

The app uses:

- Flutter + Dart
- Material UI widgets
- http for API calls
- shared_preferences for local storage
- camera for image capture
- fl_chart for charts
- intl for date formatting

You can see the dependencies in [pubspec.yaml](../pubspec.yaml).

---

## 3. Main folder structure

```text
lib/
  main.dart
  core/
    constants.dart
  models/
    batch_model.dart
  screens/
    attendance_tab.dart
    batches_tab.dart
    camera_screen.dart
    home_tab.dart
    login_screen.dart
    main_shell.dart
    manual_attendance_screen.dart
    preview_screen.dart
    profile_tab.dart
    result_screen.dart
    signup_screen.dart
    splash_screen.dart
  services/
    attendance_service.dart
    auth_service.dart
    batch_service.dart
    profile_service.dart
```

---

## 4. App flow

1. The app starts from [lib/main.dart](../lib/main.dart).
2. [lib/screens/splash_screen.dart](../lib/screens/splash_screen.dart) checks whether a saved auth token exists.
3. If a token exists, the app opens the main shell; otherwise it opens the login screen.
4. The main shell hosts the bottom navigation and manages selected batches.
5. The app then routes to:
   - Home for quick actions
   - Attendance for analytics and daily attendance views
   - Batches for creating and managing batches
   - Profile for editing user info and threshold settings

---

## 5. File-by-file guide

### Entry point

- [lib/main.dart](../lib/main.dart)
  - App entry point.
  - Sets up the Material app and routes for signup and login.
  - Starts from the splash screen.

### Core

- [lib/core/constants.dart](../lib/core/constants.dart)
  - Holds shared app constants.
  - Contains the API base URL used by all services.
  - This is important if the backend address changes.

### Models

- [lib/models/batch_model.dart](../lib/models/batch_model.dart)
  - Defines the BatchModel data structure.
  - Used to represent batch info returned from the API.

### Services

These files are the API/logic layer. If you want to understand network behavior, start here.

- [lib/services/auth_service.dart](../lib/services/auth_service.dart)
  - Handles login and signup requests.
  - Stores the auth token and user info in SharedPreferences after login.

- [lib/services/batch_service.dart](../lib/services/batch_service.dart)
  - Handles batch CRUD operations: get, add, rename, delete.
  - Used by the batches screen and the main shell.

- [lib/services/attendance_service.dart](../lib/services/attendance_service.dart)
  - Handles attendance-related API calls.
  - Includes:
    - uploading attendance images
    - getting statistics
    - getting graph data
    - getting frequent absentees
    - fetching daily attendance
    - saving overrides
    - marking manual attendance
    - fetching students for a batch

- [lib/services/profile_service.dart](../lib/services/profile_service.dart)
  - Fetches and updates the logged-in user profile.
  - Also handles the default attendance threshold.

### Screens

These are the UI pages of the app.

- [lib/screens/splash_screen.dart](../lib/screens/splash_screen.dart)
  - First screen shown on app launch.
  - Checks whether the user is already logged in.

- [lib/screens/login_screen.dart](../lib/screens/login_screen.dart)
  - Login UI.
  - Calls AuthService.login.
  - Navigates to the main shell after success.

- [lib/screens/signup_screen.dart](../lib/screens/signup_screen.dart)
  - Signup UI.
  - Calls AuthService.signup.

- [lib/screens/main_shell.dart](../lib/screens/main_shell.dart)
  - Main application shell.
  - Keeps the bottom navigation bar.
  - Loads batches and manages the selected batch globally.
  - Hosts the Home, Attendance, Batches, and Profile tabs.

- [lib/screens/home_tab.dart](../lib/screens/home_tab.dart)
  - Landing page for the app.
  - Shows current batch summary and quick actions.
  - Provides entry points for automatic attendance capture and manual attendance.

- [lib/screens/camera_screen.dart](../lib/screens/camera_screen.dart)
  - Opens the device camera.
  - Captures an image and sends it to the preview screen.

- [lib/screens/preview_screen.dart](../lib/screens/preview_screen.dart)
  - Shows the captured image before uploading.
  - Calls AttendanceService.uploadAttendance.

- [lib/screens/result_screen.dart](../lib/screens/result_screen.dart)
  - Shows the result of attendance processing.
  - Lets the user review and save the final attendance result.

- [lib/screens/manual_attendance_screen.dart](../lib/screens/manual_attendance_screen.dart)
  - UI for manually marking attendance for students.
  - Fetches students for the selected batch and submits attendance.

- [lib/screens/attendance_tab.dart](../lib/screens/attendance_tab.dart)
  - Main attendance analytics screen.
  - Loads daily attendance data, stats, graphs, and frequent absentees.
  - Displays charts and list views.

- [lib/screens/batches_tab.dart](../lib/screens/batches_tab.dart)
  - Screen for creating, renaming, deleting, and selecting batches.
  - Uses BatchService.

- [lib/screens/profile_tab.dart](../lib/screens/profile_tab.dart)
  - User profile screen.
  - Loads profile data and allows editing name, department, and threshold.

---

## 6. How the app is structured mentally

A good mental model is:

- Screens = UI pages
- Services = backend/API logic
- Models = data classes
- Core = shared constants

The app does not use a complex state manager like Provider, Riverpod, or Bloc. Most state is handled inside StatefulWidget classes.

---

## 7. Important implementation notes

- The API base URL is hardcoded in [lib/core/constants.dart](../lib/core/constants.dart).
- Auth tokens are stored in SharedPreferences under keys such as "token", "name", and "user".
- The selected batch is managed in [lib/screens/main_shell.dart](../lib/screens/main_shell.dart), and many screens depend on it.
- The app uses a local backend API, so the phone/emulator must be able to reach that server.
- Some UI screens are highly feature-rich and may depend on backend responses that are not fully documented by the code alone.

---

## 8. Where to look first for common tasks

### If you want to understand authentication
Look at:
- [lib/screens/login_screen.dart](../lib/screens/login_screen.dart)
- [lib/screens/signup_screen.dart](../lib/screens/signup_screen.dart)
- [lib/services/auth_service.dart](../lib/services/auth_service.dart)

### If you want to understand batch management
Look at:
- [lib/screens/main_shell.dart](../lib/screens/main_shell.dart)
- [lib/screens/batches_tab.dart](../lib/screens/batches_tab.dart)
- [lib/services/batch_service.dart](../lib/services/batch_service.dart)
- [lib/models/batch_model.dart](../lib/models/batch_model.dart)

### If you want to understand attendance capture
Look at:
- [lib/screens/home_tab.dart](../lib/screens/home_tab.dart)
- [lib/screens/camera_screen.dart](../lib/screens/camera_screen.dart)
- [lib/screens/preview_screen.dart](../lib/screens/preview_screen.dart)
- [lib/screens/result_screen.dart](../lib/screens/result_screen.dart)
- [lib/services/attendance_service.dart](../lib/services/attendance_service.dart)

### If you want to understand analytics and reports
Look at:
- [lib/screens/attendance_tab.dart](../lib/screens/attendance_tab.dart)
- [lib/services/attendance_service.dart](../lib/services/attendance_service.dart)

### If you want to understand profile editing
Look at:
- [lib/screens/profile_tab.dart](../lib/screens/profile_tab.dart)
- [lib/services/profile_service.dart](../lib/services/profile_service.dart)

---

## 9. Good AI/dev prompts

Here are useful prompts for an AI assistant working on this project:

- "Explain the app flow from startup to login."
- "Show me the files involved in batch management."
- "How does camera-based attendance work in this app?"
- "Which files are used for analytics and charts?"
- "Where is the API base URL configured?"
- "How is authentication persisted between app launches?"

When answering, the assistant should inspect the relevant files in order:
1. UI screen
2. service layer
3. model/constants if needed

---

## 10. Quick summary for new contributors

If you are new to this project:

- Start with [lib/main.dart](../lib/main.dart) to understand the entry point.
- Then inspect [lib/screens/main_shell.dart](../lib/screens/main_shell.dart) for navigation and shared batch state.
- Then open the relevant screen and its matching service file.
- Use [lib/core/constants.dart](../lib/core/constants.dart) and [pubspec.yaml](../pubspec.yaml) to understand configured API endpoints and dependencies.
