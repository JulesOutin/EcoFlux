import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ecoflux/models/property_models.dart';
import 'package:ecoflux/page/propertiesScreen.dart';

import '../support/mock_data_service.dart';

void main() {
  late MockDataService dataService;

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    dataService = MockDataService();
  });

  Widget buildSubject() => MaterialApp(
        home: PropertiesScreen(dataService: dataService),
        routes: {
          '/account': (context) => const Scaffold(body: Text('Account screen')),
        },
      );

  testWidgets('shows the properties returned by the data service', (tester) async {
    when(() => dataService.getProperties()).thenAnswer((_) async => const [
          Property(id: 'p1', name: 'Appart Paris', type: 'apartment', position: 0),
          Property(id: 'p2', name: 'Maison Lyon', type: 'house', position: 1),
        ]);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Appart Paris'), findsOneWidget);
    expect(find.text('Maison Lyon'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows the empty state when there are no properties', (tester) async {
    when(() => dataService.getProperties()).thenAnswer((_) async => []);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text("Aucun logement pour l'instant"), findsOneWidget);
  });

  testWidgets('shows an error snackbar when loading fails', (tester) async {
    when(() => dataService.getProperties()).thenAnswer((_) async => throw Exception('offline'));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.textContaining('Erreur'), findsOneWidget);
  });

  testWidgets('deleting a property confirms then calls the data service', (tester) async {
    const property = Property(id: 'p1', name: 'Appart Paris', type: 'apartment', position: 0);
    when(() => dataService.getProperties()).thenAnswer((_) async => [property]);
    when(() => dataService.deleteProperty(any())).thenAnswer((_) async {});

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer le logement ?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();

    verify(() => dataService.deleteProperty('p1')).called(1);
    verify(() => dataService.getProperties()).called(2); // chargement initial + reload
  });
}
