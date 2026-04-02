import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packgen/models/options_model.dart';

void main() {
  group('OptionsModel', () {
    // ── defaults ──────────────────────────────────

    test('empty() returns expected defaults', () {
      final model = OptionsModel.empty();
      expect(model.estatusList, ['modificado', 'nuevo']);
      expect(model.tipoSqlList, ['sp', 'trigger', 'script', 'job']);
      expect(model.tipoBlobList, ['css', 'scss', 'js']);
    });

    test('default constructor has same defaults as empty()', () {
      const model = OptionsModel();
      expect(model.estatusList, ['modificado', 'nuevo']);
      expect(model.tipoSqlList, ['sp', 'trigger', 'script', 'job']);
      expect(model.tipoBlobList, ['css', 'scss', 'js']);
    });

    // ── fromJson ──────────────────────────────────

    test('fromJson parses all fields correctly', () {
      final json = {
        'estatus_options': ['nuevo', 'modificado', 'eliminado'],
        'tipo_sql_options': ['sp', 'script'],
        'tipo_blob_options': ['css', 'js'],
      };

      final model = OptionsModel.fromJson(json);
      expect(model.estatusList, ['nuevo', 'modificado', 'eliminado']);
      expect(model.tipoSqlList, ['sp', 'script']);
      expect(model.tipoBlobList, ['css', 'js']);
    });

    test('fromJson falls back to defaults when fields are missing', () {
      final model = OptionsModel.fromJson({});
      expect(model.estatusList, ['modificado', 'nuevo']);
      expect(model.tipoSqlList, ['sp', 'trigger', 'script', 'job']);
      expect(model.tipoBlobList, ['css', 'scss', 'js']);
    });

    test('fromJson falls back to defaults when fields are null', () {
      final json = <String, dynamic>{
        'estatus_options': null,
        'tipo_sql_options': null,
        'tipo_blob_options': null,
      };
      final model = OptionsModel.fromJson(json);
      expect(model.estatusList, ['modificado', 'nuevo']);
      expect(model.tipoSqlList, ['sp', 'trigger', 'script', 'job']);
      expect(model.tipoBlobList, ['css', 'scss', 'js']);
    });

    // ── toJson ────────────────────────────────────

    test('toJson uses correct keys', () {
      const model = OptionsModel(
        estatusList: ['a', 'b'],
        tipoSqlList: ['sp'],
        tipoBlobList: ['css'],
      );
      final json = model.toJson();
      expect(json['estatus_options'], ['a', 'b']);
      expect(json['tipo_sql_options'], ['sp']);
      expect(json['tipo_blob_options'], ['css']);
    });

    // ── fromJson/toJson round-trip ─────────────────

    test('fromJson → toJson round-trip preserves all values', () {
      final original = OptionsModel(
        estatusList: const ['nuevo', 'modificado'],
        tipoSqlList: const ['sp', 'trigger'],
        tipoBlobList: const ['css', 'js'],
      );

      final json = original.toJson();
      final recovered = OptionsModel.fromJson(json);

      expect(recovered.estatusList, original.estatusList);
      expect(recovered.tipoSqlList, original.tipoSqlList);
      expect(recovered.tipoBlobList, original.tipoBlobList);
    });

    test('round-trip with default values is lossless', () {
      final original = OptionsModel.empty();
      final json = original.toJson();
      final recovered = OptionsModel.fromJson(json);

      expect(recovered.estatusList, original.estatusList);
      expect(recovered.tipoSqlList, original.tipoSqlList);
      expect(recovered.tipoBlobList, original.tipoBlobList);
    });

    // ── copyWith ──────────────────────────────────

    test('copyWith updates only specified fields', () {
      const model = OptionsModel();
      final updated = model.copyWith(estatusList: ['solo_nuevo']);
      expect(updated.estatusList, ['solo_nuevo']);
      expect(updated.tipoSqlList, model.tipoSqlList);
      expect(updated.tipoBlobList, model.tipoBlobList);
    });

    test('copyWith with no args returns equivalent model', () {
      const model = OptionsModel();
      final copy = model.copyWith();
      expect(copy.estatusList, model.estatusList);
      expect(copy.tipoSqlList, model.tipoSqlList);
      expect(copy.tipoBlobList, model.tipoBlobList);
    });
  });

  // ── ApiIisServiceEntry / ApiDockerServiceEntry ────────────────

  group('apiIisServices', () {
    test('parses apiIisServices from json', () {
      final json = {
        'api_iis_services': [
          {'nombre': 'SvcA', 'ruta': r'C:\SvcA.csproj'},
        ],
      };
      final model = OptionsModel.fromJson(json);
      expect(model.apiIisServices.length, 1);
      expect(model.apiIisServices[0].nombre, 'SvcA');
      expect(model.apiIisServices[0].ruta, r'C:\SvcA.csproj');
    });

    test('defaults apiIisServices to empty when key missing', () {
      final model = OptionsModel.fromJson({});
      expect(model.apiIisServices.isEmpty, isTrue);
    });
  });

  group('apiDockerServices', () {
    test('parses apiDockerServices from json', () {
      final json = {
        'api_docker_services': [
          {'nombre': 'DockerSvc'},
        ],
      };
      final model = OptionsModel.fromJson(json);
      expect(model.apiDockerServices.length, 1);
      expect(model.apiDockerServices[0].nombre, 'DockerSvc');
    });

    test('defaults apiDockerServices to empty when key missing', () {
      final model = OptionsModel.fromJson({});
      expect(model.apiDockerServices.isEmpty, isTrue);
    });
  });

  // ── sqlDatabases ───────────────────────────────

  group('sqlDatabases', () {
    test('sqlDatabases parses from json', () {
      final json = {
        'sql_databases': ['RAWRAPS', 'SCADB'],
      };
      final model = OptionsModel.fromJson(json);
      expect(model.sqlDatabases, ['RAWRAPS', 'SCADB']);
    });

    test('sqlDatabases defaults to empty when key missing', () {
      final model = OptionsModel.fromJson({});
      expect(model.sqlDatabases.isEmpty, isTrue);
    });

    test('sqlDatabases round-trips through toJson', () {
      final model = OptionsModel(sqlDatabases: const ['DB1']);
      final json = model.toJson();
      expect(json['sql_databases'], ['DB1']);
    });
  });
}
