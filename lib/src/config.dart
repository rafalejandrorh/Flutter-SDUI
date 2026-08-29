import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import 'auth/token_store.dart';
import 'ports/screen_repository.dart';
import 'ports/sdui_observer.dart';

/// Where [SduiScreen] loads Stac JSON from when no repository is injected.
enum SduiScreenSource {
  /// Bundled JSON, e.g. `assets/screens/{name}.json`.
  asset,

  /// HTTP GET `{baseUrl}{screenPath}`.
  network,
}

/// Host-provided navigation from a Stac `sduiNavigate` action.
typedef SduiNavigateCallback =
    void Function(BuildContext context, String screen, {String style});

/// Configuration for [Sdui.initialize] / [SduiClient.bootstrap].
class SduiConfig {
  const SduiConfig({
    required this.source,
    this.baseUrl = '',
    this.screenPath = '/sdui/screens/{name}',
    this.assetPath = 'assets/screens/{name}.json',
    this.tokenStore,
    this.onUnauthorized,
    this.onLogout,
    this.onNavigateScreen,
    this.dio,
    this.screenRepository,
    this.observer,
  });

  /// Asset fixtures or the real API. Ignored when [screenRepository] is set.
  final SduiScreenSource source;

  /// API origin without trailing slash, e.g. `https://api.example.com`.
  final String baseUrl;

  /// Path template. `{name}` is replaced with the screen id.
  final String screenPath;

  /// Asset template. `{name}` is replaced with the screen id.
  final String assetPath;

  final TokenStore? tokenStore;

  /// Called on HTTP 401. The host should clear the session and go to login.
  final VoidCallback? onUnauthorized;

  /// Called from the Stac `sduiLogout` action.
  final VoidCallback? onLogout;

  /// Called from the Stac `sduiNavigate` action.
  final SduiNavigateCallback? onNavigateScreen;

  /// Optional shared client. If omitted, [SduiClient] creates one.
  final Dio? dio;

  /// When set, skips the asset/network switch (OCP).
  final ScreenRepository? screenRepository;

  /// Optional analytics/diagnostics hook.
  final SduiObserver? observer;

  String resolveAssetPath(String name) => assetPath.replaceAll('{name}', name);

  String resolveScreenUrl(String name) {
    final path = screenPath.replaceAll('{name}', name);
    if (baseUrl.isEmpty) {
      return path;
    }
    return '$baseUrl$path';
  }
}
