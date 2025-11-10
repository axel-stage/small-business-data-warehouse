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
