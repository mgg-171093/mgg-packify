import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packify/models/package_template.dart';

void main() {
  group('PackageTemplate', () {
    // ── fromJson ─────────────────────────────────

    test('fromJson parses name and selectedTypes correctly', () {
      final template = PackageTemplate.fromJson({
        'name': 'API + SQL',
        'selectedTypes': ['api_iis', 'sql'],
        'instancesJson': [],
      });

      expect(template.name, 'API + SQL');
      expect(template.selectedTypes, ['api_iis', 'sql']);
      expect(template.instancesJson, isEmpty);
    });

    test('fromJson parses instancesJson entries', () {
      final template = PackageTemplate.fromJson({
        'name': 'Full Deploy',
        'selectedTypes': ['sql', 'blob'],
        'instancesJson': [
          {
            'base_datos': 'MY_DB',
            'scripts': ['V001.sql'],
          },
          {'nombre': 'archivo.css', 'tipo': 'css'},
        ],
      });

      expect(template.instancesJson.length, 2);
      expect(template.instancesJson[0]['base_datos'], 'MY_DB');
      expect(template.instancesJson[1]['tipo'], 'css');
    });

    // ── toJson ───────────────────────────────────

    test('toJson serializes all fields', () {
      final template = PackageTemplate(
        name: 'My Template',
        selectedTypes: const ['liferay', 'apim'],
        instancesJson: const [
          {'nombre': 'tema', 'tipo_liferay': 'theme'},
        ],
      );

      final json = template.toJson();

      expect(json['name'], 'My Template');
      expect(json['selectedTypes'], ['liferay', 'apim']);
      expect((json['instancesJson'] as List).length, 1);
      expect(
        (json['instancesJson'] as List<Map<String, dynamic>>)[0]['nombre'],
        'tema',
      );
    });

    // ── round-trip ───────────────────────────────

    test('fromJson/toJson round-trip preserves all fields', () {
      final original = {
        'name': 'QA Standard',
        'selectedTypes': ['sql', 'api_docker', 'blob'],
        'instancesJson': [
          {
            'base_datos': 'RETAIL_DB',
            'scripts': ['init.sql', 'seed.sql'],
          },
          {'nombre': 'api-service', 'imagen': 'api:1.0'},
          {'nombre': 'logo.png', 'tipo': 'img'},
        ],
      };

      final template = PackageTemplate.fromJson(original);
      final roundTripped = template.toJson();

      expect(roundTripped['name'], original['name']);
      expect(roundTripped['selectedTypes'], original['selectedTypes']);
      final instances = roundTripped['instancesJson'] as List;
      expect(instances.length, 3);
      expect((instances[0] as Map)['base_datos'], 'RETAIL_DB');
    });

    // ── empty instancesJson ───────────────────────

    test('fromJson handles empty instancesJson list', () {
      final template = PackageTemplate.fromJson({
        'name': 'Empty',
        'selectedTypes': <String>[],
        'instancesJson': <Map<String, dynamic>>[],
      });

      expect(template.instancesJson, isEmpty);
      expect(template.selectedTypes, isEmpty);
    });
  });
}
