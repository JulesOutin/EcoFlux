import 'package:mocktail/mocktail.dart';
import 'package:ecoflux/services/auth_service.dart';

/// Test double for [IAuthService], shared by every test that needs to
/// stub the auth layer instead of talking to Supabase.
class MockAuthService extends Mock implements IAuthService {}
