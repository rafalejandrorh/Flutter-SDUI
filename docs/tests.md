# Tests

La suite es `flutter_test`. No hay Makefile, grupos de CI ni scripts extra. `analysis_options.yaml` endurece el analyzer; no define el runner.

## Cómo ejecutar

Desde la raíz del paquete, tras `flutter pub get`:

```bash
flutter test
dart analyze

flutter test test/php_core_contract_test.dart
flutter test --update-goldens test/php_core_golden_test.dart
flutter test --coverage
```

El directorio `coverage/` está en `.gitignore`.

## Organización

```
test/
├── screen_document_test.dart
├── asset_screen_repository_test.dart
├── network_screen_repository_test.dart
├── cached_screen_repository_test.dart
├── sdui_client_test.dart
├── sdui_screen_test.dart
├── builtin_parsers_test.dart
├── bar_chart_test.dart
├── php_core_contract_test.dart
├── php_core_golden_test.dart
├── support/
│   ├── fakes.dart
│   └── php_core_fixtures.dart
├── fixtures/php_core/
│   ├── home.json
│   ├── details.json
│   └── form.json
└── goldens/
    ├── php_core_home.png
    ├── php_core_details.png
    ├── bar_chart_bars.png
    └── bar_chart_empty.png
```

La mayoría de los tests de widget no arrancan Stac: inyectan `FakeRenderer`. Los goldens sí usan el renderer real.

## Qué valida cada archivo

### `screen_document_test.dart`

`ScreenDocument.parse`: Stac legado (`schemaVersion` 0), envelope v1, rechazo de versión futura, JSON que no es ni árbol ni envelope, envelope sin `body` Stac.

### `asset_screen_repository_test.dart`

Parse de un árbol empaquetado, asset ausente → `SduiLoadFailedException`, rethrow de fallos de parse tipados. Usa un `AssetBundle` en memoria.

### `network_screen_repository_test.dart`

GET 200 con ETag, `If-None-Match` + 304 → `notModified`, errores de transporte envueltos en `SduiLoadFailedException`.

### `cached_screen_repository_test.dart`

Hit + revalidación SWR, `staleAfter` sin revalidar, `loadFresh` salta ese hit y sustituye la entrada, 304 conserva cache, GET fresco actualiza cache y notifica `watch`.

### `sdui_client_test.dart`

`SduiConfig` (templates de path), `SduiRoutes`, `MemoryTokenStore`, `Sdui.initialize` (headers Dio, repo inyectado, wrap de cache / `cacheScreens: false`), parsers `sduiNavigate` / `sduiLogout`, `MemoryScreenRepository`.

### `sdui_screen_test.dart`

Loading, `loadingBuilder` / `errorBuilder`, render inyectado, retry, observer en carga OK, copys y builders de `SduiViewPolicy`, update SWR vía `ScreenChangeSource`, fallback si el renderer lanza o devuelve `null`, reload al cambiar `name`, fallback a la fachada.

### `builtin_parsers_test.dart`

`Sdui.initialize` sin parsers extra resuelve `sduiShare` (la hoja se sustituye por un fake). Un extra con el mismo `actionType` no corre. `sduiReload` pide `loadFresh` una vez, pinta el documento nuevo y, si el GET falla, deja el anterior y avisa `onScreenError`.

### `bar_chart_test.dart`

`barChart` con dos barras y con lista vacía, a través de Stac. Goldens propios; los de `home` y `details` no se regeneran.

### `php_core_contract_test.dart`

Contrato con los snapshots de SDUI-Core (`tests/ScreenSnapshotTest.php`):

1. Si el repo Core está de hermano (`../../../Backend/Owner/SDUI-Core`), las copias en `test/fixtures/php_core/` deben coincidir. Si no está, el test no hace nada.
2. Los tres árboles parsean como Stac legado (`scaffold` + `appBar`).
3. Los mismos árboles parsean como `body` de envelope v1.
4. Semántica: `home` expone `sduiNavigate` y `sduiLogout`; `details` hace `navigate` pop; `form` conserva ids `name` / `email` y `validateForm`.

Core es la fuente de verdad. Flutter bundlea copias para poder correr sin Core checked out.

### `php_core_golden_test.dart`

`home` y `details` se pintan con Stac real (390×844) y se comparan con PNG en `test/goldens/`. `form` está en el contrato, no en goldens.

Helpers en `support/fakes.dart`: `FakeRenderer`, `ThrowingRenderer`, `NullRenderer`, `RecordingObserver`, `StreamingRepo`, `PendingScreenRepository`.

## Cómo actualizar un fixture Core

Cuando el JSON de una pantalla de referencia cambia **a propósito** en SDUI-Core:

1. Actualizar el builder y el golden en Core (`tests/fixtures/<nombre>.json`).
2. Copiar el JSON a `test/fixtures/php_core/<nombre>.json`.
3. Si cambió `home` o `details`, regenerar goldens: `flutter test --update-goldens test/php_core_golden_test.dart`.
4. Correr `flutter test` y confirmar que solo cambian ese snapshot y, si aplica, el PNG.

No “arreglar” un drift reescribiendo el fixture Flutter si Core no debía cambiar: el test de sync está para detectar regresiones de forma.

## Huecos conocidos

No se vende cobertura total. Falta, entre otras cosas:

- `SduiAuthInterceptor` (Bearer y 401 / `onUnauthorized`).
- Golden de `form` e interacción (tap → navigate / logout / `validateForm`).
- `onScreenError` en cargas fallidas (el observer de éxito sí se aserta).
- `ScreenCache` persistente (solo el camino in-memory).

## CI

No hay workflows en este repositorio. La red de seguridad es `flutter test` y `dart analyze` en local y en el host que depende del paquete.
