/*
===============================================================================
stored procedure: extract transform and load erp bronze data into silver
===============================================================================
purpose:
    - truncates tables before loading data
    - ingest bronze erp data into silver tables
parameters:
	  - none
output:
	  - void
usage:
    - call silver.etl_erp();
===============================================================================
*/

create or replace procedure silver.etl_erp()
language plpgsql
as $body$

declare
    starttime   timestamp;
    endtime     timestamp;
    rowCounter  bigint;

begin
    raise notice '--------------------------------------------------------------';
    raise notice 'ETL process to ingest bronze data into erp silver tables';
    raise notice '--------------------------------------------------------------';

    starttime := clock_timestamp();
    truncate table silver.erp_customer_az12;
    raise notice '>> Truncate table: silver.erp_customer_az12';
    insert into silver.erp_customer_az12(
        cid,
        birthdate,
        gender
    )
    select
        case
            when cid like 'NAS%' then substring(cid, 4, length(cid))
            else cid
        end as cid, -- clean 'NAS' prefix if present
        case
            when bdate > current_date then null
            else bdate
        end as birthdate, -- clean future birthdates
        case
            when trim(upper(gen)) in ('F', 'FEMALE') then 'Female'
            when trim(upper(gen)) in ('M', 'MALE') then 'Male'
            else 'n/a'
        end as gender -- standardize gender
    from bronze.erp_cust_az12;
    endtime := clock_timestamp();
    rowCounter := (select count(*) from silver.erp_customer_az12);
    raise notice '>> Insert data into: silver.erp_customer_az12';
    raise notice '>> Load duration: % [s]', EXTRACT(EPOCH FROM (endtime)) - EXTRACT(EPOCH FROM (starttime));
    raise notice '>> Total rows after insert: % [#]', rowCounter;
    raise notice '------------------------------------------------';

    starttime := clock_timestamp();
    truncate table silver.erp_location_a101;
    raise notice '>> Truncate table: silver.erp_location_a101';
    insert into silver.erp_location_a101(
        cid,
        country
    )
    select
        replace(cid, '-', '') as cid, -- clean hypens
        case
            when trim(upper(cntry)) in ('DE') then 'Germany'
            when trim(upper(cntry)) in ('US', 'USA') then 'United States'
            when cntry is null or
                trim(cntry) like '' or
                length(trim(cntry)) = 1 then 'United States'
            else trim(cntry)
        end as country -- standardize country, handle missing or blank country codes
    from bronze.erp_loc_a101;
    endtime := clock_timestamp();
    rowCounter := (select count(*) from silver.erp_location_a101);
    raise notice '>> Insert data into: silver.erp_location_a101';
    raise notice '>> Load duration: % [s]', EXTRACT(EPOCH FROM (endtime)) - EXTRACT(EPOCH FROM (starttime));
    raise notice '>> Total rows after insert: % [#]', rowCounter;
    raise notice '------------------------------------------------';

    starttime := clock_timestamp();
    truncate table silver.erp_category_g1v2;
    raise notice '>> Truncate table: silver.erp_category_g1v2';
    insert into silver.erp_category_g1v2(
        id,
        category,
        subcategory,
        maintenance
    )
    select
        id,
			  cat         as category, -- rename attribute
			  subcat      as subcategory, --rename attribute
			  maintenance
    from bronze.erp_px_cat_g1v2;
    endtime := clock_timestamp();
    rowCounter := (select count(*) from silver.erp_category_g1v2);
    raise notice '>> Insert data into: silver.erp_category_g1v2';
    raise notice '>> Load duration: % [s]', EXTRACT(EPOCH FROM (endtime)) - EXTRACT(EPOCH FROM (starttime));
    raise notice '>> Total rows after insert: % [#]', rowCounter;
    raise notice '------------------------------------------------';

end;

$body$;