import 'package:attendance_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the splash screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const AttendanceApp());

    expect(find.text('Smart Attendance'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 801));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsWidgets);
  });
}
