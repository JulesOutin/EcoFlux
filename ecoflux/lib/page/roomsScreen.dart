import 'package:flutter/material.dart';
import '../models/property_models.dart';
import '../services/data_service.dart';

class RoomsScreen extends StatefulWidget {
  final IDataService dataService;
  const RoomsScreen({super.key, required this.dataService});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  late Future<List<Room>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    _roomsFuture = widget.dataService.getRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon logement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profil',
            onPressed: () => Navigator.pushNamed(context, '/account'),
          ),
        ],
      ),
      body: FutureBuilder<List<Room>>(
        future: _roomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final rooms = snapshot.data ?? [];
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/dashboard',
                    arguments: room,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_iconFromName(room.icon), size: 48),
                      const SizedBox(height: 8),
                      Text(
                        room.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFromName(String name) {
    const icons = <String, IconData>{
      'living':   Icons.weekend,
      'bedroom':  Icons.bed,
      'kitchen':  Icons.kitchen,
      'bathroom': Icons.bathtub,
      'office':   Icons.computer,
    };
    return icons[name] ?? Icons.room;
  }
}
