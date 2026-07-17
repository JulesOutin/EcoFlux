import 'package:flutter/services.dart';
import '../models/property_models.dart';

abstract class IDataService {
  // Logements
  Future<List<Property>> getProperties();
  Future<void> addProperty(String name, String type, {String? address, double? surfaceM2, int? floor, int? yearBuilt});
  Future<void> updateProperty(String id, String name, String type, {String? address, double? surfaceM2, int? floor, int? yearBuilt});
  Future<void> deleteProperty(String id);
  Future<void> reorderProperties(List<String> orderedIds);

  // Pièces
  Future<List<Room>> getRooms(String propertyId);
  Future<void> addRoom(String propertyId, String name, String icon);
  Future<void> updateRoom(String id, String name, String icon);
  Future<void> deleteRoom(String roomId);
  Future<void> reorderRooms(List<String> orderedIds);

  // Capteurs
  Stream<List<SensorData>> getSensorData(String roomId);
}

class CsvDataService implements IDataService {
  static const _csvPath = 'assets/data.csv';

  @override
  Future<List<Property>> getProperties() async => const [
    Property(id: 'default', name: 'Mon logement', type: 'apartment', position: 0),
  ];

  @override
  Future<void> addProperty(String name, String type, {String? address, double? surfaceM2, int? floor, int? yearBuilt}) =>
      throw UnimplementedError('CsvDataService ne supporte pas addProperty');

  @override
  Future<void> updateProperty(String id, String name, String type, {String? address, double? surfaceM2, int? floor, int? yearBuilt}) =>
      throw UnimplementedError('CsvDataService ne supporte pas updateProperty');

  @override
  Future<void> deleteProperty(String id) =>
      throw UnimplementedError('CsvDataService ne supporte pas deleteProperty');

  @override
  Future<void> reorderProperties(List<String> orderedIds) =>
      throw UnimplementedError('CsvDataService ne supporte pas reorderProperties');

  @override
  Future<List<Room>> getRooms(String propertyId) async => const [
    Room(id: 'salon', name: 'Salon', icon: 'living'),
  ];

  @override
  Future<void> addRoom(String propertyId, String name, String icon) =>
      throw UnimplementedError('CsvDataService ne supporte pas addRoom');

  @override
  Future<void> updateRoom(String id, String name, String icon) =>
      throw UnimplementedError('CsvDataService ne supporte pas updateRoom');

  @override
  Future<void> deleteRoom(String roomId) =>
      throw UnimplementedError('CsvDataService ne supporte pas deleteRoom');

  @override
  Future<void> reorderRooms(List<String> orderedIds) =>
      throw UnimplementedError('CsvDataService ne supporte pas reorderRooms');

  @override
  Stream<List<SensorData>> getSensorData(String roomId) =>
      Stream.fromFuture(_loadCsv());

  Future<List<SensorData>> _loadCsv() async {
    final raw = await rootBundle.loadString(_csvPath);
    return raw.trim().split('\n').skip(1).map(SensorData.fromCsv).toList();
  }
}
