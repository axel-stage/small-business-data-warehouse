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
select plan(9);

-- run the tests.

----------------------
-- crm_customer_info -
----------------------
select is_empty(
  'select cst_id from silver.crm_customer_info group by cst_id having count(*) > 1;',
  'no dublicates in cst_id'
);

select results_eq(
  'select count(*)::int from (select cst_id from silver.crm_customer_info group by cst_id having count(*) > 1)',
  ARRAY[0],
  'no dublicates in cst_id'
);

select results_eq(
  'select count(*)::int from (select cst_id from silver.crm_customer_info where cst_id is null);',
  ARRAY[0],
  'no NULLs in cst_id'
);

select results_eq(
  'select count(*)::int from (select cst_key from silver.crm_customer_info where cst_key != trim(cst_key));',
  ARRAY[0],
  'no spaces in cst_key'
);

select results_eq(
  'select distinct cst_martial_status from silver.crm_customer_info;',
  ARRAY['Married'::varchar, 'Single'::varchar],
  'valid martial_status standardization'
);

---------------------
-- crm_product_info -
---------------------
select results_eq(
  'select count(*)::int from (select prd_id from silver.crm_product_info where prd_id is null);',
  ARRAY[0],
  'no NULLs in prd_id'
);

select results_eq(
  'select count(*)::int from (select prd_id from silver.crm_product_info group by prd_id having count(*) > 1)',
  ARRAY[0],
  'no dublicates in prd_id'
);

select results_eq(
  'select count(*)::int from (select prd_name from silver.crm_product_info where prd_name != trim(prd_name));',
  ARRAY[0],
  'no spaces in prd_name'
);

select results_eq(
  'select distinct prd_line from silver.crm_product_info order by prd_line;',
  ARRAY['Mountain'::varchar, 'n/a'::varchar, 'Other Sales'::varchar, 'Road'::varchar, 'Touring'::varchar],
  'valid prd_line standardization'
);

-- finish tests
select * from finish();

-- clean up
rollback;