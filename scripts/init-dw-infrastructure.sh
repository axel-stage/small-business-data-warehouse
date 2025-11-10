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
\i ${PWD}/data_warehouse/bronze/ddl_crm.sql
\i ${PWD}/data_warehouse/bronze/ddl_erp.sql
\i ${PWD}/data_warehouse/bronze/proc_load_csv.sql
\i ${PWD}/data_warehouse/silver/ddl_crm.sql
\i ${PWD}/data_warehouse/silver/ddl_erp.sql
\i ${PWD}/data_warehouse/silver/proc_etl_crm.sql
\i ${PWD}/data_warehouse/silver/proc_etl_erp.sql
\i ${PWD}/data_warehouse/gold/ddl_gold.sql
\i ${PWD}/data_warehouse/gold/func_gold.sql
\q
EOF
