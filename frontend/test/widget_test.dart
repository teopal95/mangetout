// Widget tests for Mangetout.
// These tests render widgets in a headless Flutter environment and verify they
// display the right content — without needing a real device or a running backend.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mangetout_frontend/providers/auth_provider.dart';
import 'package:mangetout_frontend/screens/login_screen.dart';
import 'package:mangetout_frontend/screens/register_screen.dart';

// A minimal router so GoRouter's context.go() calls don't throw in tests.
// We include both / and /register so tapping SIGN UP doesn't crash.
final _testRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (ctx, st) => const LoginScreen()),
    GoRoute(path: '/register', builder: (ctx, st) => const RegisterScreen()),
  ],
);

// Wraps the test app with the same providers that main.dart provides in production.
Widget _app() => ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp.router(routerConfig: _testRouter),
    );

void main() {
  testWidgets('Login screen renders all key elements', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(); // One frame to settle layout

    expect(find.text('Mangetout'), findsOneWidget);
    expect(find.text('Your couple\'s wishlist'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('LOG IN'), findsOneWidget);
    expect(find.text('SIGN UP'), findsOneWidget);
  });

  testWidgets('Login screen shows validation errors on empty submit',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    // Tap LOG IN without filling any field
    await tester.tap(find.text('LOG IN'));
    await tester.pump();

    // Both validator messages should appear
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });
}
