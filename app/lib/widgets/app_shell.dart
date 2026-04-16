import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../core/theme/theme_extensions.dart';
import '../core/server_manager.dart';
import '../providers/server_status_provider.dart';

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
  // Index 5 — Proyectos
  (
    icon: Icons.folder_special_outlined,
    label: 'Proyectos',
    path: '/catalogos/proyectos',
  ),
  // Index 6 — Servidores
  (
    icon: Icons.dns_outlined,
    label: 'Servidores',
    path: '/catalogos/servidores',
  ),
  // Index 7 — Servicios API
  (
    icon: Icons.miscellaneous_services_outlined,
    label: 'Servicios API',
    path: '/catalogos/servicios',
  ),
  // Index 8 — Estatus
  (icon: Icons.list_alt_outlined, label: 'Estatus', path: '/catalogos/estatus'),
  // Index 9 — Bases de Datos
  (
    icon: Icons.storage_outlined,
    label: 'Bases de Datos',
    path: '/catalogos/bases-datos',
  ),
  // Index 10 — Tipos
  (icon: Icons.category_outlined, label: 'Tipos', path: '/catalogos/tipos'),
  // Index 11 — Texto Docs
  (
    icon: Icons.edit_note_outlined,
    label: 'Texto Docs',
    path: '/catalogos/doc-templates',
  ),
  // Index 12 — Apariencia
  (
    icon: Icons.palette_outlined,
    label: 'Apariencia',
    path: '/settings/appearance',
  ),
  // Index 13 — Logs
  (icon: Icons.article_outlined, label: 'Logs', path: '/logs'),
  // Index 14 — Acerca de
  (icon: Icons.info_outline, label: 'Acerca de', path: '/about'),
];

/// Maps the current path to a sidebar index for highlight.
/// Returns -1 if no item should be highlighted (e.g. /success, /splash).
int _indexFromPath(String path) {
  if (path == '/dashboard') return 0;
  if (path == '/new-package') return 1;
  if (path == '/clone') return 2;
  if (path == '/history') return 3;
  if (path == '/templates') return 4;
  if (path.startsWith('/catalogos/proyectos')) return 5;
  if (path.startsWith('/catalogos/servidores')) return 6;
  if (path.startsWith('/catalogos/servicios')) return 7;
  if (path.startsWith('/catalogos/estatus')) return 8;
  if (path.startsWith('/catalogos/bases-datos')) return 9;
  if (path.startsWith('/catalogos/tipos')) return 10;
  if (path.startsWith('/catalogos/doc-templates')) return 11;
  if (path == '/settings/appearance') return 12;
  if (path == '/logs') return 13;
  if (path == '/about') return 14;
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
class _AppSidebar extends ConsumerWidget {
  const _AppSidebar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final void Function(int index) onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final serverStatus = ref.watch(serverStatusProvider);
    final isHealthy = serverStatus == ServerStatus.ready;

    Widget navItem(int index) {
      return _SidebarItem(
        itemIndex: index,
        icon: _destinations[index].icon,
        label: _destinations[index].label,
        selected: selectedIndex == index,
        onTap: () => onDestinationSelected(index),
      );
    }

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
                  Expanded(
                    child: Image.asset(
                      'assets/branding/logo-sidebar.png',
                      width: 180,
                      height: 60,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.inventory_2,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  // Image.asset(
                  //   'assets/branding/logo-sidebar.png',
                  //   width: 80,
                  //   height: 40,
                  //   errorBuilder: (_, __, ___) => Icon(
                  //     Icons.inventory_2,
                  //     color: colorScheme.primary,
                  //     size: 24,
                  //   ),
                  // ),
                  const SizedBox(width: 10),
                  // Expanded(
                  //   child: Text(
                  //     'MGG Packify',
                  //     style: theme.textTheme.titleMedium?.copyWith(
                  //       fontWeight: FontWeight.w700,
                  //       color: colorScheme.primary,
                  //     ),
                  //   ),
                  // ),
                  // ── Health indicator dot ──────
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isHealthy ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            // ── Restart button when crashed ───
            if (serverStatus == ServerStatus.crashed) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reiniciar API'),
                  onPressed: () {
                    ref.read(serverManagerProvider).restart(ref);
                  },
                ),
              ),
            ],
            const Divider(height: 1),
            // ── Main group ────────────────────
            navItem(0),
            navItem(1),
            navItem(2),
            navItem(3),
            navItem(4),
            const Divider(height: 1),
            // ── Catálogos header ────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'CATÁLOGOS',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            navItem(5),
            navItem(6),
            navItem(7),
            navItem(8),
            navItem(9),
            navItem(10),
            navItem(11),
            const Divider(height: 1),
            // ── Sistema ──────────────────────
            navItem(12),
            const Divider(height: 1),
            // ── Sistema / herramientas ────────
            navItem(13),
            navItem(14),
            // ── Spacer + version footer ───────
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'v$kAppVersion',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single sidebar navigation item.
class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.itemIndex,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int itemIndex;

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effects =
        theme.extension<PremiumEffects>() ??
        const PremiumEffects(
          hoverDuration: Duration(milliseconds: 150),
          focusRingWidth: 2,
          actionCursor: SystemMouseCursors.click,
          standardCurve: Curves.easeInOut,
        );
    final surfaceTokens =
        theme.extension<SurfaceTokens>() ??
        SurfaceTokens.fromColorScheme(colorScheme);

    final tileColor = widget.selected
        ? surfaceTokens.sidebarActive
        : _isHovered
        ? colorScheme.surfaceContainerHighest.withAlpha(153)
        : Colors.transparent;

    final titleStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
      color: widget.selected ? colorScheme.primary : colorScheme.onSurface,
    );

    final marker = widget.selected
        ? Container(
            key: Key('sidebar-active-marker-${widget.itemIndex}'),
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          )
        : const SizedBox(width: 4);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        key: Key('sidebar-item-${widget.itemIndex}-inkwell'),
        onTap: widget.onTap,
        mouseCursor: effects.actionCursor,
        onHover: (hovering) {
          if (_isHovered != hovering) {
            setState(() => _isHovered = hovering);
          }
        },
        onFocusChange: (focused) {
          if (_isFocused != focused) {
            setState(() => _isFocused = focused);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          key: Key('sidebar-item-${widget.itemIndex}-container'),
          duration: effects.hoverDuration,
          curve: effects.standardCurve,
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(10),
            border: _isFocused
                ? Border.all(
                    color: colorScheme.primary,
                    width: effects.focusRingWidth,
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              marker,
              const SizedBox(width: 10),
              Icon(
                widget.icon,
                color: widget.selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
