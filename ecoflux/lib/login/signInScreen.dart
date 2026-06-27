// ignore_for_file: use_build_context_synchronously

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';


class Signinscreen extends StatefulWidget {
  const Signinscreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SigninscreenState createState() => _SigninscreenState();
}


class _SigninscreenState extends State<Signinscreen> {
  final SupabaseClient _auth = Supabase.instance.client;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  String _email = "";
  String _password = "";


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body : Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child : Form(
            key : _formKey,
            child: Column(
              mainAxisAlignment : MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0))
                    ),
                    labelText: 'Email'
                    ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _email = value;
                    });
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0))
                    ),
                    labelText: 'Password'
                    ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _password = value;
                    });
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: _confirmPassController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0))
                    ),
                    labelText: 'Confirm Password'
                    ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _password) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await _auth.auth.signUp(
                          email: _email,
                          password: _password,
                        );
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/rooms',
                          (route) => false,
                        );
                      } on AuthException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.message),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Erreur réseau, réessaie.')),
                        );
                      }
                    }
                  },
                  child: const Text('Sign In'),
                ),
              ],
            )
            )
          )
        )
    );
  }
}