/// Path helpers for SDUI screens. Host auth routes stay in the host app.
class SduiRoutes {
  static const screenPrefix = '/sdui';

  static String screen(String name) => '$screenPrefix/$name';

  static String? screenNameFromPath(String path) {
    const prefix = '$screenPrefix/';
    if (!path.startsWith(prefix)) {
      return null;
    }
    final name = path.substring(prefix.length);
    if (name.isEmpty || name.contains('/')) {
      return null;
    }
    return name;
  }
}
