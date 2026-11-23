# Smart Attendance — mobile handover

## Start here

Snapshot: **23 November 2026**, reviewed from the local working tree. This is the starting context for a new chat/AI agent. Setup is in [README.md](README.md); backend context is in the sibling [website handover](../attendance-app-cu/handover.md). The app shares the website's Express API/PostgreSQL data and sends photos to that API; recognition is performed by the backend's Python service, not Flutter.

Observed mobile HEAD: `7df2f7c` (`update ui and fix bugs`). Working tree was clean before this documentation task. This task changes only README.md and handover.md. The old docs/APP_GUIDE.md refers to batch_model.dart, batch_service.dart, and batches_tab.dart, which are absent. Treat it as historical. The student_subject_selector_update directory is empty in this snapshot; active code is under lib/.

## Architecture and dependencies

Package attendance_app, version 1.0.0+1; pubspec Dart constraint ^3.11.5. Flutter Material widgets with StatefulWidget/setState, constructor-passed subjects, local Futures, and IndexedStack navigation. No Provider/BLoC/Riverpod or generated routing layer is used.

```text
main.dart → SplashScreen → AuthService.validateSession()
                             ├─ teacher → MainShell
                             ├─ student → StudentShell
                             └─ no usable session → LoginScreen
screens → static service methods → http + bearer JWT
                                      └─ sibling Express :5000/api
                                           ├─ PostgreSQL
                                           └─ Python :5001 (RetinaFace/ArcFace)
SharedPreferences → token, name, role, serialized user
assets/curriculum.json → local subject metadata/tree enrichment
```

Dependencies: http/http_parser for JSON/multipart, shared_preferences for session persistence, camera for capture, image_picker/image for gallery avatars/JPEG conversion, fl_chart for reports, intl for formatting. flutter_test and flutter_lints exist; flutter_launcher_icons config targets Android using assets/logo.png. Preserve the camera_android_camerax override 0.7.4+8 until a device-tested reason to change it.

## File map and screens

| Path | Responsibility |
| --- | --- |
| lib/main.dart | runApp, MaterialApp, SplashScreen home, named /login and /signup routes |
| lib/core/constants.dart | Single source-coded baseUrl; includes /api |
| lib/screens/splash_screen.dart | Session validation, 500 ms minimum delay, role dispatch |
| lib/screens/login_screen.dart | Form, AuthService login, role shell navigation |
| lib/screens/signup_screen.dart | Name/email/department/password/role only; missing academic fields |
| lib/screens/main_shell.dart | Teacher Home/Attendance/Subjects/Profile, subject selection, app-resume session validation |
| lib/screens/student_shell.dart | Student Home/Attendance/Reports/Profile; no equivalent resume observer |
| lib/screens/home_tab.dart | Teacher selected subject, stats/today's attendance, threshold, camera/manual quick actions |
| lib/screens/attendance_tab.dart | Teacher daily date selection, stats and frequent absentees; refresh |
| lib/screens/subjects_tab.dart | Programme/semester tree of assigned subjects; calls SubjectTreeService |
| lib/screens/manual_attendance_screen.dart | Roster, absent-by-default boolean map, bulk/toggle controls, full submission |
| lib/screens/camera_screen.dart | Camera lifecycle/capture; disposes before preview navigation |
| lib/screens/preview_screen.dart | Image.file preview, upload, result navigation, retake currently pops |
| lib/screens/result_screen.dart | Recognition attendance toggles and override save; roster enrichment gap |
| lib/screens/student_home_tab.dart | Profile overall percentage plus today's subject attendance |
| lib/screens/student_attendance_tab.dart | Subject percentages; includes StudentSubjectAttendanceScreen with report/history details |
| lib/screens/student_reports_tab.dart | Overview across subjects, selected-subject reports, charts, threshold projections |
| lib/screens/profile_tab.dart | Shared personal details, default threshold, gallery avatar, password navigation |
| lib/screens/change_password_screen.dart | Current/new/confirm form and backend password change |
| lib/services/auth_service.dart | Login, session validation/cache, clearing session, signup |
| lib/services/attendance_service.dart | Teacher/student attendance, stats, roster, threshold, uploads/overrides |
| lib/services/profile_service.dart | Get/update profile, change password, gallery image → JPEG avatar upload |
| lib/services/subject_service.dart | Role-specific subjects API and asset enrichment |
| lib/services/curriculum_service.dart | Parse assets/curriculum.json into programme/semester/subject nodes |
| lib/services/subject_tree_service.dart | Intersect catalogue with assigned subject IDs |
| lib/models/subject_model.dart | Identity/threshold/count plus locally enriched display metadata |
| lib/models/curriculum_model.dart | ProgrammeNode, SemesterNode, SubjectNode |
| lib/models/subject_tree_model.dart | ProgrammeTreeNode, SemesterTreeNode, SubjectTreeNode |
| test/widget_test.dart | Mocked preferences; splash-to-login widget test |
| analysis_options.yaml | flutter_lints; excludes native platform folders and build outputs |
| android/, ios/, web/, windows/, macos/, linux/ | Platform scaffolds; existence does not establish feature support |

