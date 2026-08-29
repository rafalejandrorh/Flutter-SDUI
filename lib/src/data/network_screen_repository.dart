import 'package:dio/dio.dart';

import '../config.dart';
import '../domain/screen_document.dart';
import '../domain/sdui_exception.dart';
import '../ports/screen_repository.dart';
import 'json_object.dart';

/// GET `{baseUrl}{screenPath}` and return a parsed [ScreenDocument].
class NetworkScreenRepository implements ConditionalScreenRepository {
  NetworkScreenRepository({required this.config, required this.dio});

  final SduiConfig config;
  final Dio dio;

  @override
  Future<ScreenDocument> load(String name) async {
    final result = await fetch(name);
    final document = result.document;
    if (result.notModified || document == null) {
      throw SduiLoadFailedException(
        'Failed to load screen "$name".',
        screen: name,
      );
    }
    return document;
  }

  @override
  Future<ScreenFetch> fetch(String name, {String? ifNoneMatch}) async {
    final url = config.resolveScreenUrl(name);
    try {
      final response = await dio.get<dynamic>(
        url,
        options: Options(
          headers: {
            if (ifNoneMatch != null && ifNoneMatch.isNotEmpty)
              'If-None-Match': ifNoneMatch,
          },
          validateStatus: _isSuccessOrNotModified,
        ),
      );
      if (response.statusCode == 304) {
        return ScreenFetch.notModified(
          etag: response.headers.value('etag') ?? ifNoneMatch,
        );
      }
      return ScreenFetch.fresh(
        document: ScreenDocument.parse(
          asJsonObject(response.data, source: url),
          name: name,
        ),
        etag: response.headers.value('etag'),
      );
    } on SduiException {
      rethrow;
    } catch (error) {
      throw SduiLoadFailedException(
        'Failed to load screen "$name".',
        cause: error,
        screen: name,
      );
    }
  }

  static bool _isSuccessOrNotModified(int? status) {
    return status != null && ((status >= 200 && status < 300) || status == 304);
  }
}
