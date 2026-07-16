import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/property_models.dart';
import 'data_service.dart';

class SupabaseDataService implements IDataService {
  final _supabase = Supabase.instance.client;

  // ── Logements ──────────────────────────────────────────────────────────────

  @override
  Future<List<Property>> getProperties() async {
    final data = await _supabase
        .from('properties')
        .select('id, name, type, address, surface_m2, floor, year_built, position')
        .order('position');
    return data.map(Property.fromMap).toList();
  }

  @override
  Future<void> addProperty(
    String name,
    String type, {
    String? address,
    double? surfaceM2,
    int? floor,
    int? yearBuilt,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final existing = await _supabase
        .from('properties')
        .select('id')
        .eq('user_id', userId);
    final data = <String, dynamic>{
      'user_id':  userId,
      'name':     name,
      'type':     type,
      'position': existing.length,
    };
    if (address != null && address.isNotEmpty) data['address'] = address;
    if (surfaceM2 != null) data['surface_m2'] = surfaceM2;
    if (floor != null) data['floor'] = floor;
    if (yearBuilt != null) data['year_built'] = yearBuilt;
    await _supabase.from('properties').insert(data);
  }

  @override
  Future<void> updateProperty(
    String id,
    String name,
    String type, {
    String? address,
    double? surfaceM2,
    int? floor,
    int? yearBuilt,
  }) async {
    await _supabase.from('properties').update({
      'name':       name,
      'type':       type,
      'address':    (address != null && address.isNotEmpty) ? address : null,
      'surface_m2': surfaceM2,
      'floor':      floor,
      'year_built': yearBuilt,
    }).eq('id', id);
  }

  @override
  Future<void> deleteProperty(String id) async {
    await _supabase.from('properties').delete().eq('id', id);
  }

  @override
  Future<void> reorderProperties(List<String> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      await _supabase
          .from('properties')
          .update({'position': i})
          .eq('id', orderedIds[i]);
    }
  }

  // ── Pièces ─────────────────────────────────────────────────────────────────

  @override
  Future<List<Room>> getRooms(String propertyId) async {
    final data = await _supabase
        .from('rooms')
        .select('id, name, icon, position')
        .eq('property_id', propertyId)
        .order('position');
    return data.map(Room.fromMap).toList();
  }

  @override
  Future<void> addRoom(String propertyId, String name, String icon) async {
    final existing = await _supabase
        .from('rooms')
        .select('id')
        .eq('property_id', propertyId);
    await _supabase.from('rooms').insert({
      'property_id': propertyId,
      'name':        name,
      'icon':        icon,
      'position':    existing.length,
    });
  }

  @override
  Future<void> updateRoom(String id, String name, String icon) async {
    await _supabase
        .from('rooms')
        .update({'name': name, 'icon': icon})
        .eq('id', id);
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

  // ── Capteurs ───────────────────────────────────────────────────────────────

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
