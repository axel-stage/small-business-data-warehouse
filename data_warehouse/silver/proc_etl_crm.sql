/*
===============================================================================
stored procedure: extract transform and load crm bronze data into silver
===============================================================================
purpose:
    - truncates the silver tables before loading data
    - ingest bronze into silver crm tables
parameters:
	- none
output:
	- void
usage:
    - call silver.etl_crm();
===============================================================================
*/

create or replace procedure silver.etl_crm()
language plpgsql
as $body$

declare
    starttime   timestamp;
    endtime     timestamp;
    rowCounter  bigint;
begin
    raise notice '--------------------------------------------------------------';
    raise notice 'ETL process to ingest crm bronze into crm silver tables';
    raise notice '--------------------------------------------------------------';

    starttime := clock_timestamp();
    truncate table silver.crm_customer_info;
    raise notice '>> Truncate table: silver.crm_customer_info';
    insert into silver.crm_customer_info(
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_martial_status,
        cst_gender,
        cst_create_date
    )
    select
        cst_id,
        cst_key,
        trim(cst_firstname) as cst_firstname,
        trim(cst_lastname) as cst_lastname,
        case
            when upper(trim(cst_marital_status)) like 'S' then 'Single'
            when upper(trim(cst_marital_status)) like 'M' then 'Married'
            else 'n/a'
        end as cst_marital_status, -- standardize marital status
        case
            when upper(trim(cst_gndr)) like 'F' then 'Female'
            when upper(trim(cst_gndr)) like 'M' then 'Male'
            else 'n/a'
        end as cst_gender, -- standardize gender status
        cst_create_date
    from (
        select
        *,
        row_number() over (partition by cst_id order by cst_create_date desc) as flag_last
        from bronze.crm_cust_info
        where cst_id is not null
    )
    where flag_last = 1; -- select latest customer record
    endtime := clock_timestamp();
    rowCounter := (select count(*) from silver.crm_customer_info);
    raise notice '>> Insert data into: silver.crm_customer_info';
    raise notice '>> Load duration: % [s]', EXTRACT(EPOCH FROM (endtime)) - EXTRACT(EPOCH FROM (starttime));
    raise notice '>> Total rows after insert: % [#]', rowCounter;
    raise notice '------------------------------------------------';

    starttime := clock_timestamp();
    truncate table silver.crm_product_info;
    raise notice '>> Truncate table: silver.crm_product_info';
    insert into silver.crm_product_info(
        prd_id,
        prd_key,
        prd_category_id,
        prd_name,
        prd_line,
        prd_price,
        prd_price_start,
        prd_price_end
    )
    select
        prd_id,
        substring(prd_key, 7, length(prd_key)) as prd_key,
        replace(substring(prd_key, 1, 5), '-', '_') as prd_category_id,
        prd_nm as prd_name,
        case
            when upper(trim(prd_line)) like 'M' then 'Mountain'
            when upper(trim(prd_line)) like 'R' then 'Road'
            when upper(trim(prd_line)) like 'S' then 'Other Sales'
            when upper(trim(prd_line)) like 'T' then 'Touring'
            else 'n/a'
        end as prd_line, -- standardize product line codes to descriptive name
        coalesce(prd_cost, 0) as prd_price,
        prd_start_dt::date as prd_price_start,
        -- Calculate end date as one day before the next start date
        (lead(prd_start_dt) over (partition by prd_key order by prd_start_dt) - 1)::timestamp as prd_price_end
    from bronze.crm_prd_info;
    endtime := clock_timestamp();
    rowCounter := (select count(*) from silver.crm_product_info);
    raise notice '>> Insert data into: silver.crm_product_info';
    raise notice '>> Load duration: % [s]', EXTRACT(EPOCH FROM (endtime)) - EXTRACT(EPOCH FROM (starttime));
    raise notice '>> Total rows after insert: % [#]', rowCounter;
    raise notice '------------------------------------------------';

    starttime := clock_timestamp();
    truncate table silver.crm_sales_details;
    raise notice '>> Truncate table: silver.crm_sales_details';
    insert into silver.crm_sales_details(
        sls_ord_num,
        sls_prd_key,
        sls_cst_id,
        sls_order_date,
        sls_ship_date,
        sls_due_date,
        sls_sales,
        sls_quantity,
        sls_price
    )
    select
        sls_ord_num,
        sls_prd_key,
        sls_cust_id as sls_cst_id,
        case
            when sls_order_dt = 0 or length(sls_order_dt::varchar) != 8 then null
            else sls_order_dt::varchar::date
        end as sls_order_date,
        case
            when sls_ship_dt = 0 or length(sls_ship_dt::varchar) != 8 then null
            else sls_ship_dt::varchar::date
        end as sls_ship_date,
        case
            when sls_due_dt = 0 or length(sls_due_dt::varchar) != 8 then null
            else sls_due_dt::varchar::date
        end as sls_due_date,
        case
            when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * abs(sls_price) then sls_quantity * abs(sls_price)
            else sls_sales
        end as sls_sales, -- derive sales if value is missing or invalid
        sls_quantity,
        case
            when sls_price is null or sls_price <= 0 then sls_sales / coalesce(sls_quantity, 0)
            else sls_price -- derive price if value is missing or invalid
        end as sls_price
    from bronze.crm_sales_details;
    endtime := clock_timestamp();
    rowCounter := (select count(*) from silver.crm_sales_details);
    raise notice '>> Insert data into: silver.crm_sales_details';
    raise notice '>> Load duration: % [s]', EXTRACT(EPOCH FROM (endtime)) - EXTRACT(EPOCH FROM (starttime));
    raise notice '>> Total rows after insert: % [#]', rowCounter;
    raise notice '------------------------------------------------';

end;

$body$;