Design is Material with purple accents, pale backgrounds, rounded cards, custom local styles, snackbars, loading and empty states. There is no shared application-wide design-token/widget library. For future UI changes, follow supplied AGENTS instructions: use UI UX Pro Max, preserve existing behavior, and inspect the actual UI on target devices. Tailwind-first applies where applicable to web styling; Flutter uses native widget styling.

## Session and navigation rules

AuthService.login POSTs credentials with a 10-second timeout, checks the JSON shape/token/teacher-or-student role, then stores token,name,role,user. It returns `{success,data}` or `{success:false,message}`. Login routes by returned role.

validateSession reads cached user, GETs /users/me with an 8-second timeout, accepts a flat profile or data wrapper, refreshes cached fields on success, and clears only on explicit 401/403. Network errors, malformed responses, 404s, or server failures generally preserve a cached user. This supports opening the shell during temporary outage; it does not provide offline attendance synchronization. Backend data calls still need network.

Splash validates then dispatches by role. Teacher MainShell observes app resume and revalidates/reloads subjects; it preserves selected subject if still assigned and auto-selects only when exactly one subject is available. It groups choices by programme/semester. StudentShell loads subjects initially without equivalent resume validation. Teacher logout uses clearSession (four known keys); student logout clears all SharedPreferences.

Both shells use IndexedStack so tabs retain state. Child didUpdateWidget/refresh methods drive data reloads; some student tabs compare only list length, so same-sized enrollment changes can remain stale. Many services have no explicit timeout or shared 401 interceptor. Loading failures sometimes look like empty/zero data rather than a persistent error panel.

## Subject catalogue mismatch

Backend database is now authoritative for names, programmes, semesters, enrollments, and assignments. Mobile still follows an older static-catalogue model:

1. SubjectService requests /subject/teacher or /subject/student according to saved role.
2. SubjectModel.fromJson accepts subject_id or subjectId and count naming variants, but initializes name="", programme="", semester=0, ignoring API display metadata.
3. SubjectService loads assets/curriculum.json and enriches by matching subject ID.
4. SubjectTreeService iterates the asset catalogue and includes only IDs assigned by backend. IDs absent from the asset disappear from the Subjects tree.

Admin can create arbitrary subject IDs (including generated UUID strings), so new DB subjects may have blank metadata and be absent from the mobile tree. Do not blindly copy the asset into the database or restore deleted web programmes.js files. A future fix should normalize database metadata in the model/service/tree and coordinate any student endpoint additions; student list currently lacks programme/semester. Keep fallback compatibility only where useful.

## Shared backend/data contracts

baseUrl includes /api; paths below are relative to it. Protected requests use Authorization: Bearer <token>. Errors generally use `{error}`. PostgreSQL numeric values can be strings; existing helpers parse both. Admin login is intentionally not supported by mobile AuthService.

