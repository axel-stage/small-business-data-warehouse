#!/bin/bash

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