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
- `docs/rushmore_erd.svg` — entity relationship diagram.
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

The ERD is included at `docs/rushmore_erd.svg`.

## Azure deployment steps
1. In the Azure portal, create an Azure Database for PostgreSQL Flexible Server.
2. Choose a region close to your users and set a pricing tier that supports your workload.
3. Set admin username/password and enable public access or private access based on your security model.
4. Create the database `rushmore_db`.
5. Copy the Azure server host, database name, username, and password into `.env`.

## Local configuration
1. Create a Python virtual environment.
2. Install project dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Copy `.env.example` to `.env` and fill in your Azure values:
   ```bash
   cp .env.example .env
   ```

Example `.env` values:
```env
AZURE_DB_HOST=rushmore-prod.postgres.database.azure.com
AZURE_DB_NAME=rushmore_db
AZURE_DB_USER=rushmoreadmin
AZURE_DB_PASSWORD=yourStrongPassword!
AZURE_DB_PORT=5432
```

## Schema deployment
Run the schema file against the Azure database:
```bash
psql "host=$AZURE_DB_HOST port=$AZURE_DB_PORT dbname=$AZURE_DB_NAME user=$AZURE_DB_USER password=$AZURE_DB_PASSWORD sslmode=require" -f database/rushmore_schema.sql
```

## Data population
Execute the population script:
```bash
python scripts/populate.py
```

The script:
- reads credentials from environment variables
- inserts stores, ingredients, menu items, customers, orders, and order items
- uses `psycopg2.extras.execute_batch` for efficient bulk inserts
- targets the scale described in the project brief

## Validation and optimization
Run the validation SQL after the data load:
```bash
psql "host=$AZURE_DB_HOST port=$AZURE_DB_PORT dbname=$AZURE_DB_NAME user=$AZURE_DB_USER password=$AZURE_DB_PASSWORD sslmode=require" -f database/quality_checks.sql
```

This validation covers:
- row counts
- duplicate detection
- orphaned foreign keys
- index presence
- example execution plans

## Notes
- Sensitive customer data is intentionally masked using Faker; this is a demo dataset only.
- Do not hardcode Azure credentials into source control.
- The Azure infrastructure and screenshots are expected to be captured in the Azure portal and pgAdmin according to the project rubric.

## Target workload
The final populated dataset is sized to represent a realistic fast-moving pizzeria operation:
- 4 stores
- 25 menu items
- 45 ingredients
- 6,500 customers
- 30,000 orders
- ~75,000 order items

## Deliverables summary
This repository includes the core deliverables required for the capstone:
- ERD as SVG
- schema SQL
- populate script
- data-quality validation SQL
- setup and deployment instructions

The Azure server instance, connection screenshots, and database row-count screenshots are to be captured from the Azure portal and pgAdmin during the live deployment step.
