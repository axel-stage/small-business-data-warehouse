#!/bin/bash
set -e

source .env.dev
export PGPASSWORD=$(cat data_warehouse/secret/postgres)
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
