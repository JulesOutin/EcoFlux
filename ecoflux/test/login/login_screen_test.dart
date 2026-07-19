import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecoflux/login/loginScreen.dart';

import '../support/mock_auth_service.dart';

void main() {
  late MockAuthService authService;

  setUp(() {
    authService = MockAuthService();
  });

  Widget buildSubject() => MaterialApp(
        home: LoginScreen(authService: authService),
        routes: {
          '/properties': (context) =>
              const Scaffold(body: Text('Properties screen')),
        },
      );

  testWidgets('shows validation errors when fields are empty', (tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
    verifyNever(() => authService.signInWithPassword(any(), any()));
  });

  testWidgets('successful login calls signInWithPassword and navigates',
      (tester) async {
    when(() => authService.signInWithPassword(any(), any()))
        .thenAnswer((_) async {});

    await tester.pumpWidget(buildSubject());
    await tester.enterText(find.byType(TextFormField).at(0), 'test@ecoflux.dev');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    verify(() => authService.signInWithPassword('test@ecoflux.dev', 'secret123'))
        .called(1);
    expect(find.text('Properties screen'), findsOneWidget);
  });

  testWidgets('shows the AuthException message on failed login', (tester) async {
    when(() => authService.signInWithPassword(any(), any()))
        .thenThrow(const AuthException('Invalid login credentials'));

    await tester.pumpWidget(buildSubject());
    await tester.enterText(find.byType(TextFormField).at(0), 'test@ecoflux.dev');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid login credentials'), findsOneWidget);
  });

  testWidgets('shows a generic error snackbar on network failure', (tester) async {
    when(() => authService.signInWithPassword(any(), any()))
        .thenThrow(Exception('offline'));

    await tester.pumpWidget(buildSubject());
    await tester.enterText(find.byType(TextFormField).at(0), 'test@ecoflux.dev');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Erreur réseau, réessaie.'), findsOneWidget);
  });

  testWidgets('meets basic accessibility guidelines (contraste, cibles tactiles)',
      (tester) async {
    await tester.pumpWidget(buildSubject());

    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });
}
