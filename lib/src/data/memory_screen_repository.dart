import '../domain/screen_document.dart';
import '../domain/sdui_exception.dart';
import '../ports/screen_repository.dart';

/// In-memory screens for tests and host fakes.
class MemoryScreenRepository implements ScreenRepository {
  MemoryScreenRepository([Map<String, Map<String, dynamic>>? screens])
    : _screens = Map<String, Map<String, dynamic>>.from(screens ?? {});

  final Map<String, Map<String, dynamic>> _screens;
  Object? errorForNextLoad;

  void put(String name, Map<String, dynamic> json) {
    _screens[name] = json;
  }

  @override
  Future<ScreenDocument> load(String name) async {
    final error = errorForNextLoad;
    if (error != null) {
      errorForNextLoad = null;
      if (error is SduiException) {
        throw error;
      }
      throw SduiLoadFailedException(
        'Failed to load screen "$name".',
        cause: error,
        screen: name,
      );
    }
    final json = _screens[name];
    if (json == null) {
      throw SduiLoadFailedException('Unknown screen "$name".', screen: name);
    }
    return ScreenDocument.parse(Map<String, dynamic>.from(json), name: name);
  }
}
