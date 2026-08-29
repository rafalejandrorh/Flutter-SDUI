import '../domain/screen_document.dart';

/// Loads a named screen. Hosts can inject a custom implementation.
abstract class ScreenRepository {
  Future<ScreenDocument> load(String name);
}
