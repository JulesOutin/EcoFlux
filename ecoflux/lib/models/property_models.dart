class SensorData {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double pressure;

  const SensorData({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.pressure,
  });

  // Attend une ligne CSV : "2024-01-15T10:30:00,21.5,58.3,1013.2"
  factory SensorData.fromCsv(String line) {
    final parts = line.split(',');
    if (parts.length < 4) throw FormatException('Invalid CSV line: $line');
    return SensorData(
      timestamp:   DateTime.parse(parts[0].trim()),
      temperature: double.parse(parts[1].trim()),
      humidity:    double.parse(parts[2].trim()),
      pressure:    double.parse(parts[3].trim()),
    );
  }

  // Colonnes Supabase : recorded_at, temperature, humidity, pressure
  factory SensorData.fromMap(Map<String, dynamic> map) => SensorData(
    timestamp:   DateTime.parse(map['recorded_at'] as String),
    temperature: (map['temperature'] as num).toDouble(),
    humidity:    (map['humidity']    as num).toDouble(),
    pressure:    (map['pressure']    as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'timestamp':   timestamp.toIso8601String(),
    'temperature': temperature,
    'humidity':    humidity,
    'pressure':    pressure,
  };
}

class Room {
  final String id;
  final String name;
  final String icon;
  final List<SensorData> readings;

  const Room({
    required this.id,
    required this.name,
    required this.icon,
    this.readings = const [],
  });

  factory Room.fromMap(Map<String, dynamic> map) => Room(
    id:   map['id']   as String,
    name: map['name'] as String,
    icon: map['icon'] as String,
  );
}
