# sdui_client

Cliente Flutter reutilizable (`sdui_client`, Dart `^3.11.5`, Flutter `>=3.35.0`) que carga pantallas nombradas como JSON [Stac](https://docs.stac.dev) y las renderiza. El host aporta autenticación, navegación y almacenamiento seguro.

```dart
import 'package:flutter/material.dart';
import 'package:sdui_client/sdui_client.dart';

await Sdui.initialize(
  config: SduiConfig(source: SduiScreenSource.asset),
);

runApp(const MaterialApp(home: SduiScreen(name: 'home')));
```

El JSON lo emite [SDUI-Core](https://github.com/rafalejandrorh/SDUI-Core) (o un host PHP). Este paquete no genera pantallas: las carga, cachea, versiona y pinta.

## Documentación

| Documento | Contenido |
|-----------|-----------|
| [Objetivos](docs/objetivos.md) | Problema, metas, no-objetivos y ecosistema |
| [Arquitectura](docs/arquitectura.md) | Capas, bootstrap, contrato y flujo de carga |
| [Diseño](docs/diseno.md) | Patrones, convenciones y cómo extender el paquete |
| [Tests](docs/tests.md) | Suite `flutter test`, fixtures Core y goldens |
| [Instalación](docs/instalacion.md) | Requisitos y consumo vía path |
| [Uso](docs/uso.md) | Guía práctica: initialize, pantallas, auth y cache |
