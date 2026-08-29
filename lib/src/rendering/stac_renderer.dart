import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:stac/stac.dart';

import '../domain/screen_document.dart';
import '../ports/sdui_renderer.dart';

/// Stac-backed [SduiRenderer]. The only type that imports `package:stac`.
class StacRenderer implements SduiRenderer {
  const StacRenderer();

  static Future<void> bootstrap({
    required Dio dio,
    required List<StacActionParser<dynamic>> actionParsers,
    List<StacParser<dynamic>> widgetParsers = const [],
  }) {
    return Stac.initialize(
      dio: dio,
      parsers: widgetParsers,
      actionParsers: actionParsers,
      override: true,
    );
  }

  @override
  Widget? render(BuildContext context, ScreenDocument document) {
    try {
      return Stac.fromJson(document.body, context);
    } catch (_) {
      return null;
    }
  }
}
