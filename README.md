<div align="center">
  <h1>
    <span style="color:#FF7A18;">RushMore</span>
    <span style="color:#2F80ED;">Pizzeria</span>
    <span style="color:#00B894;">Cloud Database Management System</span>
  </h1>
  <p>
    <strong><span style="color:#6C63FF;">Designing RushMore Pizzeria's Cloud Database Management System</span></strong>
  </p>
</div>

<p>
  <span style="color:#00A676;">✅</span> <strong>Project Objective:</strong> Design and deploy a cloud-ready PostgreSQL database for a modern pizzeria operation, including schema design, synthetic data generation, validation, and Azure-based deployment.
</p>

<p>
  <span style="color:#FFB000;">⚙️</span> <strong>Core Focus:</strong> Normalized relational modeling, production-style data pipeline orchestration, performance checks, and migration readiness for a real-world business scenario.
</p>

---

## 📌 Project Overview

This repository contains the database design, deployment assets, and synthetic-data pipeline for RushMore Pizzeria's cloud migration proof-of-concept. The solution models pizzeria operations as a normalized relational system and supports deployment to Azure Database for PostgreSQL Flexible Server.

The project is designed to demonstrate a realistic end-to-end process:
- schema development
- database provisioning
- environment configuration
- sample data generation
- validation and optimization checks
- cloud migration readiness

---

## 🎯 Business Goals

- Create a normalized relational schema for pizzeria operations
- Support multi-store ordering and inventory tracking
- Manage customer activity, menu data, and order fulfillment
- Generate realistic masked data for testing and demonstration
- Validate referential integrity and workload performance
- Prepare for deployment on Azure PostgreSQL infrastructure

---

## 🧱 Key Database Components

<table>
  <tr>
    <td bgcolor="#1F2937"><font color="#FFFFFF"><strong>Component</strong></font></td>
    <td bgcolor="#1F2937"><font color="#FFFFFF"><strong>Description</strong></font></td>
  </tr>
  <tr>
    <td bgcolor="#E8F5E9"><font color="#0B3B2E">Schema</font></td>
    <td>Normalized PostgreSQL schema for stores, customers, menu, inventory, and orders.</td>
  </tr>
  <tr>
    <td bgcolor="#EAF2FF"><font color="#1E3A8A">Data Pipeline</font></td>
    <td>Python script for generating realistic synthetic records and loading them into the database.</td>
  </tr>
  <tr>
    <td bgcolor="#FFF4E5"><font color="#92400E">Validation</font></td>
    <td>SQL quality checks for row counts, duplicates, orphaned records, and performance tuning checks.</td>
  </tr>
  <tr>
    <td bgcolor="#FDECEC"><font color="#991B1B">Cloud Deployment</font></td>
    <td>Azure PostgreSQL configuration and deployment steps tailored for the project workflow.</td>
  </tr>
</table>

---

## 📁 Repository Structure

- `database/rushmore_schema.sql` — normalized PostgreSQL schema for the pizzeria domain
- `database/quality_checks.sql` — validation and performance checks
- `scripts/populate.py` — synthetic-data generation and bulk load script
- `docs/rushmore_erd.svg` — entity relationship diagram
- `.env.example` — sample Azure database connection variables
- `requirements.txt` — Python dependencies for the data generator
- `README.md` — setup, deployment, and validation documentation

---

## 🧩 Schema Overview

The schema includes the following major entities:

- `stores`
- `customers`
- `ingredients`
- `menu_items`
- `orders`
- `order_items`
- `menu_item_ingredients`

This structure reflects a normalized design that separates master data from transactional records while maintaining clear relationships between menu items, ingredients, orders, and stores.

---

## ☁️ Azure Deployment Workflow

1. Create an Azure Database for PostgreSQL Flexible Server.
2. Select a region close to the intended user base and choose an appropriate pricing tier.
3. Configure admin credentials and access settings.
4. Create the database named `rushmore_db`.
5. Copy the server host, database name, username, and password into your local `.env` file.

---

## 🛠️ Local Configuration

1. Create a Python virtual environment.
2. Install project dependencies:

```bash
pip install -r requirements.txt
```

3. Copy the example environment file and populate it with your Azure connection details:

```bash
cp .env.example .env
```

Example values:

```env
AZURE_DB_HOST=rushmore-prod.postgres.database.azure.com
AZURE_DB_NAME=rushmore_db
AZURE_DB_USER=rushmoreadmin
AZURE_DB_PASSWORD=yourStrongPassword!
AZURE_DB_PORT=5432
```

---

## 🚀 Schema Deployment

Run the schema SQL file against the Azure PostgreSQL instance:

```bash
psql "host=$AZURE_DB_HOST port=$AZURE_DB_PORT dbname=$AZURE_DB_NAME user=$AZURE_DB_USER password=$AZURE_DB_PASSWORD sslmode=require" -f database/rushmore_schema.sql
```

---

## 🧪 Data Population

Execute the population script:

```bash
python scripts/populate.py
```

The script is responsible for:
- reading configuration from environment variables
- building realistic data for stores, ingredients, menu items, customers, orders, and order items
- using Python and Faker to generate masked sample data
- loading records efficiently with bulk insert utilities

---

## ✅ Validation and Optimization

After the data load, run the quality checks:

```bash
psql "host=$AZURE_DB_HOST port=$AZURE_DB_PORT dbname=$AZURE_DB_NAME user=$AZURE_DB_USER password=$AZURE_DB_PASSWORD sslmode=require" -f database/quality_checks.sql
```

The validation process covers:
- row count verification
- duplicate detection
- orphaned foreign keys
- presence of performance-critical indexes
- example execution plan review

---

## 📊 Target Workload

The final populated dataset is intended to represent a realistic fast-moving pizzeria operation:

- 4 stores
- 25 menu items
- 45 ingredients
- 6,500 customers
- 30,000 orders
- ~75,000 order items

---

## 🧠 Notes

- Sensitive customer data is intentionally masked to preserve privacy and demonstrate realistic but non-production data.
- Azure credentials should never be hardcoded into source control.
- The setup and screenshots for the Azure server and database validation are expected to be captured during the live deployment stage.

---

## 🏁 Deliverables Summary

This repository includes the essential project artifacts:
- ERD diagram
- PostgreSQL schema
- population script
- validation SQL
- Azure configuration guidance
- project documentation

<p align="center">
  <span style="color:#FF7A18;">⭐</span>
  <span style="color:#2F80ED;">Built for cloud migration and database design learning</span>
  <span style="color:#00B894;">⭐</span>
</p>
