# Smart Attendance — mobile handover

## Current scope and rules

The app uses the sibling [Express/PostgreSQL backend](../attendance-app-cu/handover.md). Public signup is closed; only admin-issued accounts can log in. Attendance is manual and daily, one subject/date record. Programme/semester metadata comes from database responses. Matching academic changes re-enroll students, including previous admin removals. Face-recognition screens/services are retained but hidden and their issues remain deferred in [ISSUES_REVIEW.md](../attendance-app-cu/ISSUES_REVIEW.md).

No new test code was requested. Follow the global opt-in policy in C:/Users/Dell/.codex/test.md; do not add tests without an explicit yes. Existing checks and manual verification are permitted. Read [README.md](README.md) for setup/release instructions and check git status before editing.

## Architecture

Package attendance_app, version 1.0.0+1; Dart constraint ^3.11.5. StatefulWidget/setState, constructor-passed immutable subject lists, Futures and IndexedStack; no external state-management framework.

```text
main.dart → SplashScreen → AuthService.validateSession()
                            ├─ password change → Profile (optional)
                            ├─ teacher → MainShell
                            ├─ student → StudentShell
                            └─ no session → LoginScreen
screens → services → ApiClient/http + JWT → Express /api
                                         ├─ PostgreSQL
                                         └─ retained inactive recognition service
SharedPreferences → token/name/role/serialized user
```

Dependencies remain http/http_parser, shared_preferences, camera, image_picker/image, fl_chart and intl. flutter_dotenv 6.0.1 was added for automatic .env loading. The camera_android_camerax override remains unchanged. JSON clients share 30-second timeouts and 401 handling; multipart teacher avatar upload has a 60-second timeout. Recognition multipart behavior is intentionally unchanged.

## Files and feature map

| File/area                                                               | Responsibility                                                                                     |
| ----------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| lib/main.dart                                                           | App, navigator, login routes and unauthorized-session callback; /signup redirects to login         |
| lib/core/constants.dart                                                 | API_BASE_URL from .env loaded through flutter_dotenv at startup                                    |
| lib/services/api_client.dart                                            | Bounded JSON requests, clears known session keys and triggers login on 401                         |
| lib/services/auth_service.dart                                          | Login/session validation/cache; signup helper returns closed without a network request             |
| lib/services/subject_service.dart                                       | Role-specific API subjects; no static curriculum enrichment/filtering                              |
| lib/models/subject_model.dart                                           | Normalize DB name/program/semester and identity/count/threshold variants                           |
| lib/services/subject_tree_service.dart                                  | Group all returned assigned subjects by programme/semester                                         |
| lib/services/curriculum_service.dart                                    | Compatibility tree data from API subjects, not asset files                                         |
| lib/models/curriculum_model.dart, subject_tree_model.dart               | Programme/semester/subject node types                                                              |
| lib/services/attendance_service.dart                                    | Stats/daily/roster/manual marking/threshold/student reports; retained inactive recognition helpers |
| lib/services/profile_service.dart                                       | Profile/password and teacher avatar; accepts backend default_threshold                             |
| lib/screens/splash_screen.dart                                          | Validate cached session and route directly by role                                                 |
| lib/screens/login_screen.dart                                           | Admin-issued login; password text preserved; no signup link                                        |
| lib/screens/main_shell.dart                                             | Teacher tabs/selected subject; resume session validation                                           |
| lib/screens/student_shell.dart                                          | Student tabs; resume validation and consistent known-key logout                                    |
| lib/screens/home_tab.dart                                               | Teacher stats, DB subject threshold, manual quick action only                                      |
| lib/screens/attendance_tab.dart                                         | Teacher date/stats/absentees; daily percentage reads subjectPercentage                             |
| lib/screens/subjects_tab.dart                                           | Assigned programme/semester tree                                                                   |
| lib/screens/manual_attendance_screen.dart                               | Today's stable date, roster plus existing daily values, full boolean submission                    |
| lib/screens/student_home_tab.dart                                       | Overall percentage, weighted DB attendance_target, today's statuses                                |
| lib/screens/student_attendance_tab.dart                                 | Subject percentage/target and subject history detail                                               |
| lib/screens/student_reports_tab.dart                                    | Overview-first reports, selected subject, explicit impossible/unlimited projections                |
| lib/screens/profile_tab.dart                                            | Role-aware profile; teacher avatar/preferences; corrected default_threshold and zero handling      |
| lib/screens/change_password_screen.dart                                 | Optional profile action; successful change returns to Profile and keeps the session                |
| lib/screens/camera_screen.dart, preview_screen.dart, result_screen.dart | Retained inactive recognition flow; do not repair without authorization                            |
| test/widget_test.dart                                                   | Existing mocked-preference splash/login check; unchanged                                           |
| android/, ios/, web/, desktop folders                                   | Native build/permission scaffolds                                                                  |

