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
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/supabase_service.dart';

final IDataService dataService = SupabaseDataService();
final IAuthService authService = SupabaseAuthService();

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      ),
      home: AuthGate(authService: authService, dataService: dataService),
      routes: {
        '/welcome':    (context) => const Welcome(),
        '/login':      (context) => LoginScreen(authService: authService),
        '/signup':     (context) => Signinscreen(authService: authService),
        '/properties': (context) => PropertiesScreen(dataService: dataService),
        '/dashboard':  (context) {
          final room = ModalRoute.of(context)!.settings.arguments as Room;
          return DashboardScreen(room: room, dataService: dataService);
        },
        '/account':    (context) => Accountscreen(
              authService: authService,
              dataService: dataService,
            ),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  final IAuthService authService;
  final IDataService dataService;
  const AuthGate({
    super.key,
    required this.authService,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: authService.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session = authService.currentSession;
        if (session != null) {
          return PropertiesScreen(dataService: dataService);
        }
        return const Welcome();
      },
    );
  }
}
