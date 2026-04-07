import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packify/models/component_config.dart';

void main() {
  // ─────────────────────────────────────────────
  // ConfigEntry.toJson — task 1.1
  // ─────────────────────────────────────────────

  group('ConfigEntry.toJson', () {
    // RED → GREEN: imagenPath present → key included
    test('includes imagen_path key when imagenPath is set', () {
      const entry = ConfigEntry(
        clave: 'env',
        valor: 'QA',
        imagenPath: '/home/user/pic.png',
      );
      final json = entry.toJson();
      expect(json['imagen_path'], '/home/user/pic.png');
    });

    // TRIANGULATE: imagenPath null → key absent
    test('omits imagen_path key when imagenPath is null', () {
      const entry = ConfigEntry(clave: 'env', valor: 'QA');
      final json = entry.toJson();
      expect(json.containsKey('imagen_path'), isFalse);
    });

    // TRIANGULATE: existing clave/valor still serialized correctly
    test('always includes clave and valor', () {
      const entry = ConfigEntry(clave: 'host', valor: 'localhost');
      final json = entry.toJson();
      expect(json['clave'], 'host');
      expect(json['valor'], 'localhost');
    });
  });

  // ─────────────────────────────────────────────
  // ConfigEntry.fromJson — task 1.2
  // ─────────────────────────────────────────────

  group('ConfigEntry.fromJson', () {
    // RED → GREEN: json with imagen_path → imagenPath is populated
    test('reads imagen_path into imagenPath field', () {
      final entry = ConfigEntry.fromJson({
        'clave': 'env',
        'valor': 'PRD',
        'imagen_path': '/tmp/screenshot.jpg',
      });
      expect(entry.imagenPath, '/tmp/screenshot.jpg');
    });

    // TRIANGULATE: json without imagen_path → imagenPath is null (backward compat)
    test('imagenPath is null when imagen_path key is absent', () {
      final entry = ConfigEntry.fromJson({'clave': 'k', 'valor': 'v'});
      expect(entry.imagenPath, isNull);
    });

    // TRIANGULATE: clave/valor still parsed correctly alongside imagen_path
    test('parses clave and valor alongside imagen_path', () {
      final entry = ConfigEntry.fromJson({
        'clave': 'dbUrl',
        'valor': 'jdbc://...',
        'imagen_path': '/img/arch.png',
      });
      expect(entry.clave, 'dbUrl');
      expect(entry.valor, 'jdbc://...');
      expect(entry.imagenPath, '/img/arch.png');
    });
  });

  // ─────────────────────────────────────────────
  // ConfigEntry.copyWith — bonus coverage for task 1.3
  // ─────────────────────────────────────────────

  group('ConfigEntry.copyWith', () {
    test('copies imagenPath when provided', () {
      const entry = ConfigEntry(clave: 'k', valor: 'v');
      final updated = entry.copyWith(imagenPath: '/path/img.png');
      expect(updated.imagenPath, '/path/img.png');
      expect(updated.clave, 'k');
      expect(updated.valor, 'v');
    });

    test('preserves existing imagenPath when not overridden', () {
      const entry = ConfigEntry(
        clave: 'k',
        valor: 'v',
        imagenPath: '/original.png',
      );
      final updated = entry.copyWith(clave: 'newKey');
      expect(updated.imagenPath, '/original.png');
    });
  });

  // ─────────────────────────────────────────────
  // ComponentInstanceState.toJson — publicar field
  // ─────────────────────────────────────────────

  group('ComponentInstanceState.toJson — publicar', () {
    test('apiIis toJson includes publicar field when true', () {
      const instance = ComponentInstanceState(publicar: true);
      final json = instance.toJson(ComponentType.apiIis);
      expect(json.containsKey('publicar'), isTrue);
      expect(json['publicar'], isTrue);
    });

    test('apiIis toJson publicar defaults to false', () {
      const instance = ComponentInstanceState();
      final json = instance.toJson(ComponentType.apiIis);
      expect(json.containsKey('publicar'), isTrue);
      expect(json['publicar'], isFalse);
    });

    test('apiDocker toJson does not include publicar', () {
      const instance = ComponentInstanceState(publicar: true);
      final json = instance.toJson(ComponentType.apiDocker);
      expect(json.containsKey('publicar'), isFalse);
    });
  });

  // ─────────────────────────────────────────────
  // ComponentInstanceState.toJson — scriptsCopiar field
  // ─────────────────────────────────────────────

  group('ComponentInstanceState — scriptsCopiar', () {
    test('sql scriptsCopiar included in toJson', () {
      const instance = ComponentInstanceState(
        scripts: ['a.sql', 'b.sql'],
        scriptsCopiar: [true, false],
      );
      final json = instance.toJson(ComponentType.sql);
      expect(json['scripts_copiar'], [true, false]);
    });

    test('sql scriptsCopiar defaults to false when missing', () {
      final instance = ComponentInstanceState.fromJson({
        'scripts': ['a.sql', 'b.sql'],
      });
      expect(instance.scriptsCopiar, [false, false]);
    });

    test('sql scriptsCopiar pads to match scripts length', () {
      final instance = ComponentInstanceState.fromJson({
        'scripts': ['a.sql', 'b.sql', 'c.sql'],
        'scripts_copiar': [true],
      });
      expect(instance.scriptsCopiar.length, 3);
      expect(instance.scriptsCopiar, [true, false, false]);
    });
  });
}
