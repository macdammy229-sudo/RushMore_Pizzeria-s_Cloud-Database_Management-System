# RushMore Pizzeria Cloud Database Management System

This repository contains the database design, Azure PostgreSQL deployment artifacts, and synthetic-data generation pipeline for RushMore Pizzeria's cloud migration proof-of-concept.

## Project goals
- Design a normalized relational schema for pizzeria operations.
- Deploy the database to Azure Database for PostgreSQL Flexible Server.
- Load an empty schema into `rushmore_db`.
- Generate realistic masked data with Python + Faker.
- Validate row counts, referential integrity, and performance.

## Repository structure
- `database/rushmore_schema.sql` — normalized PostgreSQL schema.
- `database/quality_checks.sql` — row-count, integrity, index, and query-plan validations.
- `scripts/populate.py` — deterministic synthetic data generator and bulk loader.
- `scripts/seed_and_validate.sh` — first-run workflow for schema creation, seeding, and validation.
- `.env.example` — Azure connection settings template.
- `requirements.txt` — Python dependencies.

## Schema overview
The schema models stores, customers, ingredients, menu items, orders, order items, and the normalized `menu_item_ingredients` recipe association.

## Azure setup
1. Create an Azure Database for PostgreSQL Flexible Server and configure network access for your client.
2. Create a dedicated, empty database for this demo run. The workflow intentionally refuses to run if the `public` schema already contains relations.
3. Copy `.env.example` to `.env` and set your host, database name, user, and password. Never commit `.env` or use production credentials for this demo.

## Reproducible seed and validation
From the repository root, create a Python environment, install dependencies, configure `.env`, then invoke the workflow:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your dedicated empty test database settings.
./scripts/seed_and_validate.sh
```

On Windows, run these Bash commands in WSL or Git Bash. `psql` (PostgreSQL client tools) must be installed and available on `PATH`. The script reads `.env`, requires `psql` and Python, checks the target's `public` schema is empty, applies `database/rushmore_schema.sql`, runs `scripts/populate.py`, and then executes `database/quality_checks.sql` with `ON_ERROR_STOP` enabled. It never drops existing objects. If the run fails after creating the schema, use a fresh empty database for a clean retry.

The seeder fixes its random and Faker seeds and uses fixed date bounds, so every clean run produces repeatable synthetic values. It inserts 4 stores, 25 menu items, 45 ingredients, 6,500 customers, 30,000 orders, and exactly 75,000 order items. Validation raises an error if expected counts, uniqueness/integrity checks, or required indexes fail; it also prints row counts, diagnostic queries, and `EXPLAIN ANALYZE` plans.

The workflow is first-run-only by design. Do not point it at a populated or production database.

## What the validation covers
- Expected row counts for the seeded entities.
- Duplicate customer emails/phones and store phone numbers.
- Orphaned customer/store/order/menu-item/ingredient references.
- Invalid order item quantities/prices and recipe quantities.
- Presence of the schema's supporting indexes.
- Example query plans for recent orders and store/date summaries.

## Notes
- The generated customer data is synthetic and for demonstration only.
- The Azure server, connection, and row-count screenshots required by the capstone rubric must be captured separately in the Azure portal or pgAdmin.
