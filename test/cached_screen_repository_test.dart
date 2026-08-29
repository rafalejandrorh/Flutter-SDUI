import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_client/sdui_client.dart';

void main() {
  group('CachedScreenRepository', () {
    test('returns cached document immediately and revalidates (SWR)', () async {
      final inner = MemoryScreenRepository({
        'home': {'type': 'text', 'data': 'v1'},
      });
      final repo = CachedScreenRepository(inner: inner);

      final first = await repo.load('home');
      expect(first.body['data'], 'v1');

      inner.put('home', {'type': 'text', 'data': 'v2'});
      final updated = repo.watch('home').first;
      final second = await repo.load('home');

      expect(second.body['data'], 'v1');
      expect((await updated).body['data'], 'v2');
      expect((await repo.cache.read('home'))!.document.body['data'], 'v2');
    });

    test('skips revalidation while the entry is within staleAfter', () async {
      final inner = _CountingRepo({
        'home': {'type': 'text', 'data': 'v1'},
      });
      final repo = CachedScreenRepository(
        inner: inner,
        staleAfter: const Duration(hours: 1),
      );

      await repo.load('home');
      inner.put('home', {'type': 'text', 'data': 'v2'});
      await repo.load('home');
      await pumpEventQueue();

      expect(inner.loads, 1);
      expect((await repo.cache.read('home'))!.document.body['data'], 'v1');
    });

    test('sends If-None-Match and keeps cache on 304', () async {
      final inner = _FakeConditional(
        json: {'type': 'text', 'data': 'v1'},
        etag: '"abc"',
      );
      final repo = CachedScreenRepository(inner: inner);

      await repo.load('home');
      expect(inner.fetches, 1);
      expect(inner.lastIfNoneMatch, isNull);

      inner.returnNotModified = true;
      final second = await repo.load('home');
      await pumpEventQueue();

      expect(second.body['data'], 'v1');
      expect(inner.fetches, 2);
      expect(inner.lastIfNoneMatch, '"abc"');
    });

    test('replaces cache and notifies watchers on a fresh ETag GET', () async {
      final inner = _FakeConditional(
        json: {'type': 'text', 'data': 'v1'},
        etag: '"v1"',
      );
      final repo = CachedScreenRepository(inner: inner);

      await repo.load('home');
      inner.json = {'type': 'text', 'data': 'v2'};
      inner.etag = '"v2"';

      final updated = repo.watch('home').first;
      await repo.load('home');

      expect((await updated).body['data'], 'v2');
      expect((await repo.cache.read('home'))!.etag, '"v2"');
    });
  });
}

Future<void> pumpEventQueue() => Future<void>.delayed(Duration.zero);

class _CountingRepo extends MemoryScreenRepository {
  _CountingRepo(super.screens);

  int loads = 0;

  @override
  Future<ScreenDocument> load(String name) {
    loads++;
    return super.load(name);
  }
}

class _FakeConditional implements ConditionalScreenRepository {
  _FakeConditional({required this.json, required this.etag});

  Map<String, dynamic> json;
  String etag;
  bool returnNotModified = false;
  int fetches = 0;
  String? lastIfNoneMatch;

  @override
  Future<ScreenDocument> load(String name) async {
    final result = await fetch(name);
    return result.document!;
  }

  @override
  Future<ScreenFetch> fetch(String name, {String? ifNoneMatch}) async {
    fetches++;
    lastIfNoneMatch = ifNoneMatch;
    if (returnNotModified) {
      return ScreenFetch.notModified(etag: etag);
    }
    return ScreenFetch.fresh(
      document: ScreenDocument.parse(
        Map<String, dynamic>.from(json),
        name: name,
      ),
      etag: etag,
    );
  }
}
