/// Path helpers shared by host apps. Does not depend on go_router.
class SduiRoutes {
  static const login = '/login';
  static const register = '/register';
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
