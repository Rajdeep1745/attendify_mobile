# Smart Attendance — Flutter app

Flutter client for the Smart Attendance website's shared API. Teachers can browse assigned subjects, mark manual attendance, capture a classroom photo for recognition, review results, and view daily statistics. Students can view enrolled subjects, attendance, reports, and their profile.

Read [handover.md](handover.md) for architecture, file locations, API contracts, and known integration gaps. The [website/backend project](../attendance-app-cu/README.md) contains Express, PostgreSQL, and Python recognition services. This app does not perform recognition on the device. Documentation reflects **23 November 2026**.

## Stack

- Flutter / Dart; package name `attendance_app`, version `1.0.0+1`.
- Dart SDK constraint `^3.11.5`; use a Flutter SDK that includes a compatible Dart version.
- Material widgets, `http`, `shared_preferences`, `camera`, `image_picker`, `image`, `fl_chart`, and `intl`.
- Bundled subject catalogue: `assets/curriculum.json`.

## Setup and run

1. Start the backend from the sibling project using its README. PostgreSQL is needed for app data; Python is needed for recognition.
2. Update [lib/core/constants.dart](lib/core/constants.dart) to the reachable API address. It currently contains a developer-specific LAN address. The value must include `/api` and omit a trailing slash:

   ```dart
   const String baseUrl = 'http://<backend-host>:5000/api';
   ```

   A physical phone needs the computer's reachable LAN address, usually on the same Wi-Fi. Android emulator can use `http://10.0.2.2:5000/api`. `localhost` on a phone refers to the phone. Permit port 5000 through the host firewall as appropriate. Verify platform cleartext/HTTPS policy if HTTP requests fail.

3. Install packages and run on a connected device:

   ```powershell
   flutter pub get
   flutter devices
   flutter run -d <device-id>
   ```

The app has no `.env`, build-flavor, or `--dart-define` API configuration. Change the source constant and rebuild/restart as needed. Keep DB/admin/JWT secrets on the backend.

## App flow

- Splash validates the saved token through `/users/me`, then opens the teacher or student shell.
- Login persists the JWT and user in SharedPreferences. Network failures can reuse a cached session; 401/403 clears it.
- Teacher tabs: Home, Attendance, Subjects, Profile. Select a subject to take attendance.
- Student tabs: Home, Attendance, Reports, Profile. Reports initially show an overview before selecting a subject.
- Manual attendance submits a real boolean for every enrolled student, using today's device date.
- Camera capture opens preview, uploads one photo, then shows results/corrections. **The current upload contract is incompatible with the backend; see below.**
- Profiles support personal detail editing and password changes. Teacher avatar upload is implemented; student avatar upload is rejected by the current backend route.

Admin management and student face registration are available through the website, not through dedicated mobile screens.

## Known integration gaps

| Area | Current issue |
| --- | --- |
| Face attendance | Mobile sends multipart `faceMedia`; active backend requires `faceImages`. Recognition cannot work against the reviewed backend until aligned. |
| Student signup | Mobile omits `program` and `semester`, which the backend requires. Use web signup/admin import meanwhile. |
| Subjects | The model discards API name/programme data and enriches from the static curriculum asset. Teacher tree excludes IDs absent from that asset, including new database-created subjects. |
| Results | Backend attendance rows lack names/roll/avatar. ResultScreen fetches a roster map but does not use it to enrich displayed rows. |
| Profile | Reads `defaultThreshold`, while the backend returns `default_threshold`; shared profile also offers teacher-only avatar behavior to students. |

Face recognition saves attendance immediately on the server; final corrections are a second request. A rerun for the same subject/date replaces previous records. All enrolled students not recognized, including those without face templates, are marked absent until corrected.

## Checks and builds

```powershell
flutter analyze
flutter test
flutter build apk --release
```

The checked-in test is [test/widget_test.dart](test/widget_test.dart), covering splash-to-login with mocked SharedPreferences. It does not cover API, camera, or attendance flows. See the handover for the documentation-review check results; the commands above are not a claim of successful execution.

Android uses Java/Kotlin target 17, AGP 8.11.1, Kotlin 2.2.20, and Gradle 9.1.0. CameraX is deliberately overridden to `0.7.4+8` in `pubspec.yaml`; preserve it unless validating an upgrade. Android release currently uses debug signing and placeholder application ID `com.example.attendance_app`.

Android camera/internet permissions are present. iOS runner configuration lacks camera/photo-library usage descriptions and requires platform validation. Web/desktop scaffold directories exist, but the file-path camera/preview upload flow uses `dart:io`; cross-platform feature support is not established. Test camera behavior on an actual target device.

## Repository map

- `lib/main.dart`: app entry and login/signup routes.
- `lib/core/constants.dart`: API base URL.
- `lib/screens/`: teacher/student shells, tabs, camera/preview/results, authentication, profile/password screens.
- `lib/services/`: authentication, profile, attendance, subject, and curriculum API/asset access.
- `lib/models/`: subject and programme/semester tree models.
- `assets/`: curriculum and logo.
- `test/`: existing widget test.
- Platform directories: native launch/build settings.

The older [docs/APP_GUIDE.md](docs/APP_GUIDE.md) describes obsolete batch files and flows. Use this README and handover as the current reference. No license file or complete release pipeline is present.
