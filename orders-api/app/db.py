"""Database access: a small connection pool and the orders table."""

import os

from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool


def conninfo() -> str:
    """Build the connection string from the variables ECS injects.

    DB_HOST, DB_PORT and DB_NAME come from the task definition's `environment`;
    DB_USERNAME and DB_PASSWORD come from Secrets Manager via its `secrets` block.
    RDS for PostgreSQL 15+ requires TLS by default, hence sslmode=require.
    """
    return (
        f"host={os.environ['DB_HOST']} "
        f"port={os.environ.get('DB_PORT', '5432')} "
        f"dbname={os.environ['DB_NAME']} "
        f"user={os.environ['DB_USERNAME']} "
        f"password={os.environ['DB_PASSWORD']} "
        f"sslmode={os.environ.get('DB_SSLMODE', 'require')} "
        "connect_timeout=5"
    )


SCHEMA = """
CREATE TABLE IF NOT EXISTS orders (
    id          BIGSERIAL PRIMARY KEY,
    customer    TEXT           NOT NULL,
    item        TEXT           NOT NULL,
    quantity    INTEGER        NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    status      TEXT           NOT NULL DEFAULT 'pending',
    created_at  TIMESTAMPTZ    NOT NULL DEFAULT now()
);
"""


def create_pool() -> ConnectionPool:
    pool = ConnectionPool(
        conninfo(),
        min_size=1,
        max_size=int(os.environ.get("DB_POOL_SIZE", "5")),
        kwargs={"row_factory": dict_row},
        open=False,
    )
    pool.open(wait=True, timeout=30)
    with pool.connection() as conn:
        conn.execute(SCHEMA)
    return pool
