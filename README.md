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
  extraWidgetParsers: const [], // optional StacParser list
);
```

Inject a custom [ScreenRepository] via `SduiConfig.screenRepository` to skip the asset/network switch.

Pass an [SduiObserver] to `initialize` (or `SduiConfig.observer`) to receive load latency, errors, actions, and render failures.

Dio sends `X-SDUI-Client-Version` so the API can negotiate the contract later.

## Screen contract

The loader accepts both shapes:

1. **Raw Stac** — a widget tree with `type` (legacy / asset fixtures). Treated as `schemaVersion` 0.
2. **Envelope** — `{ "schemaVersion": 1, "name": "home", "body": { "type": "scaffold", ... } }`. Future versions fail with [SduiUnsupportedVersionException] instead of a Stac crash.

The HTTP API wraps the Core widget tree in the envelope. `SduiScreen` isolates `Stac.fromJson` and shows a retry fallback when render fails.

## SduiScreen

```dart
SduiScreen(name: 'home')
// DynamicScreen(name: 'home') is a typedef alias
```

Pass `repository` and `renderer` to test or override the facade.

## TokenStore

Implement `TokenStore` (`read` / `write` / `clear`) for the bearer token. Use `MemoryTokenStore` in tests; use secure storage in production.

## Screen source

- **asset** — bundled fixtures, default `assets/screens/{name}.json`
- **network** — HTTP GET `{baseUrl}/sdui/screens/{name}`

Switch the host app to the API with dart-defines `SDUI_USE_NETWORK=true` and `SDUI_API_BASE_URL` (default `http://127.0.0.1:8000`). Dio uses that origin as `baseUrl` so Stac `networkRequest` actions can call relative paths such as `/sdui/actions/profile`.

## Routes

`SduiRoutes.screen('home')` → `/sdui/home`. Login and register paths belong to the host app.
