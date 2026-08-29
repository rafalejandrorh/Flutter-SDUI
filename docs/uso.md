# Uso

Ciclo de trabajo: `Sdui.initialize` → pintar `SduiScreen(name)` en una ruta del host. El cliente no conoce login ni `GoRouter`; el host enruta y aporta el token.

La forma del runtime está en [arquitectura](arquitectura.md). Cómo extenderlo, en [diseño](diseno.md).

## Initialize

Llamar antes de `runApp`. Ejemplo alineado con el host de referencia:

```dart
import 'package:sdui_client/sdui_client.dart';

await Sdui.initialize(
  config: SduiConfig(
    source: SduiScreenSource.asset, // o SduiScreenSource.network
    baseUrl: 'http://127.0.0.1:8000',
    tokenStore: tokenStore,
    onUnauthorized: auth.clearSession,
    onLogout: auth.logout,
    onNavigateScreen: (context, screen, {style = 'push'}) {
      final location = SduiRoutes.screen(screen);
      if (style == 'replace') {
        // context.go(location);
      } else {
        // context.push(location);
      }
    },
    viewPolicy: const SduiViewPolicy(
      loadingLabel: 'Cargando',
      errorMessage: 'No se pudo cargar esta pantalla.',
      retryLabel: 'Reintentar',
    ),
  ),
);
```

`onNavigateScreen` es obligatorio si alguna pantalla emite `sduiNavigate`. `baseUrl` también alimenta a Stac: las acciones `networkRequest` pueden usar paths relativos (`/sdui/actions/profile`).

Dio envía `X-SDUI-Client-Version: 1` para que la API negocie el contrato más adelante.

## Pantalla y rutas

```dart
SduiScreen(name: 'home')
// DynamicScreen(name: 'home') es un typedef alias
```

`SduiRoutes.screen('home')` → `/sdui/home`. `screenNameFromPath` extrae el nombre; rechaza segmentos anidados.

El host monta algo equivalente a `/sdui/:screen` → `SduiScreen(name: screen)`. Login y registro quedan fuera de este prefijo.

`repository`, `renderer`, `observer` y `viewPolicy` en el widget pisan la fachada (útil en tests). `loadingBuilder` / `errorBuilder` pisan la política **por pantalla**.

## Asset vs network

| `SduiScreenSource` | Origen |
|--------------------|--------|
| `asset` | Bundle: `assets/screens/{name}.json` (Stac crudo, `schemaVersion` 0) |
| `network` | `GET {baseUrl}/sdui/screens/{name}` (envelope v1) |

El host de referencia cambia de modo con dart-defines (`SDUI_USE_NETWORK`, `SDUI_API_BASE_URL`). En emulador Android el origin suele ser `http://10.0.2.2:8000`.

Inyectar `SduiConfig.screenRepository` ignora `source` (y no aplica el wrap automático de cache).

## Contrato JSON

Stac crudo (assets / snapshots de Core):

```json
{ "type": "scaffold", "body": { "type": "text", "data": "Hello" } }
```

Envelope que sirve la API:

```json
{
  "schemaVersion": 1,
  "name": "home",
  "body": { "type": "scaffold", "body": { "type": "text", "data": "Hello" } }
}
```

Una versión mayor que 1 no llega a Stac: `SduiUnsupportedVersionException` y UI de error/reintento.

## Token y logout

Implementar `TokenStore` (`read` / `write` / `clear`). `MemoryTokenStore` en tests; almacenamiento seguro en producción.

```dart
class SecureTokenStore implements TokenStore {
  @override
  Future<String?> read() async => /* flutter_secure_storage u otro */;

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> clear() async {}
}
```

- `onLogout` (acción `sduiLogout`): revocar en servidor y **después** `tokenStore.clear`.
- `onUnauthorized` (HTTP 401): solo sesión local. No reutilizar el callback de logout.

## Cache

Por defecto el repositorio asset/network va envuelto en `CachedScreenRepository` (`cacheScreens: true`):

- Hit → UI inmediata; revalidación en background; `SduiScreen` se actualiza vía `watch` si el documento cambió.
- Network envía `If-None-Match`; 304 conserva cache.
- Store: `MemoryScreenCache` salvo que se pase `screenCache`.

```dart
SduiConfig(
  source: SduiScreenSource.network,
  cacheScreens: false, // sin decorator
);

SduiConfig(
  source: SduiScreenSource.network,
  screenCache: MiDiskScreenCache(),
);
```

Para no revalidar un rato, componer a mano:

```dart
CachedScreenRepository(
  inner: NetworkScreenRepository(config: config, dio: dio),
  cache: MemoryScreenCache(),
  staleAfter: const Duration(minutes: 5),
);
```

Ese repo se inyecta en `screenRepository` (el wrap automático no se aplica encima).

## Política de vista

`SduiViewPolicy.material` usa copys en inglés y scaffolds Material. El host puede cambiar textos, semántica o builders globales:

```dart
viewPolicy: const SduiViewPolicy(
  loadingLabel: 'Cargando',
  errorMessage: 'No se pudo cargar esta pantalla.',
  retryLabel: 'Reintentar',
  showErrorDetails: false,
)
```

O reemplazar por completo `loadingBuilder` / `errorBuilder` en la política o en un `SduiScreen` concreto.

## Observer y parsers extra

```dart
class MetricsObserver extends SduiObserver {
  @override
  void onScreenLoad(String name, Duration latency, {required int schemaVersion}) {
    // analytics
  }

  @override
  void onScreenError(String name, Object error) {}

  @override
  void onRenderFailed(String name, Object error) {}

  @override
  void onAction(String actionType, {String? screen}) {}
}

await Sdui.initialize(
  config: config,
  observer: MetricsObserver(),
  extraWidgetParsers: const [/* StacParser */],
  extraActionParsers: const [/* StacActionParser */],
);
```

## Repositorio en tests

`MemoryScreenRepository` es público. Un `SduiRenderer` mínimo evita arrancar Stac:

```dart
class TextRenderer implements SduiRenderer {
  @override
  Widget? render(BuildContext context, ScreenDocument document) {
    return Text(document.name);
  }
}

final repo = MemoryScreenRepository({
  'home': {
    'type': 'scaffold',
    'body': {'type': 'text', 'data': 'Hello'},
  },
});

await Sdui.initialize(
  config: SduiConfig(
    source: SduiScreenSource.asset,
    screenRepository: repo,
    onNavigateScreen: (context, screen, {style = 'push'}) {},
  ),
  renderer: TextRenderer(),
);
```

`MemoryScreenRepository.errorForNextLoad` simula un fallo de carga. Tras los tests, `Sdui.reset()`.

Más detalle de la suite en [tests](tests.md).
