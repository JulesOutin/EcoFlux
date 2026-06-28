import 'package:flutter/services.dart';
import '../models/property_models.dart';

abstract class IDataService {
  Future<List<Room>> getRooms();
  Future<void> addRoom(String name, String icon);
  Future<void> updateRoom(String id, String name, String icon);
  Future<void> deleteRoom(String roomId);
  Future<void> reorderRooms(List<String> orderedIds);
  Stream<List<SensorData>> getSensorData(String roomId);
}

class CsvDataService implements IDataService {
  static const _csvPath = 'assets/data.csv';

  // Pas de room_id dans le CSV pour l'instant — une pièce hardcodée en attendant la phase 4
  @override
  Future<List<Room>> getRooms() async {
    return const [
      Room(id: 'salon', name: 'Salon', icon: 'living'),
    ];
  }

  @override
  Future<void> addRoom(String name, String icon) =>
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
  Stream<List<SensorData>> getSensorData(String roomId) {
    return Stream.fromFuture(_loadCsv());
  }

  Future<List<SensorData>> _loadCsv() async {
    final raw = await rootBundle.loadString(_csvPath);
    return raw
        .trim()
        .split('\n')
        .skip(1) // skip header
        .map(SensorData.fromCsv)
        .toList();
  }
}
