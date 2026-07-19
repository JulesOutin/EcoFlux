import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecoflux/models/property_models.dart';
import 'package:ecoflux/page/accountScreen.dart';

import '../support/mock_auth_service.dart';
import '../support/mock_data_service.dart';

const _testUser = User(
  id: 'user-1',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

void main() {
  late MockAuthService authService;
  late MockDataService dataService;

  setUp(() {
    authService = MockAuthService();
    dataService = MockDataService();
    when(() => authService.currentUser).thenReturn(_testUser);
  });

  Widget buildSubject() => MaterialApp(
        home: Accountscreen(authService: authService, dataService: dataService),
        routes: {
          '/welcome': (context) => const Scaffold(body: Text('Welcome screen')),
        },
      );

  testWidgets('pre-fills the form from the loaded profile', (tester) async {
    when(() => dataService.getProfile('user-1')).thenAnswer(
      (_) async => const Profile(firstName: 'Jules', lastName: 'Outin'),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Jules'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Outin'), findsOneWidget);
  });

  testWidgets('saving calls updateProfile and shows a confirmation', (tester) async {
    when(() => dataService.getProfile('user-1')).thenAnswer(
      (_) async => const Profile(firstName: 'Jules', lastName: 'Outin'),
    );
    when(() => dataService.updateProfile(
          any(),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
        )).thenAnswer((_) async {});

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    verify(() => dataService.updateProfile(
          'user-1',
          firstName: 'Jules',
          lastName: 'Outin',
        )).called(1);
    expect(find.text('Profil enregistré.'), findsOneWidget);
    verifyNever(() => authService.updatePassword(any()));
  });

  testWidgets('saving with a new password also calls updatePassword', (tester) async {
    when(() => dataService.getProfile('user-1')).thenAnswer(
      (_) async => const Profile(firstName: 'Jules', lastName: 'Outin'),
    );
    when(() => dataService.updateProfile(
          any(),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
        )).thenAnswer((_) async {});
    when(() => authService.updatePassword(any())).thenAnswer((_) async {});

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nouveau mot de passe (optionnel)'),
        'NouveauMdp123!');
    await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    verify(() => authService.updatePassword('NouveauMdp123!')).called(1);
  });

  testWidgets('signing out calls signOut and navigates to /welcome', (tester) async {
    when(() => dataService.getProfile('user-1'))
        .thenAnswer((_) async => const Profile());
    when(() => authService.signOut()).thenAnswer((_) async {});

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Se déconnecter'));
    await tester.pumpAndSettle();

    verify(() => authService.signOut()).called(1);
    expect(find.text('Welcome screen'), findsOneWidget);
  });
}
