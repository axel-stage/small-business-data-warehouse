#!/bin/bash
set -e

source .env.dev
export PGPASSWORD=$(cat data_warehouse/secret/dwadmin)
psql -v ON_ERROR_STOP=1 \
    --host ${DW_HOST} \
    --port ${DW_PORT} \
    --username ${DWADMIN} \
    --dbname ${DW_NAME} <<EOF
\conninfo
\timing
-- crm data
call silver.etl_crm();
-- erp data
call silver.etl_erp();
\q
EOF