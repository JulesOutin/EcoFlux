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
  Future<void> addRoom(String name, String icon) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('rooms').insert({
      'user_id': userId,
      'name':    name,
      'icon':    icon,
    });
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    await _supabase.from('rooms').delete().eq('id', roomId);
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