## Identity and session behavior

Login requires a valid teacher/student response and persists token,name,role,user. Login, splash and resumed shells go directly to the normal app; no forced password-change flag or redirect remains. Password changes are optional through Profile. New accounts use DEFAULT_ACCOUNT_PASSWORD=12345678; credential CSV downloads remain available. Existing passwords are preserved.

JWTs use ordinary signature/expiry checks with no token version. Password changes do not invalidate existing sessions. Password whitespace is preserved. Session validation GETs /users/me with an eight-second timeout, refreshing cached profile/role on success. Explicit 401/403 clears cached auth; temporary server/network failures can reuse the last user. This is session persistence, not offline attendance synchronization.

Both shells validate on resume. Subject selection is preserved if still assigned and auto-selects only for one teacher subject. Student tabs react to updated subject-list identity rather than only count, so same-sized enrollment changes reload. IndexedStack preserves tab state. Student reports initially show the overall dashboard, not an auto-selected subject.

## Database-driven academics

GET /subject/teacher and /subject/student now both include programme/semester metadata. SubjectModel reads name, program/programme, semester, subject_id/subjectId, threshold and total_students/totalStudents. SubjectTreeService groups every returned subject, including arbitrary database-generated IDs; no local catalogue can hide an assigned subject.

docs/archive/curriculum.json remains only as a historical file and is not in pubspec assets or read by app code. CurriculumService's compatibility loader derives nodes from API subjects. Do not restore fixed programme/semester arrays. Authoritative configured combinations live in academic_programmes/academic_programme_semesters in PostgreSQL. Admin setup and validation are in the sibling repo.

## Active API contracts

baseUrl includes /api and omits trailing slash. Bearer JWT is required for protected routes; errors generally contain error. PostgreSQL numeric fields may be strings.

| Method/path relative to /api              | Contract                                                                                                       |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| POST /auth/login                          | email/password → token,user                                                                                    |
| POST /auth/signup                         | Always 403; mobile helper does not call it                                                                     |
| GET /users/me                             | Flat role profile; default_threshold for teacher; attendance_percentage and attendance_target for student      |
| PATCH /users/me                           | name/department; teacher defaultThreshold in request is camelCase                                              |
| PATCH /users/me/password                  | currentPassword,newPassword; 8–128 chars, different; preserves existing sessions                               |
| PATCH /users/me/avatar                    | Teacher-only multipart avatar JPEG; ≤5 MiB server limit                                                        |
| GET /subject/teacher or /subject/student  | Assigned/enrolled DB subjects with identity, name, programme/semester, threshold/count                         |
| PATCH /subject/:id/threshold              | Integer threshold 0–100                                                                                        |
| GET /students/:id                         | Roster id/name/roll/avatar/attendance; contacts returned to teachers only                                      |
| GET /attendance/:id/stats                 | totalClasses,avgAttendance,bestAttendance,worstAttendance                                                      |
| GET /attendance/:id/daily?date=YYYY-MM-DD | studentId/name/roll/avatar/subjectPercentage/overallPercentage/present (nullable)                              |
| GET /attendance/:id/frequent-absentees    | id/name/absences                                                                                               |
| POST /attendance/:id/mark                 | date,attendance:[{student_id,present}] for every enrolled student; boolean/UUID/date/duplicate validation      |
| PATCH /attendance/:id/override            | date,overrides:[{student_id,present}] for an enrolled subset                                                   |
| GET /attendance/student?date=YYYY-MM-DD   | subjectId/status/recordedAt across enrollments                                                                 |
| GET /subject/:id/overview                 | myAttendance per subject; overallAttendance across subjects; subjectAverage/avgAttendance actual class average |
| GET /subject/:id/reports                  | myAttendance,subjectAverage,class counts,threshold,recentAttendance date/status history                        |

Manual saving loads today's current records first and keeps that date stable while editing. It submits a true boolean for each enrolled ID; missing/foreign/duplicate IDs are rejected. The server locks subject/student rows and commits attendance plus summaries atomically. There are no multiple daily lecture sessions or mobile offline writes. Missing attendance is distinct from Absent.

## Thresholds, profile and projections

