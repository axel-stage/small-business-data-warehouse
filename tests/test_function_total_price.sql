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

-- function definition test
------------------------------
select has_function('gold', 'total_price', ARRAY ['int8', 'int8']);
select function_lang_is('gold', 'total_price', ARRAY ['int8', 'int8'], 'plpgsql');
select function_returns('gold', 'total_price', ARRAY ['int8', 'int8'], 'bigint');

select results_eq(
  'select gold.total_price(5::int, 5::int);',
  ARRAY[25::bigint],
  'function result test 1'
);

select results_eq(
  'select gold.total_price(2147483647, 20);',
  ARRAY[42949672940::bigint],
  'function result test 2'
);

select results_eq(
  'select gold.total_price(0, 20);',
  ARRAY[0::bigint],
  'function result test 3'
);

select throws_ok(
  'select gold.total_price(null, 5);',
  'unit_quantity is NULL'
);

select throws_ok(
  'select gold.total_price(5, null);',
  'unit_price is NULL'
);

select throws_ok(
  'select gold.total_price(5, -5);',
  'unit_price is negative'
);

-- finish tests
select * from finish();

-- clean up
rollback;