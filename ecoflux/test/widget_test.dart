import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecoflux/welcome.dart';

void main() {
  testWidgets('Welcome screen shows login and sign up actions', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Welcome()));

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
  });

  testWidgets('Tapping Login navigates to /login', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const Welcome(),
      routes: {
        '/login': (context) => const Scaffold(body: Text('Login screen')),
      },
    ));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Login screen'), findsOneWidget);
  });
}
