// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/property_models.dart';
import '../services/data_service.dart';
import 'propertyFormScreen.dart';
import 'roomsScreen.dart';

class PropertiesScreen extends StatefulWidget {
  final IDataService dataService;
  const PropertiesScreen({super.key, required this.dataService});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  List<Property> _properties = [];
  bool _loading = true;

  static const _typeIcons = <String, IconData>{
    'apartment': Icons.apartment,
    'house':     Icons.house,
    'studio':    Icons.hotel,
    'office':    Icons.business,
    'other':     Icons.home_work,
  };

  static const _typeLabels = <String, String>{
    'apartment': 'Appartement',
    'house':     'Maison',
    'studio':    'Studio',
    'office':    'Bureau',
    'other':     'Autre',
  };

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final properties = await widget.dataService.getProperties();
      setState(() {
        _properties = properties;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final p = _properties.removeAt(oldIndex);
      _properties.insert(newIndex, p);
    });
    widget.dataService.reorderProperties(
      _properties.map((p) => p.id).toList(),
    );
  }

  Future<void> _openForm([Property? property]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyFormScreen(
          dataService: widget.dataService,
          property: property,
        ),
      ),
    );
    _reload();
  }

  Future<void> _confirmDelete(Property property) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le logement ?'),
        content: Text(
          '« ${property.name} », toutes ses pièces et tous ses relevés seront supprimés.',
        ),
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
      await widget.dataService.deleteProperty(property.id);
      _reload();
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.message}')),
      );
    }
  }

  String _subtitle(Property p) {
    final parts = <String>[
      _typeLabels[p.type] ?? 'Autre',
      if (p.surfaceM2 != null) '${p.surfaceM2!.toStringAsFixed(0)} m²',
      if (p.floor != null) 'Étage ${p.floor}',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes logements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profil',
            onPressed: () => Navigator.pushNamed(context, '/account'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Ajouter un logement',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _properties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun logement pour l\'instant',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 8),
                      const Text('Appuie sur + pour en ajouter un'),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 12),
                  onReorder: _onReorder,
                  itemCount: _properties.length,
                  itemBuilder: (context, index) {
                    final property = _properties[index];
                    final typeIcon =
                        _typeIcons[property.type] ?? Icons.home_work;
                    final hasAddress = property.address != null &&
                        property.address!.isNotEmpty;

                    return Card(
                      key: ValueKey(property.id),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            typeIcon,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          property.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_subtitle(property)),
                            if (hasAddress)
                              Text(
                                property.address!,
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        isThreeLine: hasAddress,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: Semantics(
                                label: 'Réordonner ${property.name}',
                                child: const Icon(Icons.drag_handle,
                                    color: Colors.grey),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') _openForm(property);
                                if (value == 'delete') _confirmDelete(property);
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18),
                                      SizedBox(width: 8),
                                      Text('Modifier'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline,
                                          size: 18,
                                          color: Theme.of(ctx)
                                              .colorScheme
                                              .error),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Supprimer',
                                        style: TextStyle(
                                            color: Theme.of(ctx)
                                                .colorScheme
                                                .error),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoomsScreen(
                              property: property,
                              dataService: widget.dataService,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
