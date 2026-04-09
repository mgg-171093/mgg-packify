"""
Tests para GET /health
"""

from __future__ import annotations

from fastapi.testclient import TestClient


def test_health_returns_200(client: TestClient) -> None:
    """GET /health debe retornar HTTP 200."""
    response = client.get("/health")
    assert response.status_code == 200


def test_health_body(client: TestClient) -> None:
    """GET /health debe retornar {status: ok, version: 3.5.0}."""
    response = client.get("/health")
    body = response.json()
    assert body["status"] == "ok"
    assert body["version"] == "3.5.0"
