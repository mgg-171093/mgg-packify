"""
Tests unitarios para SettingsManager.

Verifica load/save round-trip, archivo inexistente, y JSON corrupto.
Todos usan tmp_path para no contaminar el sistema de archivos real.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from portal_retail.config.settings import SettingsManager
from portal_retail.core.package import ServerConfig

# ─────────────────────────────────────────────────────────────────────────────
# Tests
# ─────────────────────────────────────────────────────────────────────────────

class TestSettingsLoad:

    def test_archivo_inexistente_devuelve_defaults(self, tmp_path: Path):
        """Si config.json no existe → devuelve ServerConfig vacío sin error."""
        config_path = tmp_path / "config.json"
        sm = SettingsManager(config_path=config_path)
        data = sm.load()

        qa = data.qa_servers
        assert qa.api == ""
        assert qa.bd == ""
        assert qa.blob == ""
        assert qa.liferay == ""

    def test_archivo_inexistente_no_lanza_excepcion(self, tmp_path: Path):
        """load() con archivo inexistente NO debe lanzar ninguna excepción."""
        sm = SettingsManager(config_path=tmp_path / "nope.json")
        try:
            sm.load()
        except Exception as exc:
            pytest.fail(f"load() lanzó inesperadamente: {exc}")

    def test_json_corrupto_devuelve_defaults(self, tmp_path: Path):
        """JSON inválido → load() silenciosamente usa defaults."""
        config_path = tmp_path / "config.json"
        config_path.write_text("{not valid json!!}", encoding="utf-8")

        sm = SettingsManager(config_path=config_path)
        data = sm.load()

        assert data.qa_servers.api == ""

    def test_json_corrupto_no_lanza_excepcion(self, tmp_path: Path):
        """JSON corrupto → NO lanza excepción."""
        config_path = tmp_path / "config.json"
        config_path.write_text("null", encoding="utf-8")  # válido pero inútil

        sm = SettingsManager(config_path=config_path)
        try:
            sm.load()
        except Exception as exc:
            pytest.fail(f"load() lanzó inesperadamente: {exc}")


class TestSettingsSave:

    def test_round_trip_qa_servers(self, tmp_path: Path):
        """save() QA → load() devuelve los mismos valores."""
        config_path = tmp_path / "config.json"
        sm = SettingsManager(config_path=config_path)
        sm.load()

        qa = ServerConfig(api="10.0.0.1", bd="10.0.0.2", blob="blob.core", liferay="10.0.0.4")
        sm.save(qa, "QA")

        # Nueva instancia para verificar persistencia real
        sm2 = SettingsManager(config_path=config_path)
        data2 = sm2.load()

        assert data2.qa_servers.api == "10.0.0.1"
        assert data2.qa_servers.bd == "10.0.0.2"
        assert data2.qa_servers.blob == "blob.core"
        assert data2.qa_servers.liferay == "10.0.0.4"

    def test_round_trip_prod_servers(self, tmp_path: Path):
        """save() PROD → load() devuelve los mismos valores."""
        config_path = tmp_path / "config.json"
        sm = SettingsManager(config_path=config_path)
        sm.load()

        prod = ServerConfig(api="192.168.1.1", bd="192.168.1.2", blob="", liferay="")
        sm.save(prod, "PROD")

        sm2 = SettingsManager(config_path=config_path)
        data2 = sm2.load()

        assert data2.prod_servers.api == "192.168.1.1"
        assert data2.prod_servers.bd == "192.168.1.2"

    def test_save_qa_no_sobreescribe_prod(self, tmp_path: Path):
        """Guardar QA no debe pisar los servidores PROD."""
        config_path = tmp_path / "config.json"
        sm = SettingsManager(config_path=config_path)
        sm.load()
        sm.save(ServerConfig(api="prod-api"), "PROD")
        sm.save(ServerConfig(api="qa-api"), "QA")

        sm2 = SettingsManager(config_path=config_path)
        data2 = sm2.load()

        assert data2.prod_servers.api == "prod-api"
        assert data2.qa_servers.api == "qa-api"

    def test_save_last_used(self, tmp_path: Path):
        """save_last_used persiste el dict y load lo devuelve."""
        config_path = tmp_path / "config.json"
        sm = SettingsManager(config_path=config_path)
        sm.load()
        sm.save_last_used({"ticket": "MX01-999", "ambiente": "PROD", "iteracion": "03"})

        sm2 = SettingsManager(config_path=config_path)
        sm2.load()
        lu = sm2.get_last_used()

        assert lu["ticket"] == "MX01-999"
        assert lu["ambiente"] == "PROD"
        assert lu["iteracion"] == "03"

    def test_crea_directorio_si_no_existe(self, tmp_path: Path):
        """save() crea el directorio padre si no existe."""
        config_path = tmp_path / "nested" / "deep" / "config.json"
        sm = SettingsManager(config_path=config_path)
        sm.load()
        sm.save(ServerConfig(api="x"), "QA")

        assert config_path.exists()
