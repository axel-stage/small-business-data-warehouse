/*
===============================================================================
function: total price
===============================================================================
purpose:
    - calcultes the total price from the quantity of a product and its unit price
parameters:
    - unit_quantity (int)
    - unit_price (int)
output:
    - total price (bigint)
usage:
    - select *, gold.total_price(quantity, price) from gold.fact_sales;
===============================================================================
*/
create or replace function gold.total_price (unit_quantity int, unit_price int)
returns bigint as $body$

begin
  return quantity * unit_price;
end;

$body$ language plpgsql;