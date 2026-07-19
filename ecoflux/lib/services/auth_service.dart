import 'package:supabase_flutter/supabase_flutter.dart';

abstract class IAuthService {
  Stream<AuthState> get onAuthStateChange;
  Session? get currentSession;
  User? get currentUser;

  Future<void> signInWithPassword(String email, String password);
  Future<void> signUp(String email, String password);
  Future<void> signOut();
  Future<void> updatePassword(String password);
}

class SupabaseAuthService implements IAuthService {
  final _auth = Supabase.instance.client.auth;

  @override
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  @override
  Session? get currentSession => _auth.currentSession;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<void> signInWithPassword(String email, String password) =>
      _auth.signInWithPassword(email: email, password: password);

  @override
  Future<void> signUp(String email, String password) =>
      _auth.signUp(email: email, password: password);

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> updatePassword(String password) =>
      _auth.updateUser(UserAttributes(password: password));
}