| Method/path | Mobile usage and expected shape |
| --- | --- |
| POST /auth/login | email,password → token and user with id/name/email/role/avatar |
| GET /users/me | Flat profile; teacher default_mode/default_threshold; student attendance_percentage/face_registered/roll_no |
| POST /auth/signup | Mobile sends name,email,password,department,role; backend additionally requires program/semester for student |
| PATCH /users/me | name,department,defaultThreshold (camelCase request is correct) |
| PATCH /users/me/password | currentPassword,newPassword; backend validates 8–128 chars and difference |
| PATCH /users/me/avatar | Multipart avatar JPEG; backend teacher-only |
| GET /subject/teacher | Array of DB subjects with subject_id,name,program,semester,threshold,total_students |
| GET /subject/student | Array subjectId,name,threshold,totalStudents,teacher,joinedOn |
| PATCH /subject/:id/threshold | threshold → DB-shaped subject |
| GET /students/:id | Roster array id,name,roll,avatar,faceRegistered,attendance and contact/profile fields |
| GET /attendance/:id/stats | totalClasses,avgAttendance,bestAttendance,worstAttendance |
| GET /attendance/:id/graph | Array date,attendance_percentage; helper exists |
| GET /attendance/:id/daily?date=YYYY-MM-DD | studentId,name,roll,avatar,subjectPercentage,overallPercentage,present (nullable) |
| GET /attendance/:id/frequent-absentees | id,name,absences array |
| POST /attendance/:id/mark | date,attendance:[{student_id,present}] for all enrollments |
| POST /attendance/:id/face | Backend requires multipart faceImages plus date; current client incorrectly sends faceMedia |
| PATCH /attendance/:id/override | date,overrides:[{student_id,present}] |
| GET /attendance/student?date=YYYY-MM-DD | subjectId,status,recordedAt for each enrolled subject |
| GET /subject/:id/overview | myAttendance selected-subject percentage; overallAttendance and avgAttendance currently both overall student percentage |
| GET /subject/:id/reports | subjectId,subjectName,myAttendance,subjectAverage,totalClasses,attendedClasses,threshold,recentAttendance:[{date,status}] |

Database identity: users.id equals students.student_id or teachers.teacher_id. Enrollments join student to subject. Programme/semester triggers synchronize enrollments when students/subjects are created or moved. Teacher access is assigned-subject ownership; student access is enrollment. Subject threshold is an attendance target, distinct from face similarity threshold.

Attendance has one student/subject/date row, not multiple same-day lecture sessions. Overall percentage is present/all recorded rows across subjects; subject percentage is separate. Missing record is not an absence: teacher daily returns null, student daily labels No Class. No local attendance queue/offline write mode exists.

## Attendance and camera behavior

ManualAttendanceScreen loads roster, initializes every student absent, supports changes, and submits every enrollment. Dates are device-local DateTime.now().toIso8601String().split("T").first. Backend manual API requires the full enrolled roster and rejects foreign/missing IDs. Existing manual flow has no date selector or preload of prior values.

CameraScreen uses cameras[0], ResolutionPreset.high, audio disabled. It observes inactive/paused/resumed states, guards double capture/disposal, and releases the camera before pushReplacement to preview. Preserve these lifecycle guards when changing capture.

Preview uses dart:io File and Image.file; uploads one JPEG path and today's date, then pushReplacement to ResultScreen. Retake currently pops to the previous route instead of explicitly recreating CameraScreen because camera→preview uses replacement. Camera init/no-camera failures only log and can leave an indefinite spinner.

**Critical mismatch:** AttendanceService.uploadAttendance uses multipart faceMedia; active backend multer accepts repeated faceImages only. Align the field before claiming mobile recognition works. The backend supports 1–8 JPEG/PNG/WebP images ≤10 MiB each; mobile currently captures one only. There is no mobile gallery/multi-image/video attendance workflow.

Once the contract is aligned, Node loads enrolled 512-value ArcFace templates, calls Python with cosine threshold 0.5, unions matches across images, and immediately saves all students. Unrecognized/unregistered students become absent. The response attendance rows contain student_id,present,auto_recognized,has_face,similarity,observations,image_indices, without names/roll/avatar. The service injects subjectId and date into the result for correction.

ResultScreen fetches roster into studentMap but renders attendance rows directly, so names show Unknown and roll '-' unless enriched. Saving toggles maps student_id/present to overrides. The server has already saved recognition by then: abandoning this screen does not undo it. A rerun overwrites previous corrections. Server attendance writes/recalculations are not one transaction.

Face registration itself is only available in the website. Backend accepts 1–2 faceImages ≤5 MiB each, verifies identity/quality, stores 512-dimensional templates, sets face flag, and uses first photo as avatar. Mobile has no registration API helper/screen.

## Student reports and profile

StudentHomeTab loads overall attendance_percentage from /users/me and daily subject statuses. StudentAttendanceTab loads each subject overview and opens a report/history detail screen. StudentReportsTab starts with an overall overview (selectedSubject=null), then loads selected-subject reports. Preserve the overview-first behavior.

Report projections calculate classes needed as ceil((target × total − attended)/(1 − target)) and classes that can be missed as floor(attended/target − total), clamped at zero with special cases. Some colors still hardcode 75/60 rather than using the selected subject threshold; do not confuse visual bands with backend targets. Overview averages across subject percentages differ from the cached overall percentage weighted by recorded classes.

