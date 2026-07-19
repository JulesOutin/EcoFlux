import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecoflux/login/signInScreen.dart';

import '../support/mock_auth_service.dart';

void main() {
  late MockAuthService authService;

  setUp(() {
    authService = MockAuthService();
  });

  Widget buildSubject() => MaterialApp(
        home: Signinscreen(authService: authService),
        routes: {
          '/properties': (context) =>
              const Scaffold(body: Text('Properties screen')),
        },
      );

  testWidgets('shows a validation error when passwords do not match',
      (tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.enterText(find.byType(TextFormField).at(0), 'test@ecoflux.dev');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.enterText(find.byType(TextFormField).at(2), 'different');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
    verifyNever(() => authService.signUp(any(), any()));
  });

  testWidgets('successful sign up calls signUp and navigates', (tester) async {
    when(() => authService.signUp(any(), any())).thenAnswer((_) async {});

    await tester.pumpWidget(buildSubject());
    await tester.enterText(find.byType(TextFormField).at(0), 'test@ecoflux.dev');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    verify(() => authService.signUp('test@ecoflux.dev', 'secret123')).called(1);
    expect(find.text('Properties screen'), findsOneWidget);
  });

  testWidgets('shows the AuthException message on failed sign up', (tester) async {
    when(() => authService.signUp(any(), any()))
        .thenThrow(const AuthException('User already registered'));

    await tester.pumpWidget(buildSubject());
    await tester.enterText(find.byType(TextFormField).at(0), 'test@ecoflux.dev');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('User already registered'), findsOneWidget);
  });
}
