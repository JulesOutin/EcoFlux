import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'login/loginScreen.dart';
import 'login/signInScreen.dart';
import 'page/propertiesScreen.dart';
import 'page/dashboardScreen.dart';
import 'page/accountScreen.dart';
import 'welcome.dart';
import 'models/property_models.dart';
import 'services/data_service.dart';
import 'services/supabase_service.dart';

final IDataService dataService = SupabaseDataService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const AuthGate(),
      routes: {
        '/welcome':    (context) => const Welcome(),
        '/login':      (context) => const LoginScreen(),
        '/signup':     (context) => const Signinscreen(),
        '/properties': (context) => PropertiesScreen(dataService: dataService),
        '/dashboard':  (context) {
          final room = ModalRoute.of(context)!.settings.arguments as Room;
          return DashboardScreen(room: room, dataService: dataService);
        },
        '/account':    (context) => const Accountscreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return PropertiesScreen(dataService: dataService);
        }
        return const Welcome();
      },
    );
  }
}
