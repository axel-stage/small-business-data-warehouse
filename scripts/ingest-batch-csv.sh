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
    export PGPASSWORD=${POSTGRES_PASSWORD}
    psql -v ON_ERROR_STOP=1 \
        --host ${DW_HOST} \
        --port ${DW_PORT} \
        --dbname ${DW_NAME} \
        --username ${POSTGRES_USER} <<EOF
\timing
\conninfo
-- crm data
truncate table bronze.crm_cust_info;
select aws_s3.table_import_from_s3(
    'bronze.crm_cust_info',
    '',
    '(FORMAT CSV, DELIMITER '','', HEADER true)',
    aws_commons.create_s3_uri('datatestbed', '/source_crm/cust_info.csv', '${REGION}')
);
truncate table bronze.crm_prd_info;
select aws_s3.table_import_from_s3(
    'bronze.crm_prd_info',
    '',
    '(FORMAT CSV, DELIMITER '','', HEADER true)',
    aws_commons.create_s3_uri('datatestbed', '/source_crm/prd_info.csv', '${REGION}')
);
truncate table bronze.crm_sales_details;
select aws_s3.table_import_from_s3(
    'bronze.crm_sales_details',
    '',
    '(FORMAT CSV, DELIMITER '','', HEADER true)',
    aws_commons.create_s3_uri('datatestbed', '/source_crm/sales_details.csv', '${REGION}')
);
-- erp data
truncate table bronze.erp_cust_az12;
select aws_s3.table_import_from_s3(
    'bronze.erp_cust_az12',
    '',
    '(FORMAT CSV, DELIMITER '','', HEADER true)',
    aws_commons.create_s3_uri('datatestbed', '/source_erp/CUST_AZ12.csv', '${REGION}')
);
truncate table bronze.erp_loc_a101;
select aws_s3.table_import_from_s3(
    'bronze.erp_loc_a101',
    '',
    '(FORMAT CSV, DELIMITER '','', HEADER true)',
    aws_commons.create_s3_uri('datatestbed', '/source_erp/LOC_A101.csv', '${REGION}')
);
truncate table bronze.erp_px_cat_g1v2;
select aws_s3.table_import_from_s3(
    'bronze.erp_px_cat_g1v2',
    '',
    '(FORMAT CSV, DELIMITER '','', HEADER true)',
    aws_commons.create_s3_uri('datatestbed', '/source_erp/PX_CAT_G1V2.csv', '${REGION}')
);
\q
EOF

elif [[ ${ENVIRONMENT} == "dev" ]]
then
    source .env.dev
    export PGPASSWORD=$(cat docker/secret/postgres)
    psql -v ON_ERROR_STOP=1 \
        --host ${DW_HOST} \
        --port ${DW_PORT} \
        --username ${POSTGRES_USER} \
        --dbname ${DW_NAME} <<EOF
\conninfo
\timing
-- crm data
call bronze.load_csv('bronze.crm_cust_info', '/datasets/source_crm/cust_info.csv');
call bronze.load_csv('bronze.crm_prd_info', '/datasets/source_crm/prd_info.csv');
call bronze.load_csv('bronze.crm_sales_details', '/datasets/source_crm/sales_details.csv');
-- erp data
call bronze.load_csv('bronze.erp_loc_a101', '/datasets/source_erp/LOC_A101.csv');
call bronze.load_csv('bronze.erp_cust_az12', '/datasets/source_erp/CUST_AZ12.csv');
call bronze.load_csv('bronze.erp_px_cat_g1v2', '/datasets/source_erp/PX_CAT_G1V2.csv');
\q
EOF

else
    echo "ENVIRONMENT not set to dev or prod"
    exit 1
fi
