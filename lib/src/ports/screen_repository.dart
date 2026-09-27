import '../domain/screen_document.dart';

/// Loads a named screen. Hosts can inject a custom implementation.
abstract class ScreenRepository {
  Future<ScreenDocument> load(String name);

  /// Loads [name] without serving a cache hit.
  ///
  /// The default calls [load]. The cache decorator overrides this to fetch,
  /// replace the stored copy, and notify watchers.
  Future<ScreenDocument> loadFresh(String name) => load(name);
}

/// Optional SWR capability: emit a newer document after [ScreenRepository.load].
abstract class ScreenChangeSource implements ScreenRepository {
  Stream<ScreenDocument> watch(String name);
}

/// Result of a conditional GET (`If-None-Match` / ETag).
class ScreenFetch {
  const ScreenFetch({required this.notModified, this.document, this.etag});

  const ScreenFetch.fresh({required ScreenDocument this.document, this.etag})
    : notModified = false;

  const ScreenFetch.notModified({this.etag})
    : document = null,
      notModified = true;

  final bool notModified;
  final ScreenDocument? document;
  final String? etag;
}

/// Network-aware repository that can honor ETags.
abstract class ConditionalScreenRepository implements ScreenRepository {
  Future<ScreenFetch> fetch(String name, {String? ifNoneMatch});
}
