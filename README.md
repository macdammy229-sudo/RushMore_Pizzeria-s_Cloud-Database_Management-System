# RushMore Pizzeria Cloud Database Management System

## Abstract
This capstone project presents a relational database design and reproducible synthetic-data workflow for a pizzeria cloud-migration proof of concept. The system targets Azure Database for PostgreSQL Flexible Server and demonstrates schema deployment, bulk data loading, and data-quality validation. It is a database-focused deliverable; it does not include a customer-facing application or Azure infrastructure-as-code.

## Objectives
- Model core pizzeria operations with a normalized PostgreSQL schema.
- Demonstrate deployment to Azure Database for PostgreSQL Flexible Server.
- Generate deterministic, masked demonstration data at a representative operational scale.
- Validate expected record counts, referential integrity, uniqueness, indexes, and example query plans.

## Data model
The schema comprises seven related entities:

- `stores` — branch locations
- `customers` — synthetic customer records
- `ingredients` — ingredient inventory
- `menu_items` — categorized items and prices
- `menu_item_ingredients` — normalized recipe associations
- `orders` — store- and customer-linked transactions
- `order_items` — menu-item line entries for each order

Primary keys, foreign keys, uniqueness rules, check constraints, and supporting indexes are defined in `database/rushmore_schema.sql`.

## Repository contents
- `database/rushmore_schema.sql` — PostgreSQL tables, constraints, and indexes
- `database/quality_checks.sql` — row-count, integrity, index, and query-plan checks
- `scripts/populate.py` — deterministic synthetic-data generator and bulk loader
- `scripts/seed_and_validate.sh` — first-run schema, seed, and validation workflow
- `.env.example` — Azure connection settings template
- `requirements.txt` — Python dependencies

## Dataset scope
A clean run generates the following dataset:

| Entity | Target records |
| --- | ---: |
| Stores | 4 |
| Menu items | 25 |
| Ingredients | 45 |
| Customers | 6,500 |
| Orders | 30,000 |
| Order items | 75,000 |

The seeder fixes its random seeds and reference date so that data generated from a clean database is repeatable. Customer details are synthetic and intended only for demonstration. The sample data is not production or real customer data.

## Deployment prerequisites
1. Create an Azure Database for PostgreSQL Flexible Server.
2. Configure server networking and firewall access for the machine that will run the workflow.
3. Create a dedicated, empty database for the demonstration. Do not use a production database.
4. Install Python and PostgreSQL client tools (`psql`). The workflow uses Bash and is suitable for Linux, macOS, WSL, or Git Bash.

## Configuration and installation
From the repository root, create a virtual environment and install the project dependencies:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Edit `.env` with the connection settings for the dedicated Azure database:

```env
AZURE_DB_HOST=your-server.postgres.database.azure.com
AZURE_DB_NAME=rushmore_db
AZURE_DB_USER=rushmoreadmin
AZURE_DB_PASSWORD=replace-with-your-password
AZURE_DB_PORT=5432
```

Keep `.env` private and do not commit real credentials. The workflow loads these settings and uses required SSL for the PostgreSQL connection.

## Reproducible workflow
Run the complete first-time workflow from the repository root:

```bash
./scripts/seed_and_validate.sh
```

The script checks its prerequisites and refuses to proceed if the database's `public` schema already contains relations. It then applies `database/rushmore_schema.sql`, runs `scripts/populate.py`, and executes `database/quality_checks.sql` with SQL errors configured to stop the workflow. It does not drop or overwrite existing objects.

This is a first-run workflow, not a reset or migration tool. If a run fails after schema creation, investigate the error and use a new empty database for a clean retry rather than rerunning against a partially populated database.

## Validation criteria
The SQL validation script checks that the seeded tables meet the target counts; customer email and phone values and store phone values are unique; order, line-item, and recipe references are valid; quantities and prices meet the checks performed by the script; and required indexes exist. It also reports diagnostic query results and runs example `EXPLAIN ANALYZE` queries for recent orders and store-level summaries.

The workflow raises an error and exits unsuccessfully if the expected record counts, integrity checks, or index checks fail. Query-plan output is informational and may vary with PostgreSQL version, database statistics, and data distribution.

## Manual execution
For users who need to run the steps separately, first configure the `.env` values in the shell, then execute:

```bash
psql "host=$AZURE_DB_HOST port=$AZURE_DB_PORT dbname=$AZURE_DB_NAME user=$AZURE_DB_USER password=$AZURE_DB_PASSWORD sslmode=require" -v ON_ERROR_STOP=1 -f database/rushmore_schema.sql
python scripts/populate.py
psql "host=$AZURE_DB_HOST port=$AZURE_DB_PORT dbname=$AZURE_DB_NAME user=$AZURE_DB_USER password=$AZURE_DB_PASSWORD sslmode=require" -v ON_ERROR_STOP=1 -f database/quality_checks.sql
```

Prefer the automated workflow for a complete run because it includes the empty-schema safety check.

## Scope and limitations
This repository provides database design, loading, and validation artifacts for an academic proof of concept. Azure server provisioning, network policy, access management, and evidence screenshots are performed separately in the Azure portal or pgAdmin. The seed data is synthetic, fixed in time, and not intended to represent live operational data.

## Deliverables
- Normalized PostgreSQL schema with constraints and indexes
- Deterministic Python data-generation and bulk-loading script
- SQL data-quality and query-plan checks
- Azure configuration template and reproducible setup instructions
