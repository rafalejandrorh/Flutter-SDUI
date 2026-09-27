# Diseño

Las convenciones de este paquete están en los puertos y en el composition root, no en un contenedor. El contrato público es: `Sdui.initialize` + `SduiConfig` → `SduiScreen(name)`.

## Patrones

| Patrón | Dónde |
|--------|--------|
| **Puertos y adaptadores** | `ports/` vs `data/` y `rendering/` |
| **Fachada** | `Sdui` sobre `SduiClient` |
| **Composition root** | `SduiClient.bootstrap` |
| **Decorator** | `CachedScreenRepository` sobre cualquier `ScreenRepository` |
| **Strategy / OCP** | `SduiConfig.screenRepository` salta el switch asset/network |
| **Anti-corrupción** | Envelope vs Stac legado; versión > 1 falla antes de Stac |
| **Observer** | `SduiObserver` (no-op por defecto) |

No hay contenedor de DI, casos de uso ni persistencia más allá del cache de pantallas.

## Convenciones

- Analyzer estricto: `strict-casts`, `strict-inference`, `strict-raw-types` (`analysis_options.yaml`).
- Stac vive en un solo archivo (`stac_renderer.dart`) y no se reexporta. Los tests de widget usan `FakeRenderer`.
- Un `screenRepository` inyectado **no** se envuelve en cache. El host compone el decorator si lo necesita.
- `onLogout` no es `onUnauthorized`. Revocar en un 401 puede ciclar si el propio revoke responde 401.
- Rutas de auth son del host. `SduiRoutes` solo construye `/sdui/{name}`.
- El barrel exporta `StacActionParser` y `StacParser` para que el host extienda Stac sin importar `stac_framework` por su cuenta.

## Auth: dos callbacks

```dart
onUnauthorized: auth.clearSession, // 401: solo sesión local
onLogout: auth.logout,             // sduiLogout: POST /auth/logout y luego clear
```

La librería no decide el ciclo de vida del token: `TokenStore.read/write/clear` es del host. `MemoryTokenStore` es para tests.

## Qué queda fuera a propósito

- Contenedor de DI (el wiring es manual en `bootstrap`).
- Cache en disco. `MemoryScreenCache` es proceso; persistir es un `ScreenCache` del host.
- Llamadas HTTP de logout o login.
- Validar que el JSON sea Stac-legal más allá del envelope. Eso lo cubren los tests de contrato y el renderer.
- Generar JSON. El productor es SDUI-Core.

## Cómo añadir un repositorio

1. Implementar `ScreenRepository.load`. Si hay actualizaciones en background, también `ScreenChangeSource.watch`.
2. Si el origen entiende ETags, implementar `ConditionalScreenRepository.fetch` para que el decorator envíe `If-None-Match`.
3. Inyectar en `SduiConfig.screenRepository` (no pasará por el switch asset/network ni por el wrap automático de cache).
4. Tests con `MemoryScreenRepository` o un fake; ver [tests](tests.md).

## Cómo sustituir el renderer

Pasar `renderer:` a `Sdui.initialize` o a `SduiScreen`. Si se pasa en `bootstrap`, **no** se llama `Stac.initialize`. Útil en tests (`FakeRenderer`) o si el host no usa Stac.

## Cómo persistir el cache

Implementar `ScreenCache` (`read` / `write` / `remove` / `clear`) y pasarlo en `SduiConfig.screenCache`. El decorator sigue siendo `CachedScreenRepository`; solo cambia el store.

## Cómo observar

Extender `SduiObserver` y pasarlo a `initialize` o `SduiConfig.observer`. Eventos: `onScreenLoad`, `onScreenError`, `onAction`, `onRenderFailed`. `onUnknownWidget` está en el puerto y hoy no lo emite la librería.

## Parsers de la librería y parsers extra

`sduiShare`, `barChart`, `sduiReload`, `boundText` y el `dropdownMenu` que escribe `id` en el formulario se registran en `SduiClient.bootstrap`. Cualquier host que llame a `Sdui.initialize` los tiene, sin pasarlos en `extraActionParsers` / `extraWidgetParsers`.

`networkRequest` y `setValue` de la librería se registran al final y reemplazan los de Stac. El de red sustituye `{{response.formatted}}` en la acción del status antes de correrla. El de `setValue` guarda la clave y avisa a `boundText`. Stac 1.5 no hace ninguna de las dos cosas.

Esos dos parámetros siguen siendo para widgets y acciones del host. Stac registra la lista con `override: true`: el último parser de un mismo `type` o `actionType` gana. Por eso los tres de la librería se registran después de los del host. Un extra con el mismo nombre no los tapa.

`sduiNavigate` y `sduiLogout` se registran antes de los extra.

Inventario de tipos en [arquitectura](arquitectura.md). Ejemplos de cableado en [uso](uso.md).
