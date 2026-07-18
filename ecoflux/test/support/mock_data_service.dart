import 'package:mocktail/mocktail.dart';
import 'package:ecoflux/services/data_service.dart';

/// Test double for [IDataService], shared by every test that needs to
/// stub the data layer instead of talking to Supabase.
class MockDataService extends Mock implements IDataService {}
