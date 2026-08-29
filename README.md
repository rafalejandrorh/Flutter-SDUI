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
    onUnauthorized: auth.clearSession, // local only — do not POST /auth/logout
    onLogout: auth.logout, // must call POST /auth/logout, then clear the token
    onNavigateScreen: (context, screen, {style = 'push'}) {
      // Host routes to SduiRoutes.screen(screen)
    },
    viewPolicy: const SduiViewPolicy(
      loadingLabel: 'Cargando',
      errorMessage: 'No se pudo cargar esta pantalla.',
      retryLabel: 'Reintentar',
    ),
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

## Cache (SWR + ETag)

The default asset/network repository is wrapped with [CachedScreenRepository] (`SduiConfig.cacheScreens`, default `true`). Injected `screenRepository` is left as-is so hosts can compose their own decorator.

- **SWR**: a cache hit is returned immediately; a background fetch updates [ScreenChangeSource.watch] when the document changes.
- **ETag**: [NetworkScreenRepository] sends `If-None-Match` and treats HTTP 304 as “keep cache”.
- **Store**: in-memory [MemoryScreenCache] by default. Pass `screenCache` to persist (disk is a host [ScreenCache]).
- Disable with `cacheScreens: false`, or skip revalidation for a while with `CachedScreenRepository.staleAfter`.

## Logout

`sduiLogout` only invokes `SduiConfig.onLogout`. The library does not call the API. The host callback **must** `POST /auth/logout` (or equivalent) and then clear [TokenStore]. Use a different callback for `onUnauthorized` (401): revoke-on-401 can loop if the revoke call itself returns 401.

## SduiScreen

```dart
SduiScreen(name: 'home')
// DynamicScreen(name: 'home') is a typedef alias
```

Pass `repository` and `renderer` to test or override the facade. Loading/error UI, copies, and semantics come from [SduiViewPolicy] (`SduiConfig.viewPolicy` or the widget). `loadingBuilder` / `errorBuilder` still override per screen.

## TokenStore

Implement `TokenStore` (`read` / `write` / `clear`) for the bearer token. Use `MemoryTokenStore` in tests; use secure storage in production.

## Screen source

- **asset** — bundled fixtures, default `assets/screens/{name}.json`
- **network** — HTTP GET `{baseUrl}/sdui/screens/{name}`

Switch the host app to the API with dart-defines `SDUI_USE_NETWORK=true` and `SDUI_API_BASE_URL` (default `http://127.0.0.1:8000`). Dio uses that origin as `baseUrl` so Stac `networkRequest` actions can call relative paths such as `/sdui/actions/profile`.

## Routes

`SduiRoutes.screen('home')` → `/sdui/home`. Login and register paths belong to the host app.
