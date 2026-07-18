import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ecoflux/models/property_models.dart';
import 'package:ecoflux/services/data_service.dart';

import '../support/mock_data_service.dart';

void main() {
  group('CsvDataService', () {
    // Charge assets/data.csv via rootBundle : nécessite le binding de test.
    TestWidgetsFlutterBinding.ensureInitialized();
    final service = CsvDataService();

    test('getProperties returns the single default property', () async {
      final properties = await service.getProperties();

      expect(properties, hasLength(1));
      expect(properties.single.name, 'Mon logement');
      expect(properties.single.type, 'apartment');
    });

    test('getRooms returns the single default room', () async {
      final rooms = await service.getRooms('default');

      expect(rooms, hasLength(1));
      expect(rooms.single.name, 'Salon');
    });

    test('getSensorData parses every row of assets/data.csv', () async {
      final readings = await service.getSensorData('salon').first;

      expect(readings, hasLength(180));
      expect(readings.first.timestamp, DateTime.parse('2025-09-26'));
      expect(readings.first.temperature, 20.75);
      expect(readings.last.timestamp, DateTime.parse('2026-03-24'));
      expect(readings.last.pressure, 1010.03);
    });

    test('write operations are not supported', () {
      expect(() => service.addProperty('n', 't'), throwsUnimplementedError);
      expect(() => service.updateProperty('id', 'n', 't'), throwsUnimplementedError);
      expect(() => service.deleteProperty('id'), throwsUnimplementedError);
      expect(() => service.reorderProperties(['id']), throwsUnimplementedError);
      expect(() => service.addRoom('p', 'n', 'icon'), throwsUnimplementedError);
      expect(() => service.updateRoom('id', 'n', 'icon'), throwsUnimplementedError);
      expect(() => service.deleteRoom('id'), throwsUnimplementedError);
      expect(() => service.reorderRooms(['id']), throwsUnimplementedError);
    });
  });

  group('MockDataService (mocktail)', () {
    // Sert de gabarit pour les futurs tests d'écrans : on stubbe l'interface
    // au lieu de dépendre d'un vrai backend Supabase.
    late MockDataService dataService;

    setUpAll(() {
      registerFallbackValue(<String>[]);
    });

    setUp(() {
      dataService = MockDataService();
    });

    test('stubbed getProperties returns the configured value', () async {
      const property = Property(id: 'p1', name: 'Test', type: 'house', position: 0);
      when(() => dataService.getProperties()).thenAnswer((_) async => [property]);

      final result = await dataService.getProperties();

      expect(result, [property]);
    });

    test('reorderProperties can be verified', () async {
      when(() => dataService.reorderProperties(any())).thenAnswer((_) async {});

      await dataService.reorderProperties(['a', 'b']);

      verify(() => dataService.reorderProperties(['a', 'b'])).called(1);
    });
  });
}
