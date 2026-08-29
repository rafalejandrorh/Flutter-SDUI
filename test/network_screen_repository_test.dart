import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_client/sdui_client.dart';

void main() {
  group('NetworkScreenRepository', () {
    test('parses a 200 body and captures ETag', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              expect(options.headers['If-None-Match'], isNull);
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'type': 'text', 'data': 'ok'},
                  headers: Headers.fromMap({
                    'etag': ['"v1"'],
                  }),
                ),
              );
            },
          ),
        );

      final repo = NetworkScreenRepository(
        config: const SduiConfig(
          source: SduiScreenSource.network,
          baseUrl: 'https://api.example.com',
        ),
        dio: dio,
      );

      final result = await repo.fetch('home');
      expect(result.notModified, isFalse);
      expect(result.etag, '"v1"');
      expect(result.document!.body['data'], 'ok');
    });

    test('sends If-None-Match and maps 304 to notModified', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              expect(options.headers['If-None-Match'], '"abc"');
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 304,
                  headers: Headers.fromMap({
                    'etag': ['"abc"'],
                  }),
                ),
              );
            },
          ),
        );

      final repo = NetworkScreenRepository(
        config: const SduiConfig(
          source: SduiScreenSource.network,
          baseUrl: 'https://api.example.com',
        ),
        dio: dio,
      );

      final result = await repo.fetch('home', ifNoneMatch: '"abc"');
      expect(result.notModified, isTrue);
      expect(result.document, isNull);
      expect(result.etag, '"abc"');
    });

    test('load() wraps transport errors as SduiLoadFailedException', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                  error: 'offline',
                ),
              );
            },
          ),
        );

      final repo = NetworkScreenRepository(
        config: const SduiConfig(
          source: SduiScreenSource.network,
          baseUrl: 'https://api.example.com',
        ),
        dio: dio,
      );

      expect(repo.load('home'), throwsA(isA<SduiLoadFailedException>()));
    });
  });
}
