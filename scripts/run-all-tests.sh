#!/bin/bash

source .env.dev
export PGPASSWORD=$(cat docker/secret/dwadmin)
psql \
    --host ${DW_HOST} \
    --port ${DW_PORT} \
    --username ${DWADMIN} \
    --dbname ${DW_NAME} <<EOF
\i ${PWD}/tests/infrastructure_test.sql
\i ${PWD}/tests/quality_test_silver.sql
\q
EOF