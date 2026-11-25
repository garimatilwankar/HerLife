"""Adds the onboarding columns to the profiles table if they are missing."""
from sqlalchemy import inspect, text

from app.database import engine

COLUMNS = {
    "pcos_status": "VARCHAR(20)",
    "last_period_date": "DATE",
    "cycle_length": "INTEGER",
    "period_length": "INTEGER",
    "main_concerns": "VARCHAR(500)",
    "onboarding_completed": "BOOLEAN NOT NULL DEFAULT {false}",
    "tutorial_seen": "BOOLEAN NOT NULL DEFAULT {false}",
}

is_sqlite = engine.dialect.name == "sqlite"
false_value = "0" if is_sqlite else "FALSE"

existing = {c["name"] for c in inspect(engine).get_columns("profiles")}

with engine.begin() as conn:
    for name, ddl in COLUMNS.items():
        if name in existing:
            print(f"already there: {name}")
            continue
        conn.execute(
            text(f"ALTER TABLE profiles ADD COLUMN {name} " + ddl.format(false=false_value))
        )
        print(f"added: {name}")