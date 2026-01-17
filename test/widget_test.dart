// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_workload_optimizer/main.dart';

void main() {
  testWidgets('App launches and shows splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DoctorWorkloadApp());

    // Verify that splash screen is shown
    expect(find.text('Doctor Workload'), findsOneWidget);
    expect(find.text('Optimizer'), findsOneWidget);
    expect(find.byIcon(Icons.medical_services), findsOneWidget);
  });

  testWidgets('Splash screen navigates to login after delay', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DoctorWorkloadApp());

    // Verify splash screen is shown
    expect(find.text('Doctor Workload'), findsOneWidget);

    // Wait for 3 seconds (splash screen timer)
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Verify navigation to login screen
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
  });

  testWidgets('Login screen has email and password fields', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DoctorWorkloadApp());

    // Wait for navigation to login
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Verify login screen elements
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Login button can be tapped', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DoctorWorkloadApp());

    // Wait for navigation to login
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Find and tap login button
    final loginButton = find.widgetWithText(ElevatedButton, 'Login');
    expect(loginButton, findsOneWidget);

    // Enter some text in email field
    await tester.enterText(find.byType(TextField).first, 'doctor@test.com');

    // Tap the login button
    await tester.tap(loginButton);
    await tester.pump();

    // Verify loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Dashboard has bottom navigation with 4 items', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DoctorWorkloadApp());

    // Wait for splash screen
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Enter credentials
    await tester.enterText(find.byType(TextField).first, 'doctor@test.com');
    await tester.enterText(find.byType(TextField).last, 'password');

    // Tap login
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));

    // Wait for navigation to dashboard
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify bottom navigation bar exists with 4 items
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Queue'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Home screen displays welcome message', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DoctorWorkloadApp());

    // Wait for splash screen
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Enter credentials
    await tester.enterText(find.byType(TextField).first, 'testdoctor');
    await tester.enterText(find.byType(TextField).last, 'password');

    // Tap login
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));

    // Wait for navigation to dashboard
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify welcome message
    expect(find.textContaining('Hello, Dr.'), findsOneWidget);
    expect(find.text('Here\'s your workload overview'), findsOneWidget);
  });

  testWidgets('Quick actions are displayed on home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DoctorWorkloadApp());

    // Navigate to dashboard
    await tester.pumpAndSettle(const Duration(seconds: 4));
    await tester.enterText(find.byType(TextField).first, 'doctor');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify quick actions exist
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('AI Triage'), findsOneWidget);
    expect(find.text('Shift Handover'), findsOneWidget);
    expect(find.text('Burnout Analysis'), findsOneWidget);
    expect(find.text('Voice Documentation'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches between screens', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DoctorWorkloadApp());

    // Navigate to dashboard
    await tester.pumpAndSettle(const Duration(seconds: 4));
    await tester.enterText(find.byType(TextField).first, 'doctor');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Tap on Queue tab
    await tester.tap(find.text('Queue'));
    await tester.pumpAndSettle();

    // Tap on Tasks tab
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    // Tap on Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Tap back on Home tab
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hello, Dr.'), findsOneWidget);
  });
}