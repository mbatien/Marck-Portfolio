"""API tests. They run against a real PostgreSQL (a service container in CI,
docker compose locally), so the SQL is tested too, not just the routes."""

import os

import pytest
from fastapi.testclient import TestClient

os.environ.setdefault("DB_HOST", "localhost")
os.environ.setdefault("DB_PORT", "5432")
os.environ.setdefault("DB_NAME", "orders")
os.environ.setdefault("DB_USERNAME", "orders")
os.environ.setdefault("DB_PASSWORD", "orders")
os.environ.setdefault("DB_SSLMODE", "disable")

from app.main import app  # noqa: E402


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        with app.state.pool.connection() as conn:
            conn.execute("TRUNCATE orders RESTART IDENTITY")
        yield c


ORDER = {"customer": "Ada", "item": "keyboard", "quantity": 2, "unit_price": "49.99"}


def test_health_does_not_need_the_database(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_ready_checks_the_database(client):
    r = client.get("/ready")
    assert r.status_code == 200
    assert r.json() == {"status": "ready"}


def test_root_reports_version(client):
    assert client.get("/").json()["service"] == "orders-api"


def test_create_and_get_order(client):
    r = client.post("/orders", json=ORDER)
    assert r.status_code == 201
    body = r.json()
    assert body["status"] == "pending"
    assert body["total"] == "99.98"

    r = client.get(f"/orders/{body['id']}")
    assert r.status_code == 200
    assert r.json()["customer"] == "Ada"


def test_list_orders_newest_first(client):
    client.post("/orders", json={**ORDER, "customer": "Grace"})
    orders = client.get("/orders").json()
    assert orders[0]["customer"] == "Grace"
    assert len(orders) >= 2


def test_update_status(client):
    order_id = client.post("/orders", json=ORDER).json()["id"]
    r = client.patch(f"/orders/{order_id}", json={"status": "shipped"})
    assert r.status_code == 200
    assert r.json()["status"] == "shipped"


def test_invalid_status_rejected(client):
    order_id = client.post("/orders", json=ORDER).json()["id"]
    r = client.patch(f"/orders/{order_id}", json={"status": "lost"})
    assert r.status_code == 422


def test_delete_order(client):
    order_id = client.post("/orders", json=ORDER).json()["id"]
    assert client.delete(f"/orders/{order_id}").status_code == 204
    assert client.get(f"/orders/{order_id}").status_code == 404


@pytest.mark.parametrize(
    "bad",
    [
        {**ORDER, "quantity": 0},
        {**ORDER, "unit_price": "-1"},
        {**ORDER, "customer": ""},
        {"item": "no customer", "quantity": 1, "unit_price": "1"},
    ],
)
def test_validation(client, bad):
    assert client.post("/orders", json=bad).status_code == 422


def test_missing_order_is_404(client):
    assert client.get("/orders/999999").status_code == 404
