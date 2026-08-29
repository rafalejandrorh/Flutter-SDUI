import 'package:dio/dio.dart';
import 'package:stac_framework/stac_framework.dart';

import 'config.dart';
import 'ports/screen_repository.dart';
import 'ports/sdui_observer.dart';
import 'ports/sdui_renderer.dart';
import 'sdui_client.dart';

/// Static facade over [SduiClient] for `Sdui.initialize` hosts.
class Sdui {
  Sdui._();

  static SduiClient? _client;

  static SduiClient get client {
    final value = _client;
    if (value == null) {
      throw StateError('Call Sdui.initialize before using the SDUI client.');
    }
    return value;
  }

  static SduiConfig get config => client.config;

  static Dio get dio => client.dio;

  static ScreenRepository get repository => client.repository;

  static SduiRenderer get renderer => client.renderer;

  static SduiObserver get observer => client.observer;

  static bool get isInitialized => _client != null;

  static Future<void> initialize({
    required SduiConfig config,
    List<StacActionParser<dynamic>> extraActionParsers = const [],
    List<StacParser<dynamic>> extraWidgetParsers = const [],
    SduiRenderer? renderer,
    SduiObserver? observer,
  }) async {
    _client = await SduiClient.bootstrap(
      config: config,
      extraActionParsers: extraActionParsers,
      extraWidgetParsers: extraWidgetParsers,
      renderer: renderer,
      observer: observer,
    );
  }

  /// Test-only reset.
  static void reset() {
    _client = null;
  }
}
