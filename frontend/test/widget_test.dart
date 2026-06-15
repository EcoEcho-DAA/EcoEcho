// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/theme/theme_cubit.dart';
import 'package:frontend/features/profile/presentation/settings_view.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('Splash screen rendering smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that CircularProgressIndicator is found on splash page
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Pump with duration to complete the 2-second timer
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('SettingsView rendering smoke test', (WidgetTester tester) async {
    // SharedPreferences mock
    WidgetsFlutterBinding.ensureInitialized();
    
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (context) => ThemeCubit(),
          child: const SettingsView(
            userProfile: {
              'uid': 'test-uid',
              'email': 'test@example.com',
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });
}

