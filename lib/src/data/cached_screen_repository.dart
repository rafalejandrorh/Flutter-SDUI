import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/screen_document.dart';
import '../domain/sdui_exception.dart';
import '../ports/screen_repository.dart';
import 'screen_cache.dart';

/// Decorator: cache-first load, then revalidate (SWR). Uses ETag when [inner]
/// implements [ConditionalScreenRepository].
class CachedScreenRepository implements ScreenChangeSource {
  CachedScreenRepository({
    required this.inner,
    ScreenCache? cache,
    this.staleAfter,
  }) : cache = cache ?? MemoryScreenCache();

  final ScreenRepository inner;
  final ScreenCache cache;

  /// Skip revalidation while the entry is younger than this. `null` = always.
  final Duration? staleAfter;

  final Map<String, Future<ScreenDocument>> _inflight = {};
  final Map<String, StreamController<ScreenDocument>> _controllers = {};

  @override
  Stream<ScreenDocument> watch(String name) {
    return _controllers.putIfAbsent(name, _newBroadcastController).stream;
  }

  static StreamController<ScreenDocument> _newBroadcastController() {
    return StreamController<ScreenDocument>.broadcast();
  }

  @override
  Future<ScreenDocument> load(String name) async {
    final cached = await cache.read(name);
    if (cached != null) {
      if (!_isFresh(cached)) {
        unawaited(_revalidate(name, cached));
      }
      return cached.document;
    }
    return _loadFresh(name);
  }

  bool _isFresh(ScreenCacheEntry entry) {
    final maxAge = staleAfter;
    if (maxAge == null) {
      return false;
    }
    return DateTime.now().difference(entry.storedAt) < maxAge;
  }

  Future<ScreenDocument> _loadFresh(String name) {
    return _inflight.putIfAbsent(name, () async {
      try {
        final document = await _doFetchAndStore(name);
        if (document == null) {
          throw SduiLoadFailedException(
            'Screen "$name" was not modified but no cached copy is available.',
            screen: name,
          );
        }
        return document;
      } finally {
        unawaited(_inflight.remove(name));
      }
    });
  }

  /// Skips the cache hit, fetches [name], and replaces the stored copy.
  @override
  Future<ScreenDocument> loadFresh(String name) async {
    final document = await _doFetchAndStore(name);
    if (document == null) {
      throw SduiLoadFailedException(
        'Screen "$name" refresh did not return a document.',
        screen: name,
      );
    }
    _emit(name, document);
    return document;
  }

  Future<void> _revalidate(String name, ScreenCacheEntry cached) async {
    try {
      final fresh = await _doFetchAndStore(
        name,
        ifNoneMatch: cached.etag,
        allowNotModified: true,
      );
      if (fresh == null || _same(cached.document, fresh)) {
        return;
      }
      _emit(name, fresh);
    } catch (_) {
      // Keep serving stale. The original [load] already succeeded.
    }
  }

  Future<ScreenDocument?> _doFetchAndStore(
    String name, {
    String? ifNoneMatch,
    bool allowNotModified = false,
  }) async {
    final inner = this.inner;
    if (inner is ConditionalScreenRepository) {
      final result = await inner.fetch(name, ifNoneMatch: ifNoneMatch);
      if (result.notModified) {
        if (allowNotModified) {
          return null;
        }
        throw SduiLoadFailedException(
          'Screen "$name" was not modified but no cached copy is available.',
          screen: name,
        );
      }
      final document = result.document;
      if (document == null) {
        throw SduiLoadFailedException(
          'Screen "$name" response did not include a document.',
          screen: name,
        );
      }
      await cache.write(
        name,
        ScreenCacheEntry(
          document: document,
          etag: result.etag,
          storedAt: DateTime.now(),
        ),
      );
      return document;
    }

    final document = await inner.load(name);
    await cache.write(
      name,
      ScreenCacheEntry(document: document, storedAt: DateTime.now()),
    );
    return document;
  }

  void _emit(String name, ScreenDocument document) {
    final controller = _controllers[name];
    if (controller != null && !controller.isClosed) {
      controller.add(document);
    }
  }

  bool _same(ScreenDocument a, ScreenDocument b) {
    return a.schemaVersion == b.schemaVersion && mapEquals(a.body, b.body);
  }

  /// Closes SWR watchers. Optional; process-lifetime repositories can skip this.
  Future<void> dispose() async {
    final controllers = List<StreamController<ScreenDocument>>.of(
      _controllers.values,
    );
    _controllers.clear();
    for (final controller in controllers) {
      await controller.close();
    }
  }
}
