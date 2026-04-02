"""
Tests unitarios para la convención de naming de packages.

Verifica que PackageConfig.package_name genere el nombre correcto
para distintas combinaciones de ticket, ambiente e iteración.
"""

from __future__ import annotations

from portal_retail.core.package import PackageConfig

# ─────────────────────────────────────────────────────────────────────────────
# Fixtures
# ─────────────────────────────────────────────────────────────────────────────

def _make_config(ticket: str, ambiente: str, iteracion: str, hu_nombre: str = "") -> PackageConfig:
    """Helper para construir un PackageConfig mínimo."""
    return PackageConfig(
        ticket=ticket,
        hu_nombre=hu_nombre,
        ambiente=ambiente,
        iteracion=iteracion,
    )


# ─────────────────────────────────────────────────────────────────────────────
# Tests
# ─────────────────────────────────────────────────────────────────────────────

class TestPackageName:
    """Verifica el formato del nombre canónico del package."""

    def test_iteracion_sin_cero_se_rellena(self):
        """Iteración '1' → '01' en el nombre final."""
        config = _make_config("MX01-12345", "QA", "1")
        assert config.package_name == "MX01-12345-PortalRetail_QA-01"

    def test_iteracion_ya_tiene_cero(self):
        """Iteración '01' no cambia."""
        config = _make_config("MX01-12345", "QA", "01")
        assert config.package_name == "MX01-12345-PortalRetail_QA-01"

    def test_ambiente_prod(self):
        """Ambiente PROD → '_PROD-' en el nombre."""
        config = _make_config("MX01-12345", "PROD", "01")
        assert config.package_name == "MX01-12345-PortalRetail_PROD-01"

    def test_iteracion_dos_digitos(self):
        """Iteración '2' → '02'."""
        config = _make_config("MX01-12345", "QA", "2")
        assert config.package_name == "MX01-12345-PortalRetail_QA-02"

    def test_iteracion_10_no_rellena(self):
        """Iteración '10' permanece como '10' (2 dígitos nativos)."""
        config = _make_config("MX01-12345", "QA", "10")
        assert config.package_name == "MX01-12345-PortalRetail_QA-10"

    def test_hu_nombre_no_aparece_en_package_name(self):
        """hu_nombre es para el título del doc, NO para el nombre de carpeta."""
        config = _make_config("MX01-12345", "QA", "01", hu_nombre="Portal Retail HU01")
        # El hu_nombre NO debe aparecer en el package_name (igual que v1)
        assert "HU01" not in config.package_name
        assert config.package_name == "MX01-12345-PortalRetail_QA-01"

    def test_ticket_largo(self):
        """Ticket complejo con guiones."""
        config = _make_config("MX01-274906", "PROD", "03")
        assert config.package_name == "MX01-274906-PortalRetail_PROD-03"

    def test_formato_general(self):
        """Estructura: {ticket}-PortalRetail_{ambiente}-{iter_zfill(2)}."""
        config = _make_config("TICKET-999", "QA", "5")
        name = config.package_name
        assert name.startswith("TICKET-999-PortalRetail_")
        assert name.endswith("-05")
        assert "_QA-" in name
