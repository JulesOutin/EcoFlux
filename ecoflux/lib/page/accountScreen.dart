// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
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

    // Pré-remplir depuis user_metadata si disponible
    final meta = user.userMetadata ?? {};
    _firstNameController.text = meta['first_name'] as String? ?? '';
    _lastNameController.text  = meta['last_name']  as String? ?? '';

    // Charger les données étendues depuis la table profiles
    try {
      final data = await _supabase
          .from('profiles')
          .select('first_name, last_name')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        _firstNameController.text = data['first_name'] as String? ?? _firstNameController.text;
        _lastNameController.text  = data['last_name']  as String? ?? _lastNameController.text;
      }
    } on PostgrestException {
      // Table profiles absente ou RLS bloque — on garde les valeurs de user_metadata
    }

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final firstName = _firstNameController.text.trim();
    final lastName  = _lastNameController.text.trim();
    final password  = _passwordController.text;
    final userId    = _supabase.auth.currentUser!.id;

    try {
      // Upsert dans la table profiles
      await _supabase.from('profiles').upsert({
        'id':         userId,
        'first_name': firstName,
        'last_name':  lastName,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Mise à jour du mot de passe uniquement si renseigné
      if (password.isNotEmpty) {
        await _supabase.auth.updateUser(
          UserAttributes(password: password),
        );
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
                      TextFormField(
                        controller: _firstNameController,
                        keyboardType: TextInputType.name,
                        decoration: const InputDecoration(
                          labelText: 'Prénom',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
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
                            borderRadius: BorderRadius.all(Radius.circular(10)),
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
                            borderRadius: BorderRadius.all(Radius.circular(10)),
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
