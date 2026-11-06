# RushMore Pizzeria Cloud Database Management System

This repository contains the database design, Azure PostgreSQL deployment artifacts, and synthetic-data generation pipeline for RushMore Pizzeria's cloud migration proof of concept.

## Project goals
- Design a normalized PostgreSQL schema for pizzeria operations.
- Deploy the database to Azure Database for PostgreSQL Flexible Server.
- Load an empty schema into a dedicated `rushmore_db` database.
- Generate realistic masked data with Python + Faker.
- Validate row counts, referential integrity, indexes, and performance.

## What this project models
The schema captures the core business flow of a pizza operation:
- `stores` for branch locations
- `customers` for order history and contact data
- `ingredients` for inventory and recipe inputs
- `menu_items` for catalog items and pricing
- `orders` for customer transactions
- `order_items` for line items on each order
- `menu_item_ingredients` for normalized ingredient composition per menu item

## Repository layout
- `database/rushmore_schema.sql` — PostgreSQL schema definition and index setup
- `database/quality_checks.sql` — row-count, integrity, and performance validation checks
- `scripts/populate.py` — deterministic synthetic data generator for the pizzeria dataset
- `scripts/seed_and_validate.sh` — end-to-end workflow for schema creation, seeding, and validation
- `.env.example` — Azure connection template
- `requirements.txt` — Python dependencies for the loader

## Azure setup
1. Create an Azure Database for PostgreSQL Flexible Server.
2. Configure firewall/network access so your local machine or dev environment can reach it.
3. Create a dedicated, empty database for this demo workload.
4. Copy `.env.example` to `.env` and fill in your Azure connection values.

Important:
- Do not commit your `.env` file.
- Use a dedicated test database rather than a production database.
- The workflow is designed to fail fast on a non-empty `public` schema to avoid accidental overwrite.

## Environment configuration
Create and activate a Python virtual environment, then install dependencies:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Edit `.env` with your database settings:

```env
AZURE_DB_HOST=your-server.postgres.database.azure.com
AZURE_DB_NAME=rushmore_db
AZURE_DB_USER=rushmoreadmin
AZURE_DB_PASSWORD=yourStrongPassword!
AZURE_DB_PORT=5432
```

If you are using `psql` from the shell, export the values before running commands:

```bash
set -a
source ./.env
set +a
```

## Reproducible seed and validation workflow
This project includes a first-run workflow that is safe for a clean database:

```bash
./scripts/seed_and_validate.sh
```

The script performs the following in order:
1. Verifies that the target database is empty enough to safely initialize.
2. Runs `database/rushmore_schema.sql`.
3. Executes `scripts/populate.py` to generate synthetic data.
4. Runs `database/quality_checks.sql` to verify integrity and performance assumptions.

This workflow is intentionally first-run-only. It refuses to continue if the `public` schema is not empty.

## Data generation details
The synthetic seed is fixed and deterministic for clean runs:
- 4 stores
- 25 menu items
- 45 ingredients
- 6,500 customers
- 30,000 orders
- 75,000 order items

The generator uses Faker for masked customer data and `psycopg2.extras.execute_batch` for efficient bulk inserts. It also sets fixed random seeds so repeated runs against a clean database are reproducible.

## Validation checks
`database/quality_checks.sql` validates:
- expected row counts for each table
- duplicate customer email/phone values and duplicate store phone numbers
- orphaned orders, order items, and recipe associations
- invalid quantities or negative values
- required supporting indexes
- example `EXPLAIN ANALYZE` queries for recent-order and store-summary reporting

If any check fails, the script exits with a non-zero status and raises an error.

## Local run example
For a manual run without the helper script, use the following sequence against a fresh database:

```bash
psql "host=$AZURE_DB_HOST port=$AZURE_DB_PORT dbname=$AZURE_DB_NAME user=$AZURE_DB_USER password=$AZURE_DB_PASSWORD sslmode=require" -f database/rushmore_schema.sql
python scripts/populate.py
psql "host=$AZURE_DB_HOST port=$AZURE_DB_PORT dbname=$AZURE_DB_NAME user=$AZURE_DB_USER password=$AZURE_DB_PASSWORD sslmode=require" -f database/quality_checks.sql
```

## Notes
- Synthetic customer data is for demonstration only and is intentionally masked.
- The Azure database connection and row-count screenshots required by the capstone rubric should be captured separately in the Azure portal and pgAdmin.
- Do not rerun this workflow on a populated or production database.

## Deliverables summary
This repository includes the schema SQL, synthetic data population script, quality-validation SQL, and setup instructions needed for the cloud database proof of concept.
