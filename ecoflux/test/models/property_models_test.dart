import 'package:flutter_test/flutter_test.dart';
import 'package:ecoflux/models/property_models.dart';

void main() {
  group('SensorData', () {
    test('fromCsv parses a valid line', () {
      final data = SensorData.fromCsv('2026-07-18T10:00:00, 21.5, 45.2, 1012.3');

      expect(data.timestamp, DateTime.parse('2026-07-18T10:00:00'));
      expect(data.temperature, 21.5);
      expect(data.humidity, 45.2);
      expect(data.pressure, 1012.3);
    });

    test('fromCsv throws FormatException when a column is missing', () {
      expect(
        () => SensorData.fromCsv('2026-07-18T10:00:00, 21.5, 45.2'),
        throwsFormatException,
      );
    });

    test('fromMap parses a Supabase-style row', () {
      final data = SensorData.fromMap({
        'recorded_at': '2026-07-18T10:00:00',
        'temperature': 21.5,
        'humidity': 45,
        'pressure': 1012,
      });

      expect(data.timestamp, DateTime.parse('2026-07-18T10:00:00'));
      expect(data.temperature, 21.5);
      expect(data.humidity, 45.0);
      expect(data.pressure, 1012.0);
    });

    test('toJson round-trips the values', () {
      final data = SensorData(
        timestamp: DateTime.parse('2026-07-18T10:00:00'),
        temperature: 21.5,
        humidity: 45.2,
        pressure: 1012.3,
      );

      expect(data.toJson(), {
        'timestamp': '2026-07-18T10:00:00.000',
        'temperature': 21.5,
        'humidity': 45.2,
        'pressure': 1012.3,
      });
    });
  });

  group('Room', () {
    test('fromMap parses id, name and icon', () {
      final room = Room.fromMap({'id': 'salon', 'name': 'Salon', 'icon': 'living'});

      expect(room.id, 'salon');
      expect(room.name, 'Salon');
      expect(room.icon, 'living');
      expect(room.readings, isEmpty);
    });
  });

  group('Property', () {
    test('fromMap parses required and optional fields', () {
      final property = Property.fromMap({
        'id': 'p1',
        'name': 'Mon appart',
        'type': 'house',
        'address': '1 rue de Paris',
        'surface_m2': 65,
        'floor': 2,
        'year_built': 1998,
        'position': 3,
      });

      expect(property.id, 'p1');
      expect(property.name, 'Mon appart');
      expect(property.type, 'house');
      expect(property.address, '1 rue de Paris');
      expect(property.surfaceM2, 65.0);
      expect(property.floor, 2);
      expect(property.yearBuilt, 1998);
      expect(property.position, 3);
    });

    test('fromMap falls back to defaults when optional fields are absent', () {
      final property = Property.fromMap({'id': 'p1', 'name': 'Mon appart'});

      expect(property.type, 'apartment');
      expect(property.address, isNull);
      expect(property.surfaceM2, isNull);
      expect(property.floor, isNull);
      expect(property.yearBuilt, isNull);
      expect(property.position, 0);
    });
  });
}
