import 'package:flutter/services.dart';
import '../models/property_models.dart';

abstract class IDataService {
  Future<List<Room>> getRooms();
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
