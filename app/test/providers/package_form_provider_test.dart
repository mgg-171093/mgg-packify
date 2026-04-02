import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packgen/models/component_config.dart';
import 'package:mgg_packgen/models/package_config.dart';
import 'package:mgg_packgen/providers/package_form_provider.dart';

void main() {
  late ProviderContainer container;
  late PackageFormNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(packageFormProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('PackageFormNotifier', () {
    test('initial state is empty', () {
      final state = container.read(packageFormProvider);
      expect(state.ticket, '');
      expect(state.ambiente, 'QA');
      expect(state.iteracion, '01');
      expect(state.selectedTypes, isEmpty);
      expect(state.instances, isEmpty);
    });

    // ── toggleComponent ─────────────────────────

    test('toggleComponent: adds type to selectedTypes', () {
      notifier.toggleComponent(ComponentType.sql);
      final state = container.read(packageFormProvider);
      expect(state.selectedTypes, contains(ComponentType.sql));
    });

    test('toggleComponent: initializes empty instance for new type', () {
      notifier.toggleComponent(ComponentType.sql);
      final state = container.read(packageFormProvider);
      expect(state.instances[ComponentType.sql], isNotNull);
      expect(state.instances[ComponentType.sql]!.length, 1);
    });

    test('toggleComponent: removes type when toggled again', () {
      notifier.toggleComponent(ComponentType.sql);
      notifier.toggleComponent(ComponentType.sql);
      final state = container.read(packageFormProvider);
      expect(state.selectedTypes, isNot(contains(ComponentType.sql)));
    });

    test('toggleComponent: preserves instances on deselect/reselect', () {
      notifier.toggleComponent(ComponentType.sql);
      notifier.updateInstance(
        ComponentType.sql,
        0,
        const ComponentInstanceState(baseDatos: 'MYDB'),
      );
      notifier.toggleComponent(ComponentType.sql);
      notifier.toggleComponent(ComponentType.sql);
      final state = container.read(packageFormProvider);
      expect(state.instances[ComponentType.sql]![0].baseDatos, 'MYDB');
    });

    test('toggleComponent: liferay_build initializes single instance', () {
      notifier.toggleComponent(ComponentType.liferayBuild);
      final state = container.read(packageFormProvider);
      expect(state.selectedTypes, contains(ComponentType.liferayBuild));
      expect(state.instances[ComponentType.liferayBuild]!.length, 1);
    });

    // ── addInstance ──────────────────────────────

    test('addInstance: adds new empty instance for multi-instance type', () {
      notifier.toggleComponent(ComponentType.sql);
      notifier.addInstance(ComponentType.sql);
      final state = container.read(packageFormProvider);
      expect(state.instances[ComponentType.sql]!.length, 2);
    });

    test('addInstance: does NOT add for liferay_build (single-instance)', () {
      notifier.toggleComponent(ComponentType.liferayBuild);
      notifier.addInstance(ComponentType.liferayBuild);
      final state = container.read(packageFormProvider);
      expect(state.instances[ComponentType.liferayBuild]!.length, 1);
    });

    // ── removeInstance ───────────────────────────

    test('removeInstance: removes instance at given index', () {
      notifier.toggleComponent(ComponentType.sql);
      notifier.addInstance(ComponentType.sql);
      notifier.addInstance(ComponentType.sql);
      notifier.removeInstance(ComponentType.sql, 1);
      final state = container.read(packageFormProvider);
      expect(state.instances[ComponentType.sql]!.length, 2);
    });

    test('removeInstance: does not crash on invalid index', () {
      notifier.toggleComponent(ComponentType.sql);
      notifier.removeInstance(ComponentType.sql, 99);
      final state = container.read(packageFormProvider);
      expect(state.instances[ComponentType.sql]!.length, 1);
    });

    // ── updateInstance ───────────────────────────

    test('updateInstance: updates correct instance by index', () {
      notifier.toggleComponent(ComponentType.sql);
      notifier.addInstance(ComponentType.sql);
      notifier.updateInstance(
        ComponentType.sql,
        0,
        const ComponentInstanceState(baseDatos: 'DB_01'),
      );
      notifier.updateInstance(
        ComponentType.sql,
        1,
        const ComponentInstanceState(baseDatos: 'DB_02'),
      );
      final state = container.read(packageFormProvider);
      expect(state.instances[ComponentType.sql]![0].baseDatos, 'DB_01');
      expect(state.instances[ComponentType.sql]![1].baseDatos, 'DB_02');
    });

    // ── packageName getter ───────────────────────

    test('packageName: formats correctly', () {
      notifier.updateTicket('MX01-274906');
      notifier.updateAmbiente('QA');
      notifier.updateIteracion('01');
      final state = container.read(packageFormProvider);
      expect(state.packageName, 'MX01-274906-PortalRetail_QA-01');
    });

    test('packageName: zero-pads single-digit iteracion', () {
      notifier.updateTicket('MX01-001');
      notifier.updateIteracion('5');
      final state = container.read(packageFormProvider);
      expect(state.packageName, contains('-05'));
    });

    // ── updateServer ─────────────────────────────

    test('updateServer: QA and PROD are independent', () {
      notifier.updateServer('QA', const ServerConfig(api: 'qa-server'));
      notifier.updateServer('PROD', const ServerConfig(api: 'prod-server'));
      final state = container.read(packageFormProvider);
      expect(state.servers['QA']!.api, 'qa-server');
      expect(state.servers['PROD']!.api, 'prod-server');
    });

    // ── prefill ──────────────────────────────────

    test('prefill: populates state from clone response map', () {
      notifier.prefill({
        'ticket': 'MX01-999',
        'hu_nombre': 'Test HU',
        'ambiente': 'PROD',
        'iteracion': '03',
        'ruta_packages': r'C:\Packages',
        'componentes': [
          {
            'tipo': 'sql',
            'instancias': [
              {
                'base_datos': 'TEST_DB',
                'scripts': ['script.sql'],
              },
            ],
          },
        ],
      });

      final state = container.read(packageFormProvider);
      expect(state.ticket, 'MX01-999');
      expect(state.huNombre, 'Test HU');
      expect(state.ambiente, 'PROD');
      expect(state.iteracion, '03');
      expect(state.selectedTypes, contains(ComponentType.sql));
      expect(state.instances[ComponentType.sql]![0].baseDatos, 'TEST_DB');
    });

    // ── reset ────────────────────────────────────

    test('reset: clears all state to empty', () {
      notifier.updateTicket('MX01-99');
      notifier.toggleComponent(ComponentType.sql);
      notifier.reset();
      final state = container.read(packageFormProvider);
      expect(state.ticket, '');
      expect(state.selectedTypes, isEmpty);
    });
  });
}
