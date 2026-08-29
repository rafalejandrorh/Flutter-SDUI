import '../domain/screen_document.dart';

/// One cached screen, including the ETag used for conditional GET.
class ScreenCacheEntry {
  const ScreenCacheEntry({
    required this.document,
    required this.storedAt,
    this.etag,
  });

  final ScreenDocument document;
  final DateTime storedAt;
  final String? etag;
}

/// Persistence for [CachedScreenRepository]. Memory by default; hosts can persist.
abstract class ScreenCache {
  Future<ScreenCacheEntry?> read(String name);

  Future<void> write(String name, ScreenCacheEntry entry);

  Future<void> remove(String name);

  Future<void> clear();
}

/// Process-local cache. Plug in another [ScreenCache] for disk.
class MemoryScreenCache implements ScreenCache {
  MemoryScreenCache([Map<String, ScreenCacheEntry>? entries])
    : _entries = Map<String, ScreenCacheEntry>.from(entries ?? {});

  final Map<String, ScreenCacheEntry> _entries;

  @override
  Future<ScreenCacheEntry?> read(String name) async => _entries[name];

  @override
  Future<void> write(String name, ScreenCacheEntry entry) async {
    _entries[name] = entry;
  }

  @override
  Future<void> remove(String name) async {
    _entries.remove(name);
  }

  @override
  Future<void> clear() async {
    _entries.clear();
  }
}
