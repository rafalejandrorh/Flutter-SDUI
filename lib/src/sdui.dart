import 'package:dio/dio.dart';
import 'package:stac/stac.dart';

import 'actions/sdui_logout_action.dart';
import 'actions/sdui_navigate_action.dart';
import 'auth/auth_interceptor.dart';
import 'config.dart';
import 'screen_loader.dart';

/// Runtime entry point for the SDUI client.
class Sdui {
  Sdui._();

  static SduiConfig? _config;
  static Dio? _dio;
  static ScreenLoader? _loader;

  static SduiConfig get config {
    final value = _config;
    if (value == null) {
      throw StateError('Call Sdui.initialize before using the SDUI client.');
    }
    return value;
  }

  static Dio get dio {
    final value = _dio;
    if (value == null) {
      throw StateError('Call Sdui.initialize before using the SDUI client.');
    }
    return value;
  }

  static ScreenLoader get loader {
    final value = _loader;
    if (value == null) {
      throw StateError('Call Sdui.initialize before using the SDUI client.');
    }
    return value;
  }

  static bool get isInitialized => _config != null;

  static Future<void> initialize({
    required SduiConfig config,
    List<StacActionParser> extraActionParsers = const [],
  }) async {
    _config = config;
    final client = config.dio ?? Dio();
    final tokenStore = config.tokenStore;
    if (tokenStore != null) {
      client.interceptors.add(
        SduiAuthInterceptor(
          tokenStore: tokenStore,
          onUnauthorized: config.onUnauthorized,
        ),
      );
    }
    _dio = client;
    _loader = switch (config.source) {
      SduiScreenSource.asset => AssetScreenLoader(config),
      SduiScreenSource.network => NetworkScreenLoader(
          config: config,
          dio: client,
        ),
    };

    await Stac.initialize(
      dio: client,
      actionParsers: [
        const SduiNavigateActionParser(),
        const SduiLogoutActionParser(),
        ...extraActionParsers,
      ],
    );
  }

  /// Test-only reset.
  static void reset() {
    _config = null;
    _dio = null;
    _loader = null;
  }
}
