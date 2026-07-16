// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property_models.dart';
import '../services/data_service.dart';

class PropertyFormScreen extends StatefulWidget {
  final IDataService dataService;
  final Property? property;

  const PropertyFormScreen({
    super.key,
    required this.dataService,
    this.property,
  });

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _surfaceController;
  late final TextEditingController _floorController;
  late final TextEditingController _yearController;
  late String _selectedType;
  bool _saving = false;

  static const _typeOptions = <String, (String, IconData)>{
    'apartment': ('Appartement', Icons.apartment),
    'house':     ('Maison',      Icons.house),
    'studio':    ('Studio',      Icons.hotel),
    'office':    ('Bureau',      Icons.business),
    'other':     ('Autre',       Icons.home_work),
  };

  bool get _isEditing => widget.property != null;

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _nameController    = TextEditingController(text: p?.name ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _surfaceController = TextEditingController(
        text: p?.surfaceM2 != null ? p!.surfaceM2!.toStringAsFixed(0) : '');
    _floorController   = TextEditingController(
        text: p?.floor?.toString() ?? '');
    _yearController    = TextEditingController(
        text: p?.yearBuilt?.toString() ?? '');
    _selectedType      = p?.type ?? 'apartment';
    _addressController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _surfaceController.dispose();
    _floorController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final name      = _nameController.text.trim();
    final address   = _addressController.text.trim();
    final surfaceM2 = double.tryParse(_surfaceController.text.trim());
    final floor     = int.tryParse(_floorController.text.trim());
    final yearBuilt = int.tryParse(_yearController.text.trim());

    try {
      if (_isEditing) {
        await widget.dataService.updateProperty(
          widget.property!.id,
          name,
          _selectedType,
          address:   address.isEmpty ? null : address,
          surfaceM2: surfaceM2,
          floor:     floor,
          yearBuilt: yearBuilt,
        );
      } else {
        await widget.dataService.addProperty(
          name,
          _selectedType,
          address:   address.isEmpty ? null : address,
          surfaceM2: surfaceM2,
          floor:     floor,
          yearBuilt: yearBuilt,
        );
      }
      Navigator.pop(context);
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.message}')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur réseau, réessaie.')),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _openInMaps() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;
    final uri = Uri.parse(
        'https://maps.apple.com/?q=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _typePicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _typeOptions.entries.map((e) {
        final selected = _selectedType == e.key;
        final (label, icon) = e.value;
        return ChoiceChip(
          avatar: Icon(icon, size: 16),
          label: Text(label),
          selected: selected,
          onSelected: (_) => setState(() => _selectedType = e.key),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAddress = _addressController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le logement' : 'Nouveau logement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom
              TextFormField(
                controller: _nameController,
                autofocus: !_isEditing,
                decoration: const InputDecoration(
                  labelText: 'Nom du logement',
                  hintText: 'ex. Appartement Paris',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 20),

              // Type
              const Text('Type', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _typePicker(),
              const SizedBox(height: 20),

              // Adresse
              TextFormField(
                controller: _addressController,
                keyboardType: TextInputType.streetAddress,
                decoration: const InputDecoration(
                  labelText: 'Adresse (optionnel)',
                  hintText: 'ex. 12 rue de la Paix, 75001 Paris',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
              if (hasAddress) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _openInMaps,
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('Voir sur Maps'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Surface + Étage
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _surfaceController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Surface (optionnel)',
                        suffixText: 'm²',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _floorController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Étage (optionnel)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Année de construction
              TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Année de construction (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final year = int.tryParse(v);
                  if (year == null || year < 1000 || year > 2100) {
                    return 'Année invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEditing ? 'Enregistrer' : 'Ajouter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
