import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_client/src/data/json_object.dart';

void main() {
  group('asJsonObject', () {
    test('returns Map<String, dynamic> as-is', () {
      final source = <String, dynamic>{'type': 'text'};
      expect(asJsonObject(source, source: 'test'), same(source));
    });

    test('copies a generic Map', () {
      final source = <dynamic, dynamic>{'type': 'text', 'data': 'ok'};
      expect(asJsonObject(source, source: 'test'), {
        'type': 'text',
        'data': 'ok',
      });
    });

    test('decodes a JSON object string', () {
      expect(
        asJsonObject('{"type":"text","data":"from string"}', source: 'test'),
        {'type': 'text', 'data': 'from string'},
      );
    });

    test('throws FormatException for a non-object', () {
      expect(
        () => asJsonObject(['not', 'an', 'object'], source: 'fixture'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('fixture'),
          ),
        ),
      );
    });
  });
}