ProfileService converts selected gallery images to JPEG, uploads field avatar, and returns the updated avatar string. ProfileTab is shared by roles but uses teacher-centric fallback labels and offers the teacher-only avatar action to students (403). It reads defaultThreshold, while backend GET returns default_threshold, so saved thresholds may display as 75 after reload. PATCH defaultThreshold is correct. Server profile GET is flat; compatibility data wrappers in clients do not imply every endpoint wraps results.

Avatar values may be remote URLs or inline data URLs. ResultScreen and ManualAttendanceScreen assume base64 in some rendering paths; remote avatar URLs need consistent handling in future fixes. Password change does not revoke existing server JWTs.

## Configuration, platforms, and release

lib/core/constants.dart currently hardcodes a developer LAN URL. Do not treat it as a production endpoint or copy its private address into new environments. The required form is http://<host>:5000/api (no trailing slash). Web config differs: REACT_APP_BACKEND_URL is origin with trailing slash and excludes /api.

Physical phone: use reachable host LAN address and firewall/network access. Android emulator: host usually 10.0.2.2. Phone localhost means the phone. HTTPS/cleartext rules can block local HTTP; main Android manifest has INTERNET/CAMERA permissions but no explicit cleartext allowance. Duplicate INTERNET declarations exist. No env/flavors/dart-define config currently exists.

Backend must run from sibling project with PostgreSQL credentials and JWT/admin variables; Python must run for recognition. Keep API credentials/DB secrets server-side; client only stores its session token.

Android: placeholder com.example.attendance_app namespace/applicationId; Java/Kotlin target 17; AGP 8.11.1, Kotlin 2.2.20, Gradle 9.1.0; Flutter-derived SDK/NDK values. Release uses debug signing, so production identity/signing is unfinished.

iOS Info.plist lacks camera/photo-library usage descriptions and needs validation before camera/gallery use. Web/desktop directories are scaffolded; dart:io/file uploads and platform camera availability mean equivalent support is not established. Test on physical target devices. No complete CI/release pipeline is configured.

## Known priorities for future work

1. Align faceMedia→faceImages and add an API contract regression test before device recognition testing.
2. Add backend-driven academic choices and program/semester to mobile student signup; web already exposes GET /academic/options. Do not hardcode schema choices.
3. Normalize subject metadata from backend; remove asset-dependent visibility for new IDs while preserving valid assignments.
4. Enrich ResultScreen rows from roster by student_id; standardize data/remote avatar rendering.
5. Make shared profile role-aware and map default_threshold correctly. Preserve password text rather than applying signup's whitespace trimming indiscriminately.
6. Improve camera permission/error/retry and retake paths; preserve disposal lifecycle. Validate after capture, background/resume, repeat capture, denial, and no-camera cases.
7. Cover stale response/subject selection changes, same-sized enrollment changes, loading/error states, session expiry, and network failures. Most requests lack explicit timeouts.
8. Reconcile overall vs per-subject percentages, hardcoded color bands, and report projections at 0/100% targets with tests before behavior changes.
9. Harden deployment (HTTPS, token storage, proper signing/IDs/permissions) and coordinate shared backend changes with the website.

## Tests and next-agent workflow

Existing test/widget_test.dart mocks empty SharedPreferences, renders AttendanceApp, checks splash title, advances time, and expects Login. It does not cover API calls, camera, enrollment, recognition, or reports. flutter_lints is configured. Use flutter analyze, flutter test, and dart format for future Dart changes; device builds/smoke tests are required for camera/platform changes.

Documentation-task checks: local Markdown links, balanced code fences, title/whitespace checks, and git diff --check passed. flutter test --no-pub was attempted but stalled without output and was interrupted. A direct invocation of the installed Flutter tool then reported that it could not open C:\Users\Dell\flutter\bin\cache\lockfile because the SDK cache was not writable in this environment. The widget test therefore did not execute; no passing result is claimed. Flutter analysis, device builds, and camera/API smoke flows were not run. No backend/app behavior was changed and no new automated behavior tests were added for these Markdown-only changes.

For the next task: check git status in both repos; read this handover and the relevant service/screen only; verify shared router/controller and schema before changing contracts. Preserve business logic and user changes. Follow supplied AGENTS instructions (including UI skill/actual UI review and backend unit/integration/regression tests). Recommend a backend framework before introducing one, since the shared backend has no configured test suite. Update both handovers when API/model/enrollment semantics change.
