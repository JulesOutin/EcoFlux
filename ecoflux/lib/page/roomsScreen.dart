// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/property_models.dart';
import '../services/data_service.dart';

class RoomsScreen extends StatefulWidget {
  final Property property;
  final IDataService dataService;
  const RoomsScreen({super.key, required this.property, required this.dataService});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  List<Room> _rooms = [];
  bool _loading = true;

  static const _iconOptions = <String, IconData>{
    'living':   Icons.weekend,
    'bedroom':  Icons.bed,
    'kitchen':  Icons.kitchen,
    'bathroom': Icons.bathtub,
    'office':   Icons.computer,
    'garage':   Icons.garage,
    'garden':   Icons.yard,
  };

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final rooms = await widget.dataService.getRooms(widget.property.id);
      setState(() {
        _rooms = rooms;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  IconData _iconData(String name) => _iconOptions[name] ?? Icons.room;

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final room = _rooms.removeAt(oldIndex);
      _rooms.insert(newIndex, room);
    });
    widget.dataService.reorderRooms(_rooms.map((r) => r.id).toList());
  }

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    String selectedIcon = 'living';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nouvelle pièce'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nom de la pièce',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Icône', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _iconPicker(selectedIcon, (v) => setLocal(() => selectedIcon = v)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    try {
      await widget.dataService.addRoom(widget.property.id, name, selectedIcon);
      _reload();
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException (addRoom): ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Une erreur est survenue, réessaie.')),
      );
    }
  }

  Future<void> _showEditDialog(Room room) async {
    final nameController = TextEditingController(text: room.name);
    String selectedIcon =
        _iconOptions.containsKey(room.icon) ? room.icon : 'living';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Modifier la pièce'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nom de la pièce',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Icône', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _iconPicker(selectedIcon, (v) => setLocal(() => selectedIcon = v)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    try {
      await widget.dataService.updateRoom(room.id, name, selectedIcon);
      _reload();
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException (updateRoom): ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Une erreur est survenue, réessaie.')),
      );
    }
  }

  Future<void> _confirmDelete(Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la pièce ?'),
        content:
            Text('« ${room.name} » et tous ses relevés seront supprimés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.dataService.deleteRoom(room.id);
      _reload();
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException (deleteRoom): ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Une erreur est survenue, réessaie.')),
      );
    }
  }

  Widget _iconPicker(String selected, void Function(String) onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _iconOptions.entries.map((e) {
        final isSelected = selected == e.key;
        return Builder(builder: (ctx) {
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onSelect(e.key),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? Theme.of(ctx).colorScheme.primaryContainer
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(ctx).colorScheme.primary
                      : Colors.grey.shade300,
                ),
              ),
              child: Icon(e.value, size: 28),
            ),
          );
        });
      }).toList(),
    );
  }

  Widget _buildCard(Room room) {
    return Card(
      key: ValueKey(room.id),
      child: Stack(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.pushNamed(
              context,
              '/dashboard',
              arguments: room,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_iconData(room.icon), size: 48),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      room.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: PopupMenuButton<String>(
              iconSize: 18,
              onSelected: (value) {
                if (value == 'edit') _showEditDialog(room);
                if (value == 'delete') _confirmDelete(room);
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Renommer'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 18,
                          color: Theme.of(ctx).colorScheme.error),
                      const SizedBox(width: 8),
                      Text('Supprimer',
                          style: TextStyle(
                              color: Theme.of(ctx).colorScheme.error)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profil',
            onPressed: () => Navigator.pushNamed(context, '/account'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'Ajouter une pièce',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune pièce pour l\'instant',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 8),
                      const Text('Appuie sur + pour en ajouter une'),
                    ],
                  ),
                )
              : ReorderableGridView.builder(
                  padding: const EdgeInsets.all(16),
                  onReorder: _onReorder,
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _rooms.length,
                  itemBuilder: (context, index) => _buildCard(_rooms[index]),
                ),
    );
  }
}
