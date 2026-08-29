import 'package:dio/dio.dart';
import 'package:stac_framework/stac_framework.dart';

import 'actions/sdui_logout_action.dart';
import 'actions/sdui_navigate_action.dart';
import 'auth/auth_interceptor.dart';
import 'config.dart';
import 'data/asset_screen_repository.dart';
import 'data/network_screen_repository.dart';
import 'domain/screen_document.dart';
import 'ports/screen_repository.dart';
import 'ports/sdui_observer.dart';
import 'ports/sdui_renderer.dart';
import 'rendering/stac_renderer.dart';

/// Injectable SDUI runtime (repository + renderer + observer).
class SduiClient {
  SduiClient({
    required this.config,
    required this.dio,
    required this.repository,
    required this.renderer,
    SduiObserver? observer,
  }) : observer = observer ?? const NoOpSduiObserver();

  final SduiConfig config;
  final Dio dio;
  final ScreenRepository repository;
  final SduiRenderer renderer;
  final SduiObserver observer;

  /// Builds Dio, loaders, action parsers, and (unless [renderer] is set) Stac.
  static Future<SduiClient> bootstrap({
    required SduiConfig config,
    List<StacActionParser<dynamic>> extraActionParsers = const [],
    List<StacParser<dynamic>> extraWidgetParsers = const [],
    SduiRenderer? renderer,
    SduiObserver? observer,
  }) async {
    final resolvedObserver =
        observer ?? config.observer ?? const NoOpSduiObserver();
    final client = _createDio(config);
    final repository =
        config.screenRepository ?? _defaultRepository(config, client);
    final resolvedRenderer = renderer ?? const StacRenderer();

    if (renderer == null) {
      final onNavigate = config.onNavigateScreen;
      await StacRenderer.bootstrap(
        dio: client,
        widgetParsers: extraWidgetParsers,
        actionParsers: [
          SduiNavigateActionParser(
            onNavigate:
                onNavigate ??
                (context, screen, {style = 'push'}) {
                  throw StateError(
                    'SduiConfig.onNavigateScreen is required for sduiNavigate actions.',
                  );
                },
            observer: resolvedObserver,
          ),
          SduiLogoutActionParser(
            onLogout: config.onLogout,
            observer: resolvedObserver,
          ),
          ...extraActionParsers,
        ],
      );
    }

    return SduiClient(
      config: config,
      dio: client,
      repository: repository,
      renderer: resolvedRenderer,
      observer: resolvedObserver,
    );
  }

  static Dio _createDio(SduiConfig config) {
    final client =
        config.dio ??
        Dio(
          BaseOptions(
            baseUrl: config.baseUrl,
            headers: const {'Accept': 'application/json'},
          ),
        );
    if (config.baseUrl.isNotEmpty) {
      client.options.baseUrl = config.baseUrl;
    }
    client.options.headers.putIfAbsent('Accept', () => 'application/json');
    client.options.headers.putIfAbsent(
      ScreenDocument.clientVersionHeader,
      () => '${ScreenDocument.currentSchemaVersion}',
    );
    final tokenStore = config.tokenStore;
    if (tokenStore != null) {
      client.interceptors.add(
        SduiAuthInterceptor(
          tokenStore: tokenStore,
          onUnauthorized: config.onUnauthorized,
        ),
      );
    }
    return client;
  }

  static ScreenRepository _defaultRepository(SduiConfig config, Dio client) {
    return switch (config.source) {
      SduiScreenSource.asset => AssetScreenRepository(config),
      SduiScreenSource.network => NetworkScreenRepository(
        config: config,
        dio: client,
      ),
    };
  }
}
