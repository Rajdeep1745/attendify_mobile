# Smart Attendance — Flutter app

Flutter client for the [website's shared Express/PostgreSQL backend](../attendance-app-cu/README.md). Read [handover.md](handover.md) for architecture and [issue statuses](../attendance-app-cu/ISSUES_REVIEW.md) for deferred work.

## Current behavior

- Signup is closed. Only administrators issue accounts through the website.
- Attendance is manual and daily: one record per subject/date. Recognition entry points are hidden; its implementation/issues remain preserved and deferred.
- Programme, semester, subject and enrollment data come from the backend/database. The old curriculum asset is no longer bundled or read.
- New accounts use the default password 12345678 and can sign in immediately. Password changes are optional and keep existing sessions signed in.
- Teacher tabs: Home, Attendance, Subjects, Profile. Student tabs: Home, Attendance, Reports, Profile.
- Profiles are role-aware; only teachers edit avatars/default thresholds. Student reports use configured DB targets and distinguish overall from selected-subject attendance.

## Setup

Use Flutter with Dart compatible with pubspec's `^3.11.5`. Start the sibling API/database, then:

Copy [.env.example](.env.example) to .env for a new checkout, then set API_BASE_URL to the reachable backend address. The local .env was created without overwriting existing values. For a physical phone, replace localhost with the server LAN address. Then run:

```powershell
flutter pub get
flutter devices
flutter run
```

`API_BASE_URL` includes `/api` without a trailing slash. It is read from the bundled .env by flutter_dotenv before runApp; restart the app after changing it. No extra command-line flags are required. A physical phone needs a reachable computer LAN address; Android emulator usually uses 10.0.2.2. Phone localhost refers to the phone. Supply HTTPS for production and keep backend secrets off the client.

The app has no offline attendance queue. Cached sessions survive a temporary outage, but attendance/API calls still require network. Active JSON calls time out after 30 seconds; teacher avatar uploads after 60 seconds. Authentication failures clear the session and return to login.

## Manual workflow

1. Receive your account and initial password from the administrator.
2. Sign in with the administrator-provided password; change it through Profile if desired.
3. Teachers select an assigned DB subject and open Manual Attendance; existing records for today are loaded before editing.
4. Submit an explicit present/absent value for every enrolled student. The date stays fixed while editing; the backend commits records and aggregates transactionally.
5. Students view their attendance, subject history and reports. Matching programme/semester changes re-enroll students, by the chosen policy.

## Checks

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug
```

No new test code was added, as requested. Existing [widget_test.dart](test/widget_test.dart) covers splash-to-login only; run existing checks without implying broader coverage. No physical mobile device was connected during this update. Camera/recognition behavior is deferred.

## Android release identity and signing

The application ID uniquely identifies the installed app/store listing. A release signing key proves that later updates come from the same publisher. Keep that key and its passwords private and backed up.

Development retains the current sample ID; release builds intentionally require your own configuration:

1. Choose a permanent application ID and set `ATTENDIFY_APPLICATION_ID` in private Gradle properties.
2. Create/provide a release keystore; copy [key.properties.example](android/key.properties.example) to ignored `android/key.properties` and supply its details.
3. Build release only after identity/signing are configured. Debug signing is no longer silently used for release.

Java/Kotlin target is 17; AGP 8.11.1, Kotlin 2.2.20, Gradle 9.1.0. The CameraX override is retained because recognition is out of scope. iOS gallery purpose text is configured for profile photos; camera recognition permission/device validation remains deferred.

## Code map

`lib/main.dart` handles app startup/navigation and session expiry; `core/constants.dart` defines configurable API origin; `services/` contains API/auth/profile/attendance/subject access; `models/` normalizes subject/tree data; `screens/` contains teacher/student shells, manual attendance, profile/password and retained inactive recognition screens. `docs/archive/curriculum.json` is a historical unbundled file, never an academic source of truth. Platform scaffolds do not establish full camera support on every target.
