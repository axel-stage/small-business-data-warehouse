/*
===============================================================================
ddl: build views in gold layer
===============================================================================
purpose:
    - build views from silver layer tables
    - dimension and fact views
usage:
    - query views for downstream analytic workloads
===============================================================================
*/

drop view if exists gold.fact_sales;
drop view if exists gold.dim_customer;
drop view if exists gold.dim_product;

create view gold.dim_customer as
select
    cc.cst_id               as customer_id,
    cc.cst_key              as customer_key,
    -- ec.cid,
    cc.cst_firstname        as first_name,
    cc.cst_lastname         as last_name,
    cc.cst_martial_status   as martial_status,
    case
        when cst_gender like 'n/a' then gender -- edge case if main source is undefined
        else cst_gender -- crm system is the main source for gender
    end as gender,
    el.country,
    ec.birthdate,
    cc.cst_create_date as joined
from silver.crm_customer_info as cc
left join silver.erp_customer_az12 as ec on cc.cst_key = ec.cid
left join silver.erp_location_a101 as el on cc.cst_key = el.cid;

create view gold.dim_product as 
select
cp.prd_id           as  product_id,
cp.prd_key          as  product_key,
cp.prd_name         as  product_name,
cp.prd_line         as  product_line,
--cp.prd_category_id as  product_category_id,
ec.category         as  product_category,
ec.subcategory      as  product_subcategory,
ec.maintenance      as  product_maintenance,
cp.prd_price        as  product_price,
cp.prd_price_start  as  product_price_start
from silver.crm_product_info as cp
left join silver.erp_category_g1v2 as ec on cp.prd_category_id = ec.id
where cp.prd_price_end is null;

create view gold.fact_sales as
select
sls_ord_num             as sales_key,
dp.product_key,
dc.customer_key,
-- sls_prd_key,
-- sls_cst_id,
sls_order_date          as order_date,
sls_ship_date           as ship_date,
sls_due_date            as due_date,
sls_sales               as sales_amount,
sls_quantity            as quantity,
sls_price               as price
from silver.crm_sales_details as cs
left join gold.dim_product as dp on cs.sls_prd_key = dp.product_key
left join gold.dim_customer as dc on cs.sls_cst_id = dc.customer_id;