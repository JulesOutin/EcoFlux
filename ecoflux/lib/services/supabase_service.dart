import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/property_models.dart';
import 'data_service.dart';

class SupabaseDataService implements IDataService {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<Room>> getRooms() async {
    final data = await _supabase
        .from('rooms')
        .select('id, name, icon')
        .order('created_at');
    return data.map(Room.fromMap).toList();
  }

  @override
  Stream<List<SensorData>> getSensorData(String roomId) {
    return _supabase
        .from('sensor_readings')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('recorded_at')
        .map((rows) => rows.map(SensorData.fromMap).toList());
  }
}
