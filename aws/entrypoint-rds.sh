#!/bin/bash
set -e

source .env.prod

# connect to postgres db with postgres role
export PGPASSWORD=${POSTGRES_PASSWORD}
psql -v ON_ERROR_STOP=1 \
    --host ${DW_HOST} \
    --port ${DW_PORT} \
    --dbname ${POSTGRES_DB} \
    --username ${POSTGRES_USER} <<EOF
\timing
\conninfo

-- role
CREATE ROLE ${DWADMIN}
WITH LOGIN
PASSWORD '${DWADMIN_SECRET}'
CONNECTION LIMIT 5
VALID UNTIL 'infinity'
NOCREATEDB
NOSUPERUSER
NOCREATEROLE
NOINHERIT
NOBYPASSRLS
NOREPLICATION;

-- database
CREATE DATABASE ${DW_NAME}
WITH OWNER ${DWADMIN}
TEMPLATE template1
ENCODING='UTF8';

\q
EOF

# connect to created db with dwadmin role
export PGPASSWORD=${DWADMIN_SECRET}
psql -v ON_ERROR_STOP=1 \
    --host ${DW_HOST} \
    --port ${DW_PORT} \
    --dbname ${DW_NAME} \
    --username ${DWADMIN} <<EOF
\timing
\conninfo
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;
CREATE SCHEMA IF NOT EXISTS pgtap;
SET search_path TO bronze;
\q
EOF

# connect to created db with postgres role
export PGPASSWORD=${POSTGRES_PASSWORD}
psql -v ON_ERROR_STOP=1 \
    --host ${DW_HOST} \
    --port ${DW_PORT} \
    --dbname ${DW_NAME} \
    --username ${POSTGRES_USER} <<EOF
\timing
\conninfo
CREATE EXTENSION IF NOT EXISTS aws_s3 WITH SCHEMA bronze cascade;
CREATE EXTENSION IF NOT EXISTS aws_commons WITH SCHEMA bronze cascade;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA pgtap;
\q
EOF