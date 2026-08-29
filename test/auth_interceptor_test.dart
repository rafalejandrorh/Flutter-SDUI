import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_client/sdui_client.dart';
import 'package:sdui_client/src/auth/auth_interceptor.dart';

void main() {
  group('SduiAuthInterceptor', () {
    test('attaches Authorization when a token is present', () async {
      final store = MemoryTokenStore();
      await store.write('secret');
      final captured = <String?>[];

      final dio = _dioWithAuth(
        store: store,
        onRequest: (options, handler) {
          captured.add(options.headers['Authorization'] as String?);
          handler.resolve(
            Response<dynamic>(requestOptions: options, statusCode: 200),
          );
        },
      );

      await dio.get<void>('/sdui/home');
      expect(captured, ['Bearer secret']);
    });

    test('skips Authorization when the token is null', () async {
      final captured = <Object?>[];

      final dio = _dioWithAuth(
        store: MemoryTokenStore(),
        onRequest: (options, handler) {
          captured.add(options.headers['Authorization']);
          handler.resolve(
            Response<dynamic>(requestOptions: options, statusCode: 200),
          );
        },
      );

      await dio.get<void>('/sdui/home');
      expect(captured, [isNull]);
    });

    test('skips Authorization when the token is empty', () async {
      final store = MemoryTokenStore();
      await store.write('');
      final captured = <Object?>[];

      final dio = _dioWithAuth(
        store: store,
        onRequest: (options, handler) {
          captured.add(options.headers['Authorization']);
          handler.resolve(
            Response<dynamic>(requestOptions: options, statusCode: 200),
          );
        },
      );

      await dio.get<void>('/sdui/home');
      expect(captured, [isNull]);
    });

    test('calls onUnauthorized on HTTP 401', () async {
      var unauthorized = 0;
      final dio = Dio()
        ..httpClientAdapter = _StatusAdapter(401)
        ..interceptors.add(
          SduiAuthInterceptor(
            tokenStore: MemoryTokenStore(),
            onUnauthorized: () => unauthorized++,
          ),
        );

      await expectLater(
        dio.get<void>('/sdui/home'),
        throwsA(isA<DioException>()),
      );
      expect(unauthorized, 1);
    });

    test('does not call onUnauthorized on non-401 errors', () async {
      var unauthorized = 0;
      final dio = Dio()
        ..httpClientAdapter = _StatusAdapter(500)
        ..interceptors.add(
          SduiAuthInterceptor(
            tokenStore: MemoryTokenStore(),
            onUnauthorized: () => unauthorized++,
          ),
        );

      await expectLater(
        dio.get<void>('/sdui/home'),
        throwsA(isA<DioException>()),
      );
      expect(unauthorized, 0);
    });

    test('does not call onUnauthorized when there is no response', () async {
      var unauthorized = 0;
      final dio = Dio()
        ..httpClientAdapter = _ThrowingAdapter()
        ..interceptors.add(
          SduiAuthInterceptor(
            tokenStore: MemoryTokenStore(),
            onUnauthorized: () => unauthorized++,
          ),
        );

      await expectLater(
        dio.get<void>('/sdui/home'),
        throwsA(isA<DioException>()),
      );
      expect(unauthorized, 0);
    });
  });
}

Dio _dioWithAuth({
  required TokenStore store,
  void Function()? onUnauthorized,
  required void Function(
    RequestOptions options,
    RequestInterceptorHandler handler,
  )
  onRequest,
}) {
  return Dio()
    ..interceptors.add(
      SduiAuthInterceptor(tokenStore: store, onUnauthorized: onUnauthorized),
    )
    ..interceptors.add(InterceptorsWrapper(onRequest: onRequest));
}

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.statusCode);

  final int statusCode;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString('{}', statusCode);
  }
}

class _ThrowingAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      error: 'offline',
    );
  }
}
