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
create or replace function gold.total_price (unit_quantity bigint, unit_price bigint)
    returns bigint 
    language plpgsql
as $body$

begin

  if unit_quantity is null then
    raise exception 'unit_quantity is NULL';
  end if;

  if unit_price is null then
    raise exception 'unit_price is NULL';
  end if;

  if unit_price < 0 then
    raise exception 'unit_price is negative';
  end if;

  return unit_quantity * unit_price;

end;

$body$;