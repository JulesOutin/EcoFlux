import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecoflux/main.dart';
import 'package:ecoflux/page/propertiesScreen.dart';

import 'support/mock_auth_service.dart';
import 'support/mock_data_service.dart';

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
    when(() => authService.onAuthStateChange)
        .thenAnswer((_) => const Stream.empty());
  });

  Widget buildSubject() => MaterialApp(
        home: AuthGate(authService: authService, dataService: dataService),
      );

  testWidgets('shows Welcome when there is no active session', (tester) async {
    when(() => authService.currentSession).thenReturn(null);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('shows PropertiesScreen when a session is active', (tester) async {
    when(() => authService.currentSession).thenReturn(
      Session(accessToken: 'token', tokenType: 'bearer', user: _testUser),
    );
    when(() => dataService.getProperties()).thenAnswer((_) async => []);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byType(PropertiesScreen), findsOneWidget);
  });
}
