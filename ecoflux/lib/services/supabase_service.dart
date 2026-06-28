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
        .order('position');
    return data.map(Room.fromMap).toList();
  }

  @override
  Future<void> addRoom(String name, String icon) async {
    final userId = _supabase.auth.currentUser!.id;
    final existing = await _supabase
        .from('rooms')
        .select('id')
        .eq('user_id', userId);
    await _supabase.from('rooms').insert({
      'user_id':  userId,
      'name':     name,
      'icon':     icon,
      'position': existing.length,
    });
  }

  @override
  Future<void> updateRoom(String id, String name, String icon) async {
    await _supabase.from('rooms').update({'name': name, 'icon': icon}).eq('id', id);
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    await _supabase.from('rooms').delete().eq('id', roomId);
  }

  @override
  Future<void> reorderRooms(List<String> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      await _supabase
          .from('rooms')
          .update({'position': i})
          .eq('id', orderedIds[i]);
    }
  }

  @override
  Stream<List<SensorData>> getSensorData(String roomId) async* {
    while (true) {
      final rows = await _supabase
          .from('sensor_readings')
          .select()
          .eq('room_id', roomId)
          .order('recorded_at', ascending: false)
          .limit(200);
      final readings = rows.map(SensorData.fromMap).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      yield readings;
      await Future.delayed(const Duration(seconds: 10));
    }
  }
}
