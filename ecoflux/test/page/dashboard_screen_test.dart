import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ecoflux/models/property_models.dart';
import 'package:ecoflux/page/dashboardScreen.dart';

import '../support/mock_data_service.dart';

void main() {
  late MockDataService dataService;
  const room = Room(id: 'r1', name: 'Salon', icon: 'living');

  final readings = [
    SensorData(
        timestamp: DateTime(2026, 7, 18),
        temperature: 20,
        humidity: 50,
        pressure: 1013),
    SensorData(
        timestamp: DateTime(2026, 7, 19),
        temperature: 22,
        humidity: 55,
        pressure: 1015),
  ];

  setUp(() {
    dataService = MockDataService();
  });

  Widget buildSubject() => MaterialApp(
        home: DashboardScreen(room: room, dataService: dataService),
        routes: {
          '/account': (context) => const Scaffold(body: Text('Account screen')),
        },
      );

  testWidgets('shows a loading indicator while waiting for data', (tester) async {
    when(() => dataService.getSensorData('r1'))
        .thenAnswer((_) => const Stream<List<SensorData>>.empty());

    await tester.pumpWidget(buildSubject());

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('shows an error message when the stream fails', (tester) async {
    when(() => dataService.getSensorData('r1'))
        .thenAnswer((_) => Stream.error(Exception('offline')));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.textContaining('Erreur'), findsOneWidget);
  });

  testWidgets('shows the temperature chart with an accessible text summary',
      (tester) async {
    when(() => dataService.getSensorData('r1'))
        .thenAnswer((_) => Stream.value(readings));

    final handle = tester.ensureSemantics();
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Température'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Température : dernière valeur 22°C, minimum 20°C, maximum 22°C, '
        '2 relevés affichés.',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('switching tabs shows the humidity chart summary', (tester) async {
    when(() => dataService.getSensorData('r1'))
        .thenAnswer((_) => Stream.value(readings));

    final handle = tester.ensureSemantics();
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Humidité'));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        'Humidité : dernière valeur 55%, minimum 50%, maximum 55%, '
        '2 relevés affichés.',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('the profile button navigates to /account', (tester) async {
    when(() => dataService.getSensorData('r1'))
        .thenAnswer((_) => Stream.value(readings));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Account screen'), findsOneWidget);
  });
}