Subject visual status uses its DB threshold. Overall target is weighted by recorded subject attendance rows, falling back to enrolled DB subject thresholds when no records exist; it is returned by /users/me as attendance_target. Overall percentage and subject-specific percentage are never interchangeable.

Teacher profile reads default_threshold and exposes only teacher avatar/default-threshold actions; student uses generic labels and does not call the teacher-only avatar route. ProfileService converts selected images to JPEG; profile/manual screens handle data and remote avatars. Recognition result-screen avatar issues remain deferred.

Report classes-needed projection returns an explicit impossible state for 100% after an absence. A 0% target has no minimum-attendance requirement instead of a fabricated 999-class allowance. Keep the overview-first report behavior when modifying selectors.

## Retained recognition behavior — deferred

Home no longer opens camera. The old camera→preview→result flow is retained. Known unfixed issues include faceMedia versus backend faceImages, retake replacement navigation, initialization spinner, and unused roster enrichment. Backend recognition still saves immediately, makes unmatched/unregistered students absent, and overwrites same-day corrections. Model thresholds, Python authentication/liveness and camera platform permissions are deferred. Do not change this pipeline merely to close these findings while the app is manual-only.

## Configuration and release

Set API_BASE_URL=http://<reachable-host>:5000/api in .env for a device; use HTTPS in production. Physical phone localhost means the phone; emulator can use 10.0.2.2. There are no client DB/admin secrets. Its ignored .env is bundled as an asset and loaded by flutter_dotenv before runApp. Use plain flutter run; keep backend secrets on the server. For Flutter web preview at localhost:8080, the default development API CORS allowlist permits that origin.

Android debug builds keep the existing sample identity. Release now requires ATTENDIFY_APPLICATION_ID in private Gradle properties and android/key.properties with a real keystore; see android/key.properties.example. No real signing key or permanent identity was invented. Key files are ignored. Java/Kotlin 17, AGP 8.11.1, Kotlin 2.2.20 and Gradle 9.1.0 remain unchanged.

iOS gallery usage text is present for profile photos. Camera permission/platform recognition validation remains deferred. No physical mobile device was connected during this task; web/desktop previews are not substitutes for device acceptance before release.

## Next-agent workflow and checks

Check both repos' git status, read the relevant service/screen and shared backend contract/schema, preserve existing changes, and coordinate API changes. Use UI UX Pro Max and actual UI review for interfaces. Format only modified files. Ask before adding test code; this task explicitly declined it. Do not weaken the existing widget test.

Use flutter analyze, existing flutter test, builds and manual review as appropriate, and record exact outcomes in the final report. The shared API automatically applies pending versioned migrations before accepting requests; existing-DB composite academic FKs require the database owner's separate SQL step. Updated status for every original finding is in the issue register.

## Verification baseline from the preceding update

- Web production build with CI=true: passed, including the configured ESLint checks.
- Flutter analyze --no-pub: no issues; existing flutter test --no-pub: 1 widget test passed.
- Android debug APK: built successfully; release signing/identity still requires user configuration. Existing AGP/Kotlin future-support warnings remain documented, without a dependency upgrade in this task.
- Backend JavaScript syntax checks, documentation links, formatting and diff whitespace checks: passed.
- Local API checks: signup 403; invalid login types 400; configured admin login/list reads 200; academic options 200; unapproved CORS origin 403. No attendance records/accounts were created or deleted during verification.
- Website and Flutter web login interfaces were visually reviewed; website invalid-login feedback was checked. No physical Android/iOS device was connected; full device/manual-save acceptance remains to be performed.
- No new or modified test code; recognition source files remain unchanged. Existing data was preserved; the applied migration changes schema/security fields only.

## Latest password-policy update

Forced password-change redirects and the required-change screen mode were removed. Login, splash and resume route normally; password changes remain optional in Profile and no longer revoke sessions. The shared API applies pending migrations before listening. New accounts use the configured shared default 12345678; existing passwords are not reset. Flutter analysis and the existing widget test passed; no test code was added or modified.

## Current environment/password policy

New admin-created accounts default to 12345678, with optional password changes and no token-version session revocation. Successful password change returns to Profile instead of logging out. Existing passwords are unchanged. The local .env is ignored by Git and bundled in the app; .env.example is tracked. flutter_dotenv loads API_BASE_URL from the bundled .env automatically; use plain flutter run or flutter build apk. Native Android/iOS calls normally send no Origin and are accepted by the unchanged API CORS rules; Flutter Web still requires an allowed browser origin.
