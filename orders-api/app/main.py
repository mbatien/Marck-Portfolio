"""Orders API: a small REST service that runs on ECS Fargate behind the ALB."""

import logging
import os
from contextlib import asynccontextmanager
from decimal import Decimal
from enum import StrEnum

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from app.db import create_pool

logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))
log = logging.getLogger("orders-api")

VERSION = os.environ.get("APP_VERSION", "dev")


class OrderStatus(StrEnum):
    pending = "pending"
    paid = "paid"
    shipped = "shipped"
    cancelled = "cancelled"


class OrderIn(BaseModel):
    customer: str = Field(min_length=1, max_length=100)
    item: str = Field(min_length=1, max_length=100)
    quantity: int = Field(gt=0, le=1000)
    unit_price: Decimal = Field(ge=0, max_digits=10, decimal_places=2)


class StatusUpdate(BaseModel):
    status: OrderStatus


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.pool = create_pool()
    log.info("connected to database, version=%s", VERSION)
    yield
    app.state.pool.close()


app = FastAPI(title="Orders API", version=VERSION, lifespan=lifespan)


def pool(request: Request):
    return request.app.state.pool


@app.get("/")
def root():
    return {"service": "orders-api", "version": VERSION, "env": os.environ.get("APP_ENV", "local")}


@app.get("/health")
def health():
    """Liveness for the ALB health check. Deliberately does not touch the database,
    so a database blip doesn't make the ALB pull every task out of service."""
    # TEMP: rollback test. Fails only when deployed (APP_ENV set), so unit tests pass.
    # Revert this after the rollback test.
    if os.environ.get("APP_ENV", "local") != "local":
        return JSONResponse(status_code=503, content={"status": "unhealthy"})
    return {"status": "ok"}


@app.get("/ready")
def ready(request: Request):
    """Readiness: can this task actually reach the database?"""
    try:
        with pool(request).connection() as conn:
            conn.execute("SELECT 1")
    except Exception:
        log.exception("readiness check failed")
        return JSONResponse(status_code=503, content={"status": "unavailable"})
    return {"status": "ready"}


@app.get("/orders")
def list_orders(request: Request, limit: int = 50):
    limit = max(1, min(limit, 200))
    with pool(request).connection() as conn:
        rows = conn.execute(
            "SELECT * FROM orders ORDER BY id DESC LIMIT %s", (limit,)
        ).fetchall()
    return [_out(r) for r in rows]


@app.post("/orders", status_code=status.HTTP_201_CREATED)
def create_order(order: OrderIn, request: Request):
    with pool(request).connection() as conn:
        row = conn.execute(
            "INSERT INTO orders (customer, item, quantity, unit_price) "
            "VALUES (%s, %s, %s, %s) RETURNING *",
            (order.customer, order.item, order.quantity, order.unit_price),
        ).fetchone()
    return _out(row)


@app.get("/orders/{order_id}")
def get_order(order_id: int, request: Request):
    with pool(request).connection() as conn:
        row = conn.execute("SELECT * FROM orders WHERE id = %s", (order_id,)).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="order not found")
    return _out(row)


@app.patch("/orders/{order_id}")
def update_status(order_id: int, body: StatusUpdate, request: Request):
    with pool(request).connection() as conn:
        row = conn.execute(
            "UPDATE orders SET status = %s WHERE id = %s RETURNING *",
            (body.status.value, order_id),
        ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="order not found")
    return _out(row)


@app.delete("/orders/{order_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_order(order_id: int, request: Request):
    with pool(request).connection() as conn:
        deleted = conn.execute("DELETE FROM orders WHERE id = %s", (order_id,)).rowcount
    if deleted == 0:
        raise HTTPException(status_code=404, detail="order not found")


def _out(row: dict) -> dict:
    return {
        "id": row["id"],
        "customer": row["customer"],
        "item": row["item"],
        "quantity": row["quantity"],
        "unit_price": str(row["unit_price"]),
        "total": str(row["unit_price"] * row["quantity"]),
        "status": row["status"],
        "created_at": row["created_at"].isoformat(),
    }
