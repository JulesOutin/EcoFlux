// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Accountscreen extends StatefulWidget {
  const Accountscreen({super.key});

  @override
  State<Accountscreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<Accountscreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final meta = user.userMetadata ?? {};
    _firstNameController.text = meta['first_name'] as String? ?? '';
    _lastNameController.text  = meta['last_name']  as String? ?? '';

    try {
      final data = await _supabase
          .from('profiles')
          .select('first_name, last_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        _firstNameController.text =
            data['first_name'] as String? ?? _firstNameController.text;
        _lastNameController.text =
            data['last_name'] as String? ?? _lastNameController.text;
        _avatarUrl = data['avatar_url'] as String?;
      }
    } on PostgrestException {
      // RLS bloque ou table absente — on garde les valeurs de user_metadata
    }

    setState(() => _loading = false);
  }

  Future<void> _pickAndUploadAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Caméra'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final file = File(picked.path);
      final path = '$userId/avatar.jpg';

      await _supabase.storage.from('avatars').upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );

      final url = _supabase.storage.from('avatars').getPublicUrl(path);
      // Bust cache en ajoutant un timestamp
      final cacheBustedUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      await _supabase.from('profiles').upsert({
        'id':         userId,
        'avatar_url': cacheBustedUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      setState(() => _avatarUrl = cacheBustedUrl);
    } on StorageException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur upload : ${e.message}')),
      );
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur base de données : ${e.message}')),
      );
    } finally {
      setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final firstName = _firstNameController.text.trim();
    final lastName  = _lastNameController.text.trim();
    final password  = _passwordController.text;
    final userId    = _supabase.auth.currentUser!.id;

    try {
      await _supabase.from('profiles').upsert({
        'id':         userId,
        'first_name': firstName,
        'last_name':  lastName,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (password.isNotEmpty) {
        await _supabase.auth.updateUser(UserAttributes(password: password));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil enregistré.')),
      );
      _passwordController.clear();
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur base de données : ${e.message}')),
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur auth : ${e.message}')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur réseau, réessaie.')),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    await _supabase.auth.signOut();
    navigator.pushNamedAndRemoveUntil('/welcome', (route) => false);
  }

  Widget _buildAvatar() {
    final initials = [
      _firstNameController.text.isNotEmpty
          ? _firstNameController.text[0].toUpperCase()
          : '',
      _lastNameController.text.isNotEmpty
          ? _lastNameController.text[0].toUpperCase()
          : '',
    ].join();

    return GestureDetector(
      onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor:
                Theme.of(context).colorScheme.primaryContainer,
            backgroundImage:
                _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
            child: _avatarUrl == null
                ? Text(
                    initials.isEmpty ? '?' : initials,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          if (_uploadingAvatar)
            const CircleAvatar(
              radius: 48,
              backgroundColor: Colors.black38,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
          if (!_uploadingAvatar)
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(
                  Icons.camera_alt,
                  size: 14,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon compte')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAvatar(),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _firstNameController,
                        keyboardType: TextInputType.name,
                        decoration: const InputDecoration(
                          labelText: 'Prénom',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameController,
                        keyboardType: TextInputType.name,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Nouveau mot de passe (optionnel)',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Enregistrer'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _signOut,
                          child: const Text('Se déconnecter'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
