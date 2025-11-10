#!/bin/bash
set -e

ENVIRONMENT=$1

if [ -z ${ENVIRONMENT} ]; then
    echo "Please specify a ENVIRONMENT dev | prod"
    exit 1
fi

if [[ ${ENVIRONMENT} == "prod" ]]
then
    source .env.prod
    export PGPASSWORD=${DWADMIN_SECRET}
elif [[ ${ENVIRONMENT} == "dev" ]]
then
    source .env.dev
    export PGPASSWORD=$(cat docker/secret/dwadmin)
else
    echo "ENVIRONMENT not set to dev or prod"
    exit 1
fi

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