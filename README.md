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
- `database/quality_checks.sql` — validation and performance checks.
- `scripts/populate.py` — synthetic data generation and bulk load script.
- `.env.example` — Azure connection variables template.
- `requirements.txt` — Python dependencies.
- `README.md` — setup, deployment, and validation guide.

## Schema overview
The schema includes the following core entities:
- `stores`
- `customers`
- `ingredients`
- `menu_items`
- `orders`
- `order_items`
- `menu_item_ingredients` (normalized recipe association)

## Azure deployment steps
1. In the Azure portal, create an Azure Database for PostgreSQL Flexible Server.
2. Choose a region close to your users and set a pricing tier that supports your workload.
3. Set admin username/password and configure network access according to your security model.
4. Create the database `rushmore_db`.
5. Copy `.env.example` to `.env` and set your server host, database name, username, and password.

## Local configuration
Create and activate a Python virtual environment, install dependencies, and configure the database environment:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

On Windows PowerShell, activate with `.venv\\Scripts\\Activate.ps1` instead of the `source` command.

Edit `.env` with your Azure PostgreSQL connection values. The Python population script loads this file automatically. For the `psql` commands below, export its values into your shell first:

```bash
set -a
. ./.env
set +a
```

Do not commit `.env` or put real credentials in source control.

## Schema deployment
Run the schema file against an empty `rushmore_db` database:

```bash
psql "host=$AZURE_DB_HOST port=$AZURE_DB_PORT dbname=$AZURE_DB_NAME user=$AZURE_DB_USER password=$AZURE_DB_PASSWORD sslmode=require" -f database/rushmore_schema.sql
```

## Data population
Run the population script once against the newly created schema. It generates 4 stores, 25 menu items, 45 ingredients, 6,500 customers, 30,000 orders, and exactly 75,000 order items. The data generator uses Faker for masked customer names and `psycopg2.extras.execute_batch` for efficient inserts.

```bash
python scripts/populate.py
```

The script reads Azure connection settings from `.env` (or from exported environment variables), and requires an empty schema to avoid duplicate rows.

## Validation and optimization
Run the validation SQL after the data load:

```bash
psql "host=$AZURE_DB_HOST port=$AZURE_DB_PORT dbname=$AZURE_DB_NAME user=$AZURE_DB_USER password=$AZURE_DB_PASSWORD sslmode=require" -f database/quality_checks.sql
```

This validation covers row counts, duplicate detection, orphaned foreign keys, index presence, and example execution plans.

## Notes
- Synthetic customer data is generated for demonstration only; it is not real customer data.
- Do not hardcode Azure credentials into source control.
- The Azure infrastructure and screenshots are expected to be captured in the Azure portal and pgAdmin according to the project rubric.

## Target workload
- 4 stores
- 25 menu items
- 45 ingredients
- 6,500 customers
- 30,000 orders
- 75,000 order items

## Deliverables summary
This repository includes the schema SQL, synthetic data population script, data-quality validation SQL, and setup and deployment instructions.

The Azure server instance, connection screenshots, and database row-count screenshots are to be captured from the Azure portal and pgAdmin during the live deployment step.
