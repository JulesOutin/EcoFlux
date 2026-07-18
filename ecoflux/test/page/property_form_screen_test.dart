import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ecoflux/models/property_models.dart';
import 'package:ecoflux/page/propertyFormScreen.dart';

import '../support/mock_data_service.dart';

void main() {
  late MockDataService dataService;

  setUp(() {
    dataService = MockDataService();
  });

  // Pousse le formulaire par-dessus un écran de base, comme le fait
  // PropertiesScreen._openForm via Navigator.push, pour pouvoir vérifier
  // qu'un save réussi referme bien l'écran.
  Widget buildSubject({Property? property}) => MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PropertyFormScreen(
                      dataService: dataService,
                      property: property,
                    ),
                  ),
                ),
                child: const Text('Open form'),
              ),
            ),
          ),
        ),
      );

  Future<void> openForm(WidgetTester tester, {Property? property}) async {
    await tester.pumpWidget(buildSubject(property: property));
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
  }

  testWidgets('create mode shows an empty form with the Ajouter button', (tester) async {
    await openForm(tester);

    expect(find.text('Nouveau logement'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Ajouter'), findsOneWidget);
    expect(find.text(''), findsWidgets); // champs vides
  });

  testWidgets('edit mode pre-fills the fields from the existing property', (tester) async {
    const property = Property(
      id: 'p1',
      name: 'Appart Paris',
      type: 'house',
      address: '1 rue de Paris',
      surfaceM2: 65,
      floor: 2,
      yearBuilt: 1998,
      position: 0,
    );

    await openForm(tester, property: property);

    expect(find.text('Modifier le logement'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Enregistrer'), findsOneWidget);
    expect(find.text('Appart Paris'), findsOneWidget);
    expect(find.text('1 rue de Paris'), findsOneWidget);
    expect(find.text('65'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1998'), findsOneWidget);
  });

  testWidgets('shows a validation error and does not save when the name is empty', (tester) async {
    await openForm(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Ajouter'));
    await tester.pumpAndSettle();

    expect(find.text('Champ requis'), findsOneWidget);
    verifyNever(() => dataService.addProperty(any(), any(),
        address: any(named: 'address'),
        surfaceM2: any(named: 'surfaceM2'),
        floor: any(named: 'floor'),
        yearBuilt: any(named: 'yearBuilt')));
  });

  testWidgets('an invalid year blocks save', (tester) async {
    await openForm(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Chalet');
    await tester.enterText(find.byType(TextFormField).at(4), '50');
    await tester.tap(find.widgetWithText(FilledButton, 'Ajouter'));
    await tester.pumpAndSettle();

    expect(find.text('Année invalide'), findsOneWidget);
    verifyNever(() => dataService.addProperty(any(), any(),
        address: any(named: 'address'),
        surfaceM2: any(named: 'surfaceM2'),
        floor: any(named: 'floor'),
        yearBuilt: any(named: 'yearBuilt')));
  });

  testWidgets('saving a new property calls addProperty with the picked type and closes the screen',
      (tester) async {
    when(() => dataService.addProperty(any(), any(),
        address: any(named: 'address'),
        surfaceM2: any(named: 'surfaceM2'),
        floor: any(named: 'floor'),
        yearBuilt: any(named: 'yearBuilt'))).thenAnswer((_) async {});

    await openForm(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Maison Lyon');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Maison'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(2), '90');
    await tester.tap(find.widgetWithText(FilledButton, 'Ajouter'));
    await tester.pumpAndSettle();

    verify(() => dataService.addProperty('Maison Lyon', 'house',
        address: null, surfaceM2: 90, floor: null, yearBuilt: null)).called(1);
    expect(find.text('Open form'), findsOneWidget); // l'écran s'est refermé
  });

  testWidgets('editing calls updateProperty with the property id', (tester) async {
    const property = Property(id: 'p1', name: 'Appart Paris', type: 'apartment', position: 0);
    when(() => dataService.updateProperty(any(), any(), any(),
        address: any(named: 'address'),
        surfaceM2: any(named: 'surfaceM2'),
        floor: any(named: 'floor'),
        yearBuilt: any(named: 'yearBuilt'))).thenAnswer((_) async {});

    await openForm(tester, property: property);

    await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    verify(() => dataService.updateProperty('p1', 'Appart Paris', 'apartment',
        address: null, surfaceM2: null, floor: null, yearBuilt: null)).called(1);
  });

  testWidgets('shows a generic error snackbar when saving fails', (tester) async {
    when(() => dataService.addProperty(any(), any(),
        address: any(named: 'address'),
        surfaceM2: any(named: 'surfaceM2'),
        floor: any(named: 'floor'),
        yearBuilt: any(named: 'yearBuilt'))).thenAnswer((_) async => throw Exception('offline'));

    await openForm(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Maison Lyon');
    await tester.tap(find.widgetWithText(FilledButton, 'Ajouter'));
    await tester.pumpAndSettle();

    expect(find.text('Erreur réseau, réessaie.'), findsOneWidget);
    expect(find.text('Open form'), findsNothing); // l'écran reste ouvert
  });
}
