#!/bin/bash

source .env.dev
export PGPASSWORD=$(cat docker/secret/dwadmin)
psql \
    --host ${DW_HOST} \
    --port ${DW_PORT} \
    --username ${DWADMIN} \
    --dbname ${DW_NAME} <<EOF
\i ${PWD}/tests/test_structure_db.sql
\i ${PWD}/tests/test_quality_silver_layer.sql
\i ${PWD}/tests/test_function_total_price.sql
\q
EOF