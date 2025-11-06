-- config
---------
-- Turn off echo and keep things quiet.
\unset ECHO
\set QUIET 1
-- Format the output for nice TAP.
\pset format unaligned
\pset tuples_only true
\pset pager off
-- Revert all changes on failure.
\set ON_ERROR_ROLLBACK 1
\set ON_ERROR_STOP true

begin;

set search_path to pgtap;

-- plan tests
select plan(25);

-- run the tests.
select has_schema('bronze'::name);
select has_schema('silver'::name);
select has_schema('gold'::name);
select has_schema('pgtap'::name);

select has_extension('pgtap'::name);
select has_extension('pgtap'::name);

select has_table('bronze'::name,'crm_cust_info'::name);
select has_table('bronze'::name,'crm_prd_info'::name);
select has_table('bronze'::name,'crm_sales_details'::name);
select has_table('bronze'::name,'erp_loc_a101'::name);
select has_table('bronze'::name,'erp_cust_az12'::name);
select has_table('bronze'::name,'erp_px_cat_g1v2'::name);
select has_function('bronze'::name,'load_csv'::name);

select has_table('silver'::name,'crm_customer_info'::name);
select has_table('silver'::name,'crm_product_info'::name);
select has_table('silver'::name,'crm_sales_details'::name);
select has_table('silver'::name,'erp_customer_az12'::name);
select has_table('silver'::name,'erp_location_a101'::name);
select has_table('silver'::name,'erp_category_g1v2'::name);
select has_function('silver'::name,'etl_crm'::name);
select has_function('silver'::name,'etl_erp'::name);

select has_view('gold'::name,'dim_customer'::name);
select has_view('gold'::name,'dim_product'::name);
select has_view('gold'::name,'fact_sales'::name);
select has_function('gold'::name,'total_price'::name);

-- finish tests
select * from finish();

-- clean up
rollback;