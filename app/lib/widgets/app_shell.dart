import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Sidebar destinations definition
const _destinations = [
  // Index 0 — Dashboard
  (icon: Icons.dashboard_outlined, label: 'Dashboard', path: '/dashboard'),
  // Index 1 — Nuevo Paquete
  (
    icon: Icons.inventory_2_outlined,
    label: 'Nuevo Paquete',
    path: '/new-package',
  ),
  // Index 2 — Clonar
  (icon: Icons.content_copy_outlined, label: 'Clonar', path: '/clone'),
  // Index 3 — Historial
  (icon: Icons.history_outlined, label: 'Historial', path: '/history'),
  // Index 4 — Templates
  (icon: Icons.bookmark_outlined, label: 'Templates', path: '/templates'),
  // Index 5 — Servidores
  (
    icon: Icons.dns_outlined,
    label: 'Servidores',
    path: '/catalogos/servidores',
  ),
  // Index 6 — Servicios API
  (
    icon: Icons.miscellaneous_services_outlined,
    label: 'Servicios API',
    path: '/catalogos/servicios',
  ),
  // Index 7 — Estatus
  (icon: Icons.list_alt_outlined, label: 'Estatus', path: '/catalogos/estatus'),
  // Index 8 — Bases de Datos
  (
    icon: Icons.storage_outlined,
    label: 'Bases de Datos',
    path: '/catalogos/bases-datos',
  ),
  // Index 9 — Tipos
  (icon: Icons.category_outlined, label: 'Tipos', path: '/catalogos/tipos'),
  // Index 10 — Apariencia
  (
    icon: Icons.palette_outlined,
    label: 'Apariencia',
    path: '/settings/appearance',
  ),
];

/// Maps the current path to a sidebar index for highlight.
/// Returns -1 if no item should be highlighted (e.g. /success, /splash).
int _indexFromPath(String path) {
  if (path == '/dashboard') return 0;
  if (path == '/new-package') return 1;
  if (path == '/clone') return 2;
  if (path == '/history') return 3;
  if (path == '/templates') return 4;
  if (path.startsWith('/catalogos/servidores')) return 5;
  if (path.startsWith('/catalogos/servicios')) return 6;
  if (path.startsWith('/catalogos/estatus')) return 7;
  if (path.startsWith('/catalogos/bases-datos')) return 8;
  if (path.startsWith('/catalogos/tipos')) return 9;
  if (path == '/settings/appearance') return 10;
  return -1;
}

/// Persistent shell widget with a NavigationDrawer sidebar.
///
/// [AppShell] is used as the [ShellRoute] builder — it wraps every
/// operational route with a permanent left-side navigation drawer.
/// The sidebar is rendered directly in a [Row] (never as a modal Drawer).
class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexFromPath(location);

    return Scaffold(
      body: Row(
        children: [
          _AppSidebar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              context.go(_destinations[index].path);
            },
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// The permanent sidebar navigation.
class _AppSidebar extends StatelessWidget {
  const _AppSidebar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final void Function(int index) onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 220,
      child: Material(
        color: colorScheme.surface,
        child: Column(
          children: [
            // ── App header ─────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.inventory_2, color: colorScheme.primary, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'MGG Packify',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── Main group ────────────────────
            _SidebarItem(
              icon: _destinations[0].icon,
              label: _destinations[0].label,
              selected: selectedIndex == 0,
              onTap: () => onDestinationSelected(0),
            ),
            _SidebarItem(
              icon: _destinations[1].icon,
              label: _destinations[1].label,
              selected: selectedIndex == 1,
              onTap: () => onDestinationSelected(1),
            ),
            _SidebarItem(
              icon: _destinations[2].icon,
              label: _destinations[2].label,
              selected: selectedIndex == 2,
              onTap: () => onDestinationSelected(2),
            ),
            _SidebarItem(
              icon: _destinations[3].icon,
              label: _destinations[3].label,
              selected: selectedIndex == 3,
              onTap: () => onDestinationSelected(3),
            ),
            _SidebarItem(
              icon: _destinations[4].icon,
              label: _destinations[4].label,
              selected: selectedIndex == 4,
              onTap: () => onDestinationSelected(4),
            ),
            const Divider(height: 1),
            // ── Catálogos header ────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'CATÁLOGOS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            _SidebarItem(
              icon: _destinations[5].icon,
              label: _destinations[5].label,
              selected: selectedIndex == 5,
              onTap: () => onDestinationSelected(5),
            ),
            _SidebarItem(
              icon: _destinations[6].icon,
              label: _destinations[6].label,
              selected: selectedIndex == 6,
              onTap: () => onDestinationSelected(6),
            ),
            _SidebarItem(
              icon: _destinations[7].icon,
              label: _destinations[7].label,
              selected: selectedIndex == 7,
              onTap: () => onDestinationSelected(7),
            ),
            _SidebarItem(
              icon: _destinations[8].icon,
              label: _destinations[8].label,
              selected: selectedIndex == 8,
              onTap: () => onDestinationSelected(8),
            ),
            _SidebarItem(
              icon: _destinations[9].icon,
              label: _destinations[9].label,
              selected: selectedIndex == 9,
              onTap: () => onDestinationSelected(9),
            ),
            const Divider(height: 1),
            // ── Sistema ──────────────────────
            _SidebarItem(
              icon: _destinations[10].icon,
              label: _destinations[10].label,
              selected: selectedIndex == 10,
              onTap: () => onDestinationSelected(10),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single sidebar navigation item.
class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
      selected: selected,
      selectedTileColor: colorScheme.primaryContainer.withAlpha(128),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      onTap: onTap,
    );
  }
}
