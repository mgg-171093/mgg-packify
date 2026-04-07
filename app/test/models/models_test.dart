import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packify/models/component_config.dart';
import 'package:mgg_packify/models/generate_result.dart';
import 'package:mgg_packify/models/package_config.dart';
import 'package:mgg_packify/models/settings_model.dart';
import 'package:mgg_packify/models/options_model.dart';

void main() {
  group('ComponentInstanceState.toJson', () {
    test('liferay_build: only returns build_id', () {
      const inst = ComponentInstanceState(buildId: '7957');
      final json = inst.toJson(ComponentType.liferayBuild);
      expect(json['build_id'], '7957');
      expect(json['estatus'], 'modificado');
      expect(json['tipo'], '');
    });

    test('sql: returns base_datos and scripts', () {
      const inst = ComponentInstanceState(
        baseDatos: 'RAWRAPSIIF',
        scripts: ['01_Migra.sql'],
      );
      final json = inst.toJson(ComponentType.sql);
      expect(json['base_datos'], 'RAWRAPSIIF');
      expect(json['scripts'], ['01_Migra.sql']);
    });

    test('api_iis: returns nombre_servicio and configs', () {
      const inst = ComponentInstanceState(
        nombreServicio: 'WebRetailAuth',
        configs: [ConfigEntry(clave: 'env', valor: 'QA')],
      );
      final json = inst.toJson(ComponentType.apiIis);
      expect(json['nombre_servicio'], 'WebRetailAuth');
      expect((json['configs'] as List).length, 1);
      expect((json['configs'] as List)[0]['clave'], 'env');
    });

    test('api_docker: same schema as api_iis', () {
      const inst = ComponentInstanceState(nombreServicio: 'DockerSvc');
      final json = inst.toJson(ComponentType.apiDocker);
      expect(json['nombre_servicio'], 'DockerSvc');
      expect(json.containsKey('configs'), isTrue);
    });

    test('blob: returns archivos list', () {
      const inst = ComponentInstanceState(
        archivos: [FileEntry(nombre: 'styles.css', carpeta: 'assets/css')],
      );
      final json = inst.toJson(ComponentType.blob);
      expect((json['archivos'] as List).length, 1);
      expect((json['archivos'] as List)[0]['nombre'], 'styles.css');
    });

    test('liferay: returns nombre, es_nueva, crear_pagina', () {
      const inst = ComponentInstanceState(
        nombre: 'MXAuth',
        esNueva: true,
        crearPagina: false,
      );
      final json = inst.toJson(ComponentType.liferay);
      expect(json['nombre'], 'MXAuth');
      expect(json['es_nueva'], true);
      expect(json['crear_pagina'], false);
      expect(json.containsKey('pagina'), isFalse);
    });

    test('liferay with crearPagina: includes pagina and widgets', () {
      const inst = ComponentInstanceState(
        nombre: 'MXAuth',
        crearPagina: true,
        pagina: 'Home',
        widgets: ['Widget1', 'Widget2'],
      );
      final json = inst.toJson(ComponentType.liferay);
      expect(json['crear_pagina'], true);
      expect(json['pagina'], 'Home');
      expect(json['widgets'], ['Widget1', 'Widget2']);
    });

    test('assets: returns nombre', () {
      const inst = ComponentInstanceState(nombre: 'logo.png');
      final json = inst.toJson(ComponentType.assets);
      expect(json['nombre'], 'logo.png');
      expect(json['estatus'], 'modificado');
      expect(json['tipo'], '');
    });

    test('apim: returns nombre_servicio', () {
      const inst = ComponentInstanceState(nombreServicio: 'ApiMgmt');
      final json = inst.toJson(ComponentType.apim);
      expect(json['nombre_servicio'], 'ApiMgmt');
      expect(json['estatus'], 'modificado');
      expect(json['tipo'], '');
    });

    // ── estatus / tipo defaults in toJson ──────────

    test('default estatus is "modificado" in toJson output', () {
      const inst = ComponentInstanceState();
      final json = inst.toJson(ComponentType.sql);
      expect(json['estatus'], 'modificado');
    });

    test('default tipo is empty string in toJson output', () {
      const inst = ComponentInstanceState();
      final json = inst.toJson(ComponentType.sql);
      expect(json['tipo'], '');
    });

    test('copyWith(estatus: "nuevo") round-trip via toJson', () {
      const inst = ComponentInstanceState(baseDatos: 'TEST_DB');
      final updated = inst.copyWith(estatus: 'nuevo');
      final json = updated.toJson(ComponentType.sql);
      expect(json['estatus'], 'nuevo');
      expect(json['base_datos'], 'TEST_DB');
    });

    test('copyWith(tipo: "sp") round-trip via toJson', () {
      const inst = ComponentInstanceState(baseDatos: 'MYDB');
      final updated = inst.copyWith(tipo: 'sp');
      final json = updated.toJson(ComponentType.sql);
      expect(json['tipo'], 'sp');
    });

    test('estatus and tipo included in all component type toJson outputs', () {
      const inst = ComponentInstanceState(estatus: 'nuevo', tipo: 'sp');
      for (final type in ComponentType.values) {
        final json = inst.toJson(type);
        expect(
          json.containsKey('estatus'),
          isTrue,
          reason: '${type.key} should include estatus',
        );
        expect(
          json.containsKey('tipo'),
          isTrue,
          reason: '${type.key} should include tipo',
        );
      }
    });
  });

  // ─────────────────────────────────────────────
  // SettingsModel fromJson/toJson roundtrip
  // ─────────────────────────────────────────────

  group('SettingsModel', () {
    test('fromJson/toJson roundtrip', () {
      final original = SettingsModel(
        qa: const ServerConfigModel(
          api: 'qa-api',
          bd: 'qa-bd',
          blob: 'qa-blob',
          liferay: 'qa-lr',
        ),
        prod: const ServerConfigModel(
          api: 'prod-api',
          bd: 'prod-bd',
          blob: 'prod-blob',
          liferay: 'prod-lr',
        ),
        lastUsed: const LastUsedModel(rutaPackages: r'C:\Packages'),
      );

      final json = original.toJson();
      final recovered = SettingsModel.fromJson(json);

      expect(recovered.qa.api, 'qa-api');
      expect(recovered.qa.bd, 'qa-bd');
      expect(recovered.prod.api, 'prod-api');
      expect(recovered.prod.liferay, 'prod-lr');
      expect(recovered.lastUsed?.rutaPackages, r'C:\Packages');
    });

    test('fromJson handles missing fields gracefully', () {
      final settings = SettingsModel.fromJson({});
      expect(settings.qa.api, '');
      expect(settings.prod.bd, '');
    });

    test('empty() returns blank settings', () {
      final empty = SettingsModel.empty();
      expect(empty.qa.api, '');
      expect(empty.prod.api, '');
    });
  });

  // ─────────────────────────────────────────────
  // PackageConfig.toJson
  // ─────────────────────────────────────────────

  group('PackageConfig.toJson', () {
    test('serializes all fields correctly', () {
      const config = PackageConfig(
        ticket: 'MX01-274906',
        huNombre: 'Test HU',
        ambiente: 'QA',
        iteracion: '01',
        rutaPackages: r'C:\Packages',
        componentes: [
          {'tipo': 'sql', 'instancias': []},
        ],
      );

      final json = config.toJson();
      expect(json['ticket'], 'MX01-274906');
      expect(json['ambiente'], 'qa'); // lowercased
      expect(json['iteracion'], '01');
      expect(json['ruta_packages'], r'C:\Packages');
      expect((json['componentes'] as List).length, 1);
    });

    test('iteracion is zero-padded', () {
      const config = PackageConfig(
        ticket: 'T',
        huNombre: '',
        ambiente: 'QA',
        iteracion: '3',
        rutaPackages: 'C:',
        componentes: [],
      );
      expect(config.toJson()['iteracion'], '03');
    });
  });

  // ─────────────────────────────────────────────
  // GenerateResult.fromJson
  // ─────────────────────────────────────────────

  group('GenerateResult.fromJson', () {
    test('parses all fields from API response', () {
      final result = GenerateResult.fromJson({
        'ok': true,
        'package_name': 'MX01-274906-PortalRetail_QA-01',
        'package_dir': r'C:\Packages\MX01-274906-PortalRetail_QA-01',
        'doc_path': r'C:\Packages\MX01-274906-PortalRetail_QA-01\doc.docx',
        'folders_created': ['folder1', 'folder2'],
      });

      expect(result.ok, isTrue);
      expect(result.packageName, 'MX01-274906-PortalRetail_QA-01');
      expect(result.foldersCreated.length, 2);
      expect(result.error, isNull);
    });

    test('handles missing fields with defaults', () {
      final result = GenerateResult.fromJson({});
      expect(result.ok, isFalse);
      expect(result.packageName, '');
      expect(result.foldersCreated, isEmpty);
    });
  });

  // ─────────────────────────────────────────────
  // OptionsModel — fromJson/toJson + defaults
  // ─────────────────────────────────────────────

  group('OptionsModel (in models_test)', () {
    test('fromJson/toJson round-trip preserves custom lists', () {
      final json = {
        'estatus_options': ['nuevo', 'modificado', 'eliminado'],
        'tipo_sql_options': ['sp', 'trigger'],
        'tipo_blob_options': ['css'],
      };
      final model = OptionsModel.fromJson(json);
      final recovered = OptionsModel.fromJson(model.toJson());

      expect(recovered.estatusList, ['nuevo', 'modificado', 'eliminado']);
      expect(recovered.tipoSqlList, ['sp', 'trigger']);
      expect(recovered.tipoBlobList, ['css']);
    });

    test('fromJson on empty map returns default lists', () {
      final model = OptionsModel.fromJson({});
      expect(model.estatusList, ['modificado', 'nuevo']);
      expect(model.tipoSqlList, ['sp', 'trigger', 'script', 'job']);
      expect(model.tipoBlobList, ['css', 'scss', 'js']);
    });

    test(
      'toJson keys are estatus_options, tipo_sql_options, tipo_blob_options',
      () {
        const model = OptionsModel();
        final json = model.toJson();
        expect(json.containsKey('estatus_options'), isTrue);
        expect(json.containsKey('tipo_sql_options'), isTrue);
        expect(json.containsKey('tipo_blob_options'), isTrue);
      },
    );
  });
}
