import 'package:dio/dio.dart';

import '../config.dart';
import '../domain/screen_document.dart';
import '../domain/sdui_exception.dart';
import '../ports/screen_repository.dart';
import 'json_object.dart';

/// GET `{baseUrl}{screenPath}` and return a parsed [ScreenDocument].
class NetworkScreenRepository implements ScreenRepository {
  NetworkScreenRepository({required this.config, required this.dio});

  final SduiConfig config;
  final Dio dio;

  @override
  Future<ScreenDocument> load(String name) async {
    final url = config.resolveScreenUrl(name);
    try {
      final response = await dio.get<dynamic>(url);
      return ScreenDocument.parse(
        asJsonObject(response.data, source: url),
        name: name,
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
}
