import 'package:dio/dio.dart';

import 'token_store.dart';

/// Attaches `Authorization: Bearer` and reports 401 to the host.
class SduiAuthInterceptor extends Interceptor {
  SduiAuthInterceptor({required this.tokenStore, this.onUnauthorized});

  final TokenStore tokenStore;
  final void Function()? onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStore.read();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}
