#!/bin/bash
set -e

source .env.prod

export PGPASSWORD=${POSTGRES_PASSWORD}
psql -v ON_ERROR_STOP=1 \
    --host ${DW_HOST} \
    --port ${DW_PORT} \
    --dbname ${DW_NAME} \
    --username ${POSTGRES_USER} <<EOF
\timing
\conninfo

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
\q
EOF
