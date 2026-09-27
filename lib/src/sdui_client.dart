import 'dart:async';

import 'package:dio/dio.dart';
import 'package:stac_framework/stac_framework.dart';

import 'actions/sdui_logout_action.dart';
import 'actions/sdui_navigate_action.dart';
import 'actions/sdui_network_request_action.dart';
import 'actions/sdui_reload_action.dart';
import 'actions/sdui_set_value_action.dart';
import 'actions/sdui_share_action.dart';
import 'auth/auth_interceptor.dart';
import 'config.dart';
import 'data/asset_screen_repository.dart';
import 'data/cached_screen_repository.dart';
import 'data/network_screen_repository.dart';
import 'data/screen_cache.dart';
import 'domain/screen_document.dart';
import 'ports/screen_repository.dart';
import 'ports/sdui_observer.dart';
import 'ports/sdui_renderer.dart';
import 'presentation/sdui_view_policy.dart';
import 'rendering/stac_renderer.dart';
import 'widgets/bar_chart.dart';
import 'widgets/bound_text.dart';
import 'widgets/form_dropdown.dart';

/// Injectable SDUI runtime (repository + renderer + observer).
class SduiClient {
  SduiClient({
    required this.config,
    required this.dio,
    required this.repository,
    required this.renderer,
    SduiObserver? observer,
    SduiViewPolicy? viewPolicy,
  }) : observer = observer ?? const NoOpSduiObserver(),
       viewPolicy = viewPolicy ?? config.viewPolicy ?? SduiViewPolicy.material;

  final SduiConfig config;
  final Dio dio;
  final ScreenRepository repository;
  final SduiRenderer renderer;
  final SduiObserver observer;
  final SduiViewPolicy viewPolicy;

  final StreamController<ScreenDocument> _reloads =
      StreamController<ScreenDocument>.broadcast();

  String? _focusedScreen;

  /// Documents produced by [reload]. [SduiScreen] listens when it uses this client.
  Stream<ScreenDocument> get reloads => _reloads.stream;

  /// Screen reloaded when an `sduiReload` action omits `screen`.
  void focusScreen(String name) {
    _focusedScreen = name;
  }

  void unfocusScreen(String name) {
    if (_focusedScreen == name) {
      _focusedScreen = null;
    }
  }

  /// Fetches [screen], or the focused screen, skipping a cache hit.
  ///
  /// A failed fetch keeps the previous document and reports [SduiObserver.onScreenError].
  Future<void> reload({String? screen}) async {
    final requested = screen;
    final name = (requested == null || requested.isEmpty)
        ? _focusedScreen
        : requested;
    if (name == null || name.isEmpty) {
      return;
    }
    try {
      final document = await repository.loadFresh(name);
      if (!_reloads.isClosed) {
        _reloads.add(document);
      }
    } catch (error) {
      observer.onScreenError(name, error);
    }
  }

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
    final runtime = SduiClient(
      config: config,
      dio: client,
      repository: repository,
      renderer: resolvedRenderer,
      observer: resolvedObserver,
      viewPolicy: config.viewPolicy,
    );

    if (renderer == null) {
      final onNavigate = config.onNavigateScreen;
      await StacRenderer.bootstrap(
        dio: client,
        widgetParsers: [
          ...extraWidgetParsers,
          const BarChartParser(),
          const BoundTextParser(),
          const FormDropdownMenuParser(),
        ],
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
          SduiShareActionParser(observer: resolvedObserver),
          SduiReloadActionParser(
            onReload: runtime.reload,
            observer: resolvedObserver,
          ),
          const SduiNetworkRequestActionParser(),
          const SduiSetValueActionParser(),
        ],
      );
    }

    return runtime;
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
    final inner = switch (config.source) {
      SduiScreenSource.asset => AssetScreenRepository(config),
      SduiScreenSource.network => NetworkScreenRepository(
        config: config,
        dio: client,
      ),
    };
    if (!config.cacheScreens) {
      return inner;
    }
    return CachedScreenRepository(
      inner: inner,
      cache: config.screenCache ?? MemoryScreenCache(),
    );
  }
}
