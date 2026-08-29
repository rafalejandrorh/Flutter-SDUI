# sdui_client

Reusable Stac SDUI client for Flutter apps. Hosts load named screens as JSON (bundled assets or an API), render them with Stac, and wire auth plus navigation through host callbacks.

## Depend via path

```yaml
dependencies:
  sdui_client:
    path: ../SDUI
```

## Initialize

Call `Sdui.initialize` before `runApp`:

```dart
import 'package:sdui_client/sdui_client.dart';

await Sdui.initialize(
  config: SduiConfig(
    source: SduiScreenSource.asset, // or SduiScreenSource.network
    baseUrl: 'http://127.0.0.1:8000',
    tokenStore: tokenStore,
    onUnauthorized: auth.logout,
    onLogout: auth.logout,
    onNavigateScreen: (context, screen, {style = 'push'}) {
      // Host routes to SduiRoutes.screen(screen)
    },
  ),
);
```

## DynamicScreen

```dart
DynamicScreen(name: 'home')
```

## TokenStore

Implement `TokenStore` (`read` / `write` / `clear`) for the bearer token. Use `MemoryTokenStore` in tests; use secure storage in production.

## Screen source

- **asset** — bundled fixtures, default `assets/screens/{name}.json`
- **network** — HTTP GET `{baseUrl}/sdui/screens/{name}`

Switch the host app to the API with dart-defines SDUI_USE_NETWORK=true and SDUI_API_BASE_URL (default http://127.0.0.1:8000).
