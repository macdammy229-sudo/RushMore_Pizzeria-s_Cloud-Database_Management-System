#!/usr/bin/env bash
set -euo pipefail

# Run from any directory; all repository paths are resolved relative to this file.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}. Copy .env.example to .env and configure a dedicated empty test database." >&2
  exit 1
fi

# .env is a trusted shell-style file with KEY=value entries, as in .env.example.
set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${AZURE_DB_HOST:?Set AZURE_DB_HOST in .env}"
: "${AZURE_DB_NAME:?Set AZURE_DB_NAME in .env}"
: "${AZURE_DB_USER:?Set AZURE_DB_USER in .env}"
: "${AZURE_DB_PASSWORD:?Set AZURE_DB_PASSWORD in .env}"
export PGHOST="${AZURE_DB_HOST}"
export PGPORT="${AZURE_DB_PORT:-5432}"
export PGDATABASE="${AZURE_DB_NAME}"
export PGUSER="${AZURE_DB_USER}"
export PGPASSWORD="${AZURE_DB_PASSWORD}"
export PGSSLMODE=require

if ! command -v psql >/dev/null 2>&1; then
  echo "psql is required; install the PostgreSQL client tools first." >&2
  exit 1
fi
if ! command -v python >/dev/null 2>&1; then
  echo "python is required; activate the project virtual environment first." >&2
  exit 1
fi

cd "${ROOT_DIR}"

# This workflow is deliberately first-run-only: never drop or overwrite user data.
relation_count="$(psql -X -qAt -v ON_ERROR_STOP=1 -c \
  "SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relkind IN ('r','p','v','m','S','f');")"
if [[ "${relation_count}" != "0" ]]; then
  echo "Refusing to seed: public schema contains ${relation_count} existing relation(s). Use a new, empty database." >&2
  exit 1
fi

printf '%s\n' "Creating schema..."
psql -X -v ON_ERROR_STOP=1 -f database/rushmore_schema.sql

printf '%s\n' "Loading deterministic demo data..."
python scripts/populate.py

printf '%s\n' "Running validation checks..."
psql -X -v ON_ERROR_STOP=1 -f database/quality_checks.sql
printf '%s\n' "Seed and validation workflow completed successfully."
