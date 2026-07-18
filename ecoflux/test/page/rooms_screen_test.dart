import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ecoflux/models/property_models.dart';
import 'package:ecoflux/page/roomsScreen.dart';

import '../support/mock_data_service.dart';

void main() {
  late MockDataService dataService;

  const property = Property(id: 'prop1', name: 'Mon appart', type: 'apartment', position: 0);

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    dataService = MockDataService();
  });

  Widget buildSubject() => MaterialApp(
        home: RoomsScreen(property: property, dataService: dataService),
        routes: {
          '/account': (context) => const Scaffold(body: Text('Account screen')),
        },
      );

  testWidgets('shows the rooms returned by the data service', (tester) async {
    when(() => dataService.getRooms('prop1')).thenAnswer((_) async => const [
          Room(id: 'r1', name: 'Salon', icon: 'living'),
          Room(id: 'r2', name: 'Cuisine', icon: 'kitchen'),
        ]);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Salon'), findsOneWidget);
    expect(find.text('Cuisine'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows the empty state when there are no rooms', (tester) async {
    when(() => dataService.getRooms('prop1')).thenAnswer((_) async => []);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Aucune pièce pour l\'instant'), findsOneWidget);
  });

  testWidgets('shows an error snackbar when loading fails', (tester) async {
    when(() => dataService.getRooms('prop1')).thenAnswer((_) async => throw Exception('offline'));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.textContaining('Erreur'), findsOneWidget);
  });

  testWidgets('adding a room calls addRoom then reloads', (tester) async {
    when(() => dataService.getRooms('prop1')).thenAnswer((_) async => []);
    when(() => dataService.addRoom(any(), any(), any())).thenAnswer((_) async {});

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Cuisine');
    await tester.tap(find.widgetWithText(FilledButton, 'Ajouter'));
    await tester.pumpAndSettle();

    verify(() => dataService.addRoom('prop1', 'Cuisine', 'living')).called(1);
    verify(() => dataService.getRooms('prop1')).called(2); // chargement initial + reload
  });

  testWidgets('deleting a room confirms then calls the data service', (tester) async {
    when(() => dataService.getRooms('prop1')).thenAnswer((_) async => const [
          Room(id: 'r1', name: 'Salon', icon: 'living'),
        ]);
    when(() => dataService.deleteRoom(any())).thenAnswer((_) async {});

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer la pièce ?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();

    verify(() => dataService.deleteRoom('r1')).called(1);
    verify(() => dataService.getRooms('prop1')).called(2);
  });
}
