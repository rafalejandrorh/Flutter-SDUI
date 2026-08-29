# Instalación

El paquete se llama `sdui_client`. No está publicado en pub.dev: se consume como dependencia path (o, en el futuro, git).

## Requisitos

- Dart SDK `^3.11.5`
- Flutter `>=3.35.0`
- Dependencias de runtime: `dio`, `stac`, `stac_framework`

El paquete no declara assets propios. Si el host usa `SduiScreenSource.asset`, debe registrar los JSON en su `pubspec.yaml`.

## Desarrollo del propio cliente

```bash
git clone git@github.com:rafalejandrorh/Flutter-SDUI.git
cd Flutter-SDUI
flutter pub get
flutter test
dart analyze
```

Detalle de la suite en [tests](tests.md).

## Como dependencia (path)

Patrón usado por SDUI-App cuando el cliente está en un directorio hermano. Los cambios en `lib/` se ven al instante.

```yaml
dependencies:
  sdui_client:
    path: ../SDUI
```

```bash
flutter pub get
```

Si se cargan fixtures locales:

```yaml
flutter:
  assets:
    - assets/screens/
```

El template por defecto es `assets/screens/{name}.json` (`SduiConfig.assetPath`).

## Como dependencia (git)

Si el host no tiene el repo al lado:

```yaml
dependencies:
  sdui_client:
    git:
      url: https://github.com/rafalejandrorh/Flutter-SDUI.git
```

Hoy el flujo de desarrollo es path. No hay tags semver ni publicación en pub.dev.

## Verificación

Tras instalar, el import debe resolverse y `Sdui.initialize` debe llamarse **antes** de `runApp`:

```dart
import 'package:sdui_client/sdui_client.dart';

await Sdui.initialize(
  config: SduiConfig(source: SduiScreenSource.asset),
);
```

Guía de cableado en [uso](uso.md).
