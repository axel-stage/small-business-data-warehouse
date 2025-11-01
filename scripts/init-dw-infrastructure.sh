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
\i ${PWD}/data_warehouse/bronze/ddl_crm.sql
\i ${PWD}/data_warehouse/bronze/ddl_erp.sql
\i ${PWD}/data_warehouse/bronze/proc_load_csv.sql
\q
EOF
