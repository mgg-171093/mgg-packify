"""
Tests para los schemas Pydantic de packages.
"""

from __future__ import annotations

import pytest
from pydantic import ValidationError

from mgg_packgen_api.schemas.package import ConfigItemIn


class TestConfigItemIn:
    # ── task 1.4: imagen_path defaults to None ──────────────────────────────

    def test_imagen_path_defaults_to_none(self) -> None:
        """ConfigItemIn created without imagen_path has imagen_path = None."""
        item = ConfigItemIn(clave="k", valor="v")
        assert item.imagen_path is None

    # ── TRIANGULATE: accepts non-null imagen_path ────────────────────────────

    def test_imagen_path_accepts_string_value(self) -> None:
        """ConfigItemIn accepts a non-null string for imagen_path."""
        item = ConfigItemIn(clave="env", valor="QA", imagen_path="/home/user/img.png")
        assert item.imagen_path == "/home/user/img.png"

    # ── TRIANGULATE: clave and valor are still required ──────────────────────

    def test_clave_and_valor_are_required(self) -> None:
        """ConfigItemIn still requires clave and valor."""
        with pytest.raises(ValidationError):
            ConfigItemIn(imagen_path="/img.png")  # type: ignore[call-arg]

    # ── TRIANGULATE: imagen_path can be explicitly set to None ───────────────

    def test_imagen_path_can_be_set_to_none_explicitly(self) -> None:
        """Passing imagen_path=None explicitly is valid and results in None."""
        item = ConfigItemIn(clave="host", valor="localhost", imagen_path=None)
        assert item.imagen_path is None
